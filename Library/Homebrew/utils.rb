require 'pathname'
require 'exceptions'
require 'compat/compatibility'

module Utils
  module Tty
    class << self
      def blue;   bold 34;      end
      def white;  bold 39;      end
      def red;    underline 31; end
      def yellow; underline 33; end
      def reset;  escape 0;     end
      def em;     underline 39; end
      def green;  color 92      end

      def width
        `/usr/bin/tput cols`.strip.to_i
      end

      private
      def color(n);     escape "0;#{n}"; end
      def bold(n);      escape "1;#{n}"; end
      def underline(n); escape "4;#{n}"; end

      def escape(n)
        "\033[#{n}m" if $stdout.tty?
      end
    end
  end

  module MakefileInreplace
    extend ::Deprecation

    # Looks for Makefile style variable defintions and replaces the
    # value with "new_value", or removes the definition entirely.
    def change_var!(flag, new_value)
      new_value = "#{flag}=#{new_value}"
      gsub! Regexp.new("^#{flag}[ \\t]*=[ \\t]*(.*)$"), new_value
    end

    # Removes variable assignments completely.
    def remove_var!(flags)
      Array(flags).each do |flag|
        # Also remove trailing \n, if present.
        gsub! Regexp.new("^#{flag}[ \\t]*=(.*)$\n?"), ""
      end
    end

    # Finds the specified variable
    def get_var(flag)
      m = match Regexp.new("^#{flag}[ \\t]*=[ \\t]*(.*)$")

      m ? m[1] : nil
    end

    deprecate :change_make_var!, :change_var!
    deprecate :remove_make_var!, :remove_var!
    deprecate :get_make_var!, :get_var!
  end

  module ArchitectureListExtension
    def universal?
      self.include? :i386 and self.include? :x86_64
    end

    def remove_ppc!
      self.delete :ppc7400
      self.delete :ppc64
    end

    def as_arch_flags
      self.collect{ |a| "-arch #{a}" }.join(' ')
    end
  end

  # args are additional inputs to puts until a nil arg is encountered
  def ohai title, *sput
    title = title.to_s[0, Tty.width - 4] unless ARGV.verbose?
    puts "#{Tty.blue}==>#{Tty.white} #{title}#{Tty.reset}"
    puts sput unless sput.empty?
  end

  def oh1 title
    title = title.to_s[0, Tty.width - 4] unless ARGV.verbose?
    puts "#{Tty.green}==> #{Tty.reset}#{title}"
  end

  def opoo warning
    puts "#{Tty.red}Warning#{Tty.reset}: #{warning}"
  end

  def onoe error
    lines = error.to_s.split'\n'
    puts "#{Tty.red}Error#{Tty.reset}: #{lines.shift}"
    puts lines unless lines.empty?
  end

  def pretty_duration s
    return "2 seconds" if s < 3 # avoids the plural problem ;)
    return "#{s.to_i} seconds" if s < 120
    return "%.1f minutes" % (s/60)
  end

  def interactive_shell f=nil
    unless f.nil?
      ENV['HOMEBREW_DEBUG_PREFIX'] = f.prefix
      ENV['HOMEBREW_DEBUG_INSTALL'] = f.name
    end

    fork {exec ENV['SHELL'] }
    Process.wait
    unless $?.success?
      puts "Aborting due to non-zero exit status"
      exit $?
    end
  end

  # Kernel.system but with exceptions
  def safe_system cmd, *args
    unless Homebrew.system cmd, *args
      args = args.map{ |arg| arg.to_s.gsub " ", "\\ " } * " "
      raise ErrorDuringExecution, "Failure while executing: #{cmd} #{args}"
    end
  end

  # prints no output
  def quiet_system cmd, *args
    Homebrew.system(cmd, *args) do
      $stdout.close
      $stderr.close
    end
  end

  def curl *args
    curl = Pathname.new '/usr/bin/curl'
    raise "#{curl} is not executable" unless curl.exist? and curl.executable?

    args = [Homebrew.curl_args, Homebrew.user_agent, *args]
    # See https://github.com/mxcl/homebrew/issues/6103
    args << "--insecure" if MacOS.version < 10.6
    args << "--verbose" if ENV['HOMEBREW_CURL_VERBOSE']

    safe_system curl, *args
  end

  def puts_columns items
    return if items.empty?

    if $stdout.tty?
      # determine the best width to display for different console sizes
      console_width = `/bin/stty size`.chomp.split(" ").last.to_i
      console_width = 80 if console_width <= 0
      longest = items.sort_by { |item| item.length }.last
      optimal_col_width = (console_width.to_f / (longest.length + 2).to_f).floor
      cols = optimal_col_width > 1 ? optimal_col_width : 1

      IO.popen("/usr/bin/pr -#{cols} -t -w#{console_width}", "w"){ |io| io.puts(items) }
    else
      puts items
    end
  end

  def which_editor
    editor = ENV['HOMEBREW_EDITOR'] || ENV['EDITOR']
    # If an editor wasn't set, try to pick a sane default
    return editor unless editor.nil?

    # Find Textmate
    return 'mate' if system "/usr/bin/which -s mate"
    # Find # BBEdit / TextWrangler
    return 'edit' if system "/usr/bin/which -s edit"
    # Default to vim
    return '/usr/bin/vim'
  end

  def exec_editor *args
    return if args.to_s.empty?

    # Invoke bash to evaluate env vars in $EDITOR
    # This also gets us proper argument quoting.
    # See: https://github.com/mxcl/homebrew/issues/5123
    system "bash", "-c", which_editor + ' "$@"', "--", *args
  end

  # GZips the given paths, and returns the gzipped paths
  def gzip *paths
    paths.collect do |path|
      system "/usr/bin/gzip", path
      Pathname.new("#{path}.gz")
    end
  end

  # Returns array of architectures that the given command or library is built for.
  def archs_for_command cmd
    cmd = cmd.to_s # If we were passed a Pathname, turn it into a string.
    cmd = `/usr/bin/which #{cmd}` unless Pathname.new(cmd).absolute?
    cmd.gsub! ' ', '\\ '  # Escape spaces in the filename.

    lines = `/usr/bin/file -L #{cmd}`
    archs = lines.to_a.inject([]) do |archs, line|
      case line
      when /Mach-O (executable|dynamically linked shared library) ppc/
        archs << :ppc7400
      when /Mach-O 64-bit (executable|dynamically linked shared library) ppc64/
        archs << :ppc64
      when /Mach-O (executable|dynamically linked shared library) i386/
        archs << :i386
      when /Mach-O 64-bit (executable|dynamically linked shared library) x86_64/
        archs << :x86_64
      else
        archs
      end
    end
    archs.extend(ArchitectureListExtension)
  end

  def inreplace path, before=nil, after=nil
    [*path].each do |path|
      f = File.open(path, 'r')
      s = f.read

      if before == nil and after == nil
        s.extend(MakefileInreplace)
        yield s
      else
        s.gsub!(before, after)
      end

      f.reopen(path, 'w').write(s)
      f.close
    end
  end

  def ignore_interrupts
    std_trap = trap("INT") {}
    yield
  ensure
    trap("INT", std_trap)
  end

  def nostdout
    if ARGV.verbose?
      yield
    else
      begin
        require 'stringio'
        real_stdout = $stdout
        $stdout = StringIO.new
        yield
      ensure
        $stdout = real_stdout
      end
    end
  end
end
