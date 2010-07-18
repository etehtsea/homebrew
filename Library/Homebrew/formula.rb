require 'download_strategy'
require 'fileutils'

class FormulaUnavailableError <RuntimeError
  def initialize name
    @name = name
    super "No available formula for #{name}"
  end
  
  attr_reader :name
end


# Derive and define at least @url, see Library/Formula for examples
class Formula
  include FileUtils
  
  attr_reader :url, :version, :homepage, :name, :specs, :downloader

  # Homebrew determines the name
  def initialize name='__UNKNOWN__'
    set_instance_variable 'url'
    set_instance_variable 'head'
    set_instance_variable 'specs'

    if @head and (not @url or ARGV.build_head?)
      @url=@head
      @version='HEAD'
    end

    raise "No url provided for formula #{name}" if @url.nil?
    @name=name
    validate_variable :name

    set_instance_variable 'version'
    @version ||= Pathname.new(@url).version
    validate_variable :version if @version
    
    set_instance_variable 'homepage'

    CHECKSUM_TYPES.each do |type|
      set_instance_variable type
    end

    @downloader=download_strategy.new url, name, version, specs
  end

  # if the dir is there, but it's empty we consider it not installed
  def installed?
    return prefix.children.length > 0
  rescue
    return false
  end

  def prefix
    validate_variable :name
    validate_variable :version
    HOMEBREW_CELLAR+@name+@version
  end

  def path
    self.class.path name
  end

  def cached_download
    @downloader.cached_location
  end

  def bin; prefix+'bin' end
  def sbin; prefix+'sbin' end
  def doc; prefix+'share/doc'+name end
  def lib; prefix+'lib' end
  def libexec; prefix+'libexec' end
  def man; prefix+'share/man' end
  def man1; man+'man1' end
  def info; prefix+'share/info' end
  def include; prefix+'include' end
  def share; prefix+'share' end

  # generally we don't want var stuff inside the keg
  def var; HOMEBREW_PREFIX+'var' end
  # configuration needs to be preserved past upgrades
  def etc; HOMEBREW_PREFIX+'etc' end
  
  # reimplement if we don't autodetect the download strategy you require
  def download_strategy
    if @specs and @url == @head
      vcs = @specs.delete :using
      if vcs != nil
        # If a class is passed, assume it is a download strategy
        return vcs if vcs.kind_of? Class

        case vcs
        when :bzr then return BazaarDownloadStrategy
        when :curl then return CurlDownloadStrategy
        when :cvs then return CVSDownloadStrategy
        when :git then return GitDownloadStrategy
        when :hg then return MercurialDownloadStrategy
        when :svn then return SubversionDownloadStrategy
        end

        raise "Unknown strategy #{vcs} was requested."
      end
    end

    detect_download_strategy url
  end

  # tell the user about any caveats regarding this package, return a string
  def caveats; nil end

  # patches are automatically applied after extracting the tarball
  # return an array of strings, or if you need a patch level other than -p1
  # return a Hash eg.
  #   {
  #     :p0 => ['http://foo.com/patch1', 'http://foo.com/patch2'],
  #     :p1 =>  'http://bar.com/patch2',
  #     :p2 => ['http://moo.com/patch5', 'http://moo.com/patch6']
  #   }
  # The final option is to return DATA, then put a diff after __END__. You
  # can still return a Hash with DATA as the value for a patch level key.
  def patches; end

  # rarely, you don't want your library symlinked into the main prefix
  # see gettext.rb for an example
  def keg_only?; false end

  # sometimes the clean process breaks things
  # skip cleaning paths in a formula with a class method like this:
  #   skip_clean [bin+"foo", lib+"bar"]
  # redefining skip_clean? in formulas is now deprecated
  def skip_clean? path
    to_check = path.relative_path_from(prefix).to_s
    self.class.skip_clean_paths.include? to_check
  end

  # yields self with current working directory set to the uncompressed tarball
  def brew
    validate_variable :name
    validate_variable :version

    stage do
      begin
        patch
        # we allow formulas to do anything they want to the Ruby process
        # so load any deps before this point! And exit asap afterwards
        yield self
      rescue Interrupt, RuntimeError, SystemCallError => e
        raise unless ARGV.debug?
        onoe e.inspect
        puts e.backtrace
        ohai "Rescuing build..."
        if (e.was_running_configure? rescue false) and File.exist? 'config.log'
          puts "It looks like an autotools configure failed."
          puts "Gist 'config.log' and any error output when reporting an issue."
          puts
        end

        puts "When you exit this shell Homebrew will attempt to finalise the installation."
        puts "If nothing is installed or the shell exits with a non-zero error code,"
        puts "Homebrew will abort. The installation prefix is:"
        puts prefix
        ENV['HOMEBREW_DEBUG_INSTALL'] = name
        interactive_shell
      end
    end
  end

  # we don't have a std_autotools variant because autotools is a lot less
  # consistent and the standard parameters are more memorable
  # really Homebrew should determine what works inside brew() then
  # we could add --disable-dependency-tracking when it will work
  def std_cmake_parameters
    # The None part makes cmake use the environment's CFLAGS etc. settings
    "-DCMAKE_INSTALL_PREFIX='#{prefix}' -DCMAKE_BUILD_TYPE=None -Wno-dev"
  end

  def self.class_s name
    #remove invalid characters and then camelcase it
    name.capitalize.gsub(/[-_.\s]([a-zA-Z0-9])/) { $1.upcase } \
                   .gsub('+', 'x')
  end

  # an array of all Formula names
  def self.names
    Dir["#{HOMEBREW_REPOSITORY}/Library/Formula/*.rb"].map{ |f| File.basename f, '.rb' }.sort
  end

  # an array of all Formula, instantiated
  def self.all
    all = []
    names.each do |n|
      begin
        all << Formula.factory(n)
      rescue
        # Don't let one broken formula break commands.
      end
    end
    return all
  end

  def self.aliases
    Dir["#{HOMEBREW_REPOSITORY}/Library/Aliases/*"].map{ |f| File.basename f }.sort
  end

  def self.factory name
    return name if name.kind_of? Formula
    path = Pathname.new(name)
    if path.absolute?
      require name
      name = path.stem
    else
      require self.path(name)
    end
    begin
      klass_name =self.class_s(name)
      klass = eval(klass_name)
    rescue NameError
      # TODO really this text should be encoded into the exception
      # and only shown if the UI deems it correct to show it
      onoe "class \"#{klass_name}\" expected but not found in #{name}.rb"
      puts "Double-check the name of the class in that formula."
      raise LoadError
    end
    return klass.new(name)
  rescue LoadError
    raise FormulaUnavailableError.new(name)
  end

  def self.path name
    HOMEBREW_REPOSITORY+"Library/Formula/#{name.downcase}.rb"
  end

  def deps
    self.class.deps or []
  end

  def external_deps
    self.class.external_deps
  end

  def fails_with_llvm msg="", data=nil
    return unless (ENV['HOMEBREW_USE_LLVM'] or ARGV.include? '--use-llvm')

    build = data.delete :build rescue nil
    msg = "(No specific reason was given)" if msg.empty?

    opoo "LLVM was requested, but this formula is reported as not working with LLVM:"
    puts msg
    puts "Tested with LLVM build #{build}" unless build == nil
  end

protected
  # Pretty titles the command and buffers stdout/stderr
  # Throws if there's an error
  def system cmd, *args
    ohai "#{cmd} #{args*' '}".strip

    if ARGV.verbose?
      safe_system cmd, *args
    else
      rd, wr = IO.pipe
      pid = fork do
        rd.close
        $stdout.reopen wr
        $stderr.reopen wr
        exec(cmd, *args) rescue nil
        exit! 1 # never gets here unless exec threw or failed
      end
      wr.close
      out = ''
      out << rd.read until rd.eof?
      Process.wait
      unless $?.success?
        puts out
        raise
      end
    end
  rescue SystemCallError
    # usually because exec could not be find the command that was requested
    raise
  rescue 
    raise BuildError.new(cmd, args, $?)
  end

private
  # creates a temporary directory then yields, when the block returns it
  # recursively deletes the temporary directory
  def mktemp
    # I used /tmp rather than mktemp -td because that generates a directory
    # name with exotic characters like + in it, and these break badly written
    # scripts that don't escape strings before trying to regexp them :(

    # If the user has FileVault enabled, then we can't mv symlinks from the
    # /tmp volume to the other volume. So we let the user override the tmp
    # prefix if they need to.
    tmp_prefix = ENV['HOMEBREW_TEMP'] || '/tmp'
    tmp=Pathname.new `/usr/bin/mktemp -d #{tmp_prefix}/homebrew-#{name}-#{version}-XXXX`.strip
    raise "Couldn't create build sandbox" if not tmp.directory? or $? != 0
    begin
      wd=Dir.pwd
      Dir.chdir tmp
      yield
    ensure
      Dir.chdir wd
      tmp.rmtree
    end
  end

  CHECKSUM_TYPES=[:md5, :sha1, :sha256].freeze

  def verify_download_integrity fn
    require 'digest'
    type=CHECKSUM_TYPES.detect { |type| instance_variable_defined?("@#{type}") }
    type ||= :md5
    supplied=instance_variable_get("@#{type}")
    type=type.to_s.upcase
    hasher = Digest.const_get(type)
    hash = fn.incremental_hash(hasher)

    if supplied and not supplied.empty?
      message = <<-EOF
#{type} mismatch
Expected: #{supplied}
Got: #{hash}
Archive: #{fn}
(To retry an incomplete download, remove the file above.)
EOF
      raise message unless supplied.upcase == hash.upcase
    else
      opoo "Cannot verify package integrity"
      puts "The formula did not provide a download checksum"
      puts "For your reference the #{type} is: #{hash}"
    end
  end

  def stage
    HOMEBREW_CACHE.mkpath

    downloaded_tarball = @downloader.fetch
    if downloaded_tarball.kind_of? Pathname
      verify_download_integrity downloaded_tarball
    end
  
    mktemp do
      @downloader.stage
      yield
    end
  end
  
  def patch
    return if patches.nil?

    if not patches.kind_of? Hash
      # We assume -p1
      patch_defns = { :p1 => patches }
    else
      patch_defns = patches
    end

    patch_list=[]
    n=0
    patch_defns.each do |arg, urls|
      # DATA.each does each line, which doesn't work so great
      urls = [urls] unless urls.kind_of? Array

      urls.each do |url|
        p = {:filename => '%03d-homebrew.diff' % n+=1, :compression => false}

        if defined? DATA and url == DATA
          pn=Pathname.new p[:filename]
          pn.write DATA.read
        elsif url =~ %r[^\w+\://]
          out_fn = p[:filename]
          case url
          when /\.gz$/
            p[:compression] = :gzip
            out_fn += '.gz'
          when /\.bz2$/
            p[:compression] = :bzip2
            out_fn += '.bz2'
          end
          p[:curl_args] = [url, '-o', out_fn]
        else
          # it's a file on the local filesystem
          p[:filename] = url
        end

        p[:args] = ["-#{arg}", '-i', p[:filename]]

        patch_list << p
      end
    end
    
    return if patch_list.empty?

    ohai "Downloading patches"
    # downloading all at once is much more efficient, espeically for FTP
    curl *(patch_list.collect{|p| p[:curl_args]}.select{|p| p}.flatten)

    ohai "Patching"
    patch_list.each do |p|
      case p[:compression]
        when :gzip  then safe_system "/usr/bin/gunzip",  p[:filename]+'.gz'
        when :bzip2 then safe_system "/usr/bin/bunzip2", p[:filename]+'.bz2'
      end
      # -f means it doesn't prompt the user if there are errors, if just
      # exits with non-zero status
      safe_system '/usr/bin/patch', '-f', *(p[:args])
    end
  end

  def validate_variable name
    v = instance_variable_get("@#{name}")
    raise "Invalid @#{name}" if v.to_s.empty? or v =~ /\s/
  end

  def set_instance_variable(type)
    unless instance_variable_defined? "@#{type}"
      class_value = self.class.send(type)
      instance_variable_set("@#{type}", class_value) if class_value
    end
  end

  def method_added method
    raise 'You cannot override Formula.brew' if method == 'brew'
  end

  class << self

    def self.attr_rw(*attrs)
      attrs.each do |attr|
        class_eval %Q{
          def #{attr}(val=nil)
            val.nil? ? @#{attr} : @#{attr} = val
          end
        }
      end
    end

    attr_rw :url, :version, :homepage, :specs, :deps, :external_deps, *CHECKSUM_TYPES

    def head val=nil, specs=nil
      if specs
        @specs = specs
      end
      val.nil? ? @head : @head = val
    end

    def depends_on name
      @deps ||= []
      @external_deps ||= {:python => [], :perl => [], :ruby => [], :jruby => []}

      case name
      when String
        # noop
      when Hash
        key, value = name.shift
        case value
        when :python, :perl, :ruby, :jruby
          @external_deps[value] << key
          return
        when :optional, :recommended
          name = key
        end
      when Symbol
        name = name.to_s
      when Formula
        # noop
      else
        raise "Unsupported type #{name.class}"
      end

      @deps << name
    end

    def skip_clean paths
      @skip_clean_paths ||= []
      [paths].flatten.each do |p|
        @skip_clean_paths << p.to_s unless @skip_clean_paths.include? p.to_s
      end
    end
    
    def skip_clean_paths
      @skip_clean_paths or []
    end
  end
end

# see ack.rb for an example usage
class ScriptFileFormula <Formula
  def install
    bin.install Dir['*']
  end
end

# see flac.rb for example usage
class GithubGistFormula <ScriptFileFormula
  def initialize name='__UNKNOWN__'
    super name
    @version=File.basename(File.dirname(url))[0,6]
  end
end
