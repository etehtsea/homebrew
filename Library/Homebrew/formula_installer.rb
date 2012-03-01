require 'exceptions'
require 'formula'
require 'keg'
require 'set'
require 'tab'

class FormulaInstaller
  attr :f
  attr :show_summary_heading, true
  attr :ignore_deps, true
  attr :install_bottle, true
  attr :show_header, true

  def initialize ff
    @f = ff
    @show_header = true
    @ignore_deps = ARGV.include? '--ignore-dependencies' || ARGV.interactive?
    @install_bottle = !ARGV.build_from_source? && ff.bottle_up_to_date?
  end

  def install
    raise FormulaAlreadyInstalledError, f if f.installed? and not ARGV.force?

    unless ignore_deps
      f.check_external_deps

      needed_deps = f.recursive_deps.reject{ |d| d.installed? }
      unless needed_deps.empty?
        needed_deps.each do |dep|
          if dep.explicitly_requested?
            install_dependency dep
          else
            ARGV.filter_for_dependencies do
              # Re-create the formula object so that args like `--HEAD` won't
              # affect properties like the installation prefix. Also need to
              # re-check installed status as the Formula may have changed.
              dep = Formula.factory dep.path
              install_dependency dep unless dep.installed?
            end
          end
        end
        # now show header as all the deps stuff has clouded the original issue
        show_header = true
      end
    end

    oh1 "Installing #{f}" if show_header

    @@attempted ||= Set.new
    raise FormulaInstallationAlreadyAttemptedError, f if @@attempted.include? f
    @@attempted << f

    if install_bottle
      pour
    else
      build
      clean
    end

    raise "Nothing was installed to #{f.prefix}" unless f.installed?
  end

  def install_dependency dep
    fi = FormulaInstaller.new dep
    fi.ignore_deps = true
    fi.show_header = false
    oh1 "Installing #{f} dependency: #{dep}"
    fi.install
    Keg.new(dep.linked_keg.realpath).unlink if dep.linked_keg.directory?
    fi.caveats
    fi.finish
  end

  def caveats
    the_caveats = (f.caveats || "").strip
    unless the_caveats.empty?
      ohai "Caveats", f.caveats
      @show_summary_heading = true
    end

    if f.keg_only?
      ohai 'Caveats', f.keg_only_text
      @show_summary_heading = true
    else
      audit_bin
      audit_sbin
      audit_lib
      check_manpages
      check_infopages
      check_m4
    end
  end

  def finish
    ohai 'Finishing up' if ARGV.verbose?

    unless f.keg_only?
      link
      check_PATH
    end
    fix_install_names

    ohai "Summary" if ARGV.verbose? or show_summary_heading
    print "#{f.prefix}: #{f.prefix.abv}"
    print ", built in #{pretty_duration build_time}" if build_time
    puts
  end

  def build_time
    @build_time ||= Time.now - @start_time unless install_bottle or ARGV.interactive? or @start_time.nil?
  end

  def build
    @start_time = Time.now

    # 1. formulae can modify ENV, so we must ensure that each
    #    installation has a pristine ENV when it starts, forking now is
    #    the easiest way to do this
    # 2. formulae have access to __END__ the only way to allow this is
    #    to make the formula script the executed script
    read, write = IO.pipe
    # I'm guessing this is not a good way to do this, but I'm no UNIX guru
    ENV['HOMEBREW_ERROR_PIPE'] = write.to_i.to_s

    args = ARGV.clone
    unless args.include? '--fresh'
      previous_install = Tab.for_formula f
      args.concat previous_install.used_options
      args.uniq! # Just in case some dupes were added
    end

    fork do
      begin
        read.close
        exec '/usr/bin/nice',
             '/usr/bin/ruby',
             '-I', Pathname.new(__FILE__).dirname,
             '-rbuild',
             '--',
             f.path,
             *args.options_only
      rescue Exception => e
        Marshal.dump(e, write)
        write.close
        exit! 1
      end
    end

    ignore_interrupts do # the fork will receive the interrupt and marshall it back
      write.close
      Process.wait
      data = read.read
      raise Marshal.load(data) unless data.nil? or data.empty?
      raise "Suspicious installation failure" unless $?.success?

      # Write an installation receipt (a Tab) to the prefix
      Tab.for_install(f, args).write if f.installed?
    end
  end

  def link
    if f.linked_keg.directory? and f.linked_keg.realpath == f.prefix
      opoo "This keg was marked linked already, continuing anyway"
      # otherwise Keg.link will bail
      f.linked_keg.unlink
    end

    Keg.new(f.prefix).link
  rescue Exception => e
    onoe "The linking step did not complete successfully"
    puts "The formula built, but is not symlinked into #{Homebrew.prefix}"
    puts "You can try again using `brew link #{f.name}'"
    ohai e, e.backtrace if ARGV.debug?
    @show_summary_heading = true
  end

  def fix_install_names
    Keg.new(f.prefix).fix_install_names
  rescue Exception => e
    onoe "Failed to fix install names"
    puts "The formula built, but you may encounter issues using it or linking other"
    puts "formula against it."
    ohai e, e.backtrace if ARGV.debug?
    @show_summary_heading = true
  end

  def clean
    require 'cleaner'
    Cleaner.new f
  rescue Exception => e
    opoo "The cleaning step did not complete successfully"
    puts "Still, the installation was successful, so we will link it into your prefix"
    ohai e, e.backtrace if ARGV.debug?
    @show_summary_heading = true
  end

  def pour
    Homebrew.cache.mkpath
    downloader = DownloadStrategy::CurlBottle.new f.bottle_url, f.name, f.version, nil
    downloader.fetch
    f.verify_download_integrity downloader.tarball_path, f.bottle_sha1, "SHA1"
    Homebrew.cellar.cd do
      downloader.stage
    end
  end

  ## checks

  def paths
    @paths ||= ENV['PATH'].split(':').map{ |p| File.expand_path p }
  end

  def in_aclocal_dirlist?
    File.open("/usr/share/aclocal/dirlist") do |dirlist|
      dirlist.grep(%r{^#{Homebrew.prefix}/share/aclocal$}).length > 0
    end rescue false
  end

  def check_PATH
    # warn the user if stuff was installed outside of their PATH
    [f.bin, f.sbin].each do |bin|
      if bin.directory? and bin.children.length > 0
        bin = (Homebrew.prefix/bin.basename).realpath.to_s
        unless paths.include? bin
          opoo "#{bin} is not in your PATH"
          puts "You can amend this by altering your ~/.bashrc file"
          @show_summary_heading = true
        end
      end
    end
  end

  def check_manpages
    # Check for man pages that aren't in share/man
    if (f.prefix+'man').exist?
      opoo 'A top-level "man" directory was found.'
      puts "Homebrew requires that man pages live under share."
      puts 'This can often be fixed by passing "--mandir=#{man}" to configure.'
      @show_summary_heading = true
    end
  end

  def check_infopages
    # Check for info pages that aren't in share/info
    if (f.prefix+'info').exist?
      opoo 'A top-level "info" directory was found.'
      puts "Homebrew suggests that info pages live under share."
      puts 'This can often be fixed by passing "--infodir=#{info}" to configure.'
      @show_summary_heading = true
    end
  end

  def check_jars
    return unless File.exist? f.lib

    jars = f.lib.children.select{|g| g.to_s =~ /\.jar$/}
    unless jars.empty?
      opoo 'JARs were installed to "lib".'
      puts "Installing JARs to \"lib\" can cause conflicts between packages."
      puts "For Java software, it is typically better for the formula to"
      puts "install to \"libexec\" and then symlink or wrap binaries into \"bin\"."
      puts "See \"activemq\", \"jruby\", etc. for examples."
      puts "The offending files are:"
      puts jars
      @show_summary_heading = true
    end
  end

  def check_non_libraries
    return unless File.exist? f.lib

    valid_libraries = %w(.a .dylib .framework .la .so)
    non_libraries = f.lib.children.select do |g|
      next if g.directory?
      extname = g.extname
      (extname != ".jar") and (not valid_libraries.include? extname)
    end

    unless non_libraries.empty?
      opoo 'Non-libraries were installed to "lib".'
      puts "Installing non-libraries to \"lib\" is bad practice."
      puts "The offending files are:"
      puts non_libraries
      @show_summary_heading = true
    end
  end

  def audit_bin
    return unless File.exist? f.bin

    non_exes = f.bin.children.select {|g| File.directory? g or not File.executable? g}

    unless non_exes.empty?
      opoo 'Non-executables were installed to "bin".'
      puts "Installing non-executables to \"bin\" is bad practice."
      puts "The offending files are:"
      puts non_exes
      @show_summary_heading = true
    end
  end

  def audit_sbin
    return unless File.exist? f.sbin

    non_exes = f.sbin.children.select {|g| File.directory? g or not File.executable? g}

    unless non_exes.empty?
      opoo 'Non-executables were installed to "sbin".'
      puts "Installing non-executables to \"sbin\" is bad practice."
      puts "The offending files are:"
      puts non_exes
      @show_summary_heading = true
    end
  end

  def audit_lib
    check_jars
    check_non_libraries
  end

  def check_m4
    return if MacOS.xcode_version.to_f >= 4.3

    # Check for m4 files
    if Dir[f.share+"aclocal/*.m4"].length > 0 and not in_aclocal_dirlist?
      opoo 'm4 macros were installed to "share/aclocal".'
      puts "Homebrew does not append \"#{Homebrew.prefix}/share/aclocal\""
      puts "to \"/usr/share/aclocal/dirlist\". If an autoconf script you use"
      puts "requires these m4 macros, you'll need to add this path manually."
      @show_summary_heading = true
    end
  end
end


def external_dep_check dep, type
  case type
    when :python then %W{/usr/bin/env python -c import\ #{dep}}
    when :jruby then %W{/usr/bin/env jruby -rubygems -e require\ '#{dep}'}
    when :ruby then %W{/usr/bin/env ruby -rubygems -e require\ '#{dep}'}
    when :rbx then %W{/usr/bin/env rbx -rubygems -e require\ '#{dep}'}
    when :perl then %W{/usr/bin/env perl -e use\ #{dep}}
    when :chicken then %W{/usr/bin/env csi -e (use #{dep})}
    when :node then %W{/usr/bin/env node -e require('#{dep}');}
    when :lua then %W{/usr/bin/env luarocks show #{dep}}
  end
end


class Formula
  def keg_only_text
    # Add indent into reason so undent won't truncate the beginnings of lines
    reason = self.keg_only?.to_s.gsub(/[\n]/, "\n    ")
    return <<-EOS.undent
    This formula is keg-only, so it was not symlinked into #{Homebrew.prefix}.

    #{reason}

    Generally there are no consequences of this for you.
    If you build your own software and it requires this formula, you'll need
    to add its lib & include paths to your build variables:

        LDFLAGS  -L#{lib}
        CPPFLAGS -I#{include}
    EOS
  end

  def check_external_deps
    [:ruby, :python, :perl, :jruby, :rbx, :chicken, :node, :lua].each do |type|
      self.external_deps[type].each do |dep|
        unless quiet_system(*external_dep_check(dep, type))
          raise UnsatisfiedExternalDependencyError.new(dep, type)
        end
      end if self.external_deps[type]
    end
  end
end
