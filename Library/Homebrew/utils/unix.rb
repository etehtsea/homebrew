require 'pathname'

module Utils::Unix
  module_function

  def system(cmd, *args)
    puts "#{cmd} #{args*' '}" if ARGV.verbose?

    fork do
      yield if block_given?
      args.collect! { |arg| arg.to_s}
      exec(cmd, *args) rescue nil
      exit! 1 # never gets here unless exec failed
    end

    Process.wait
    $?.success?
  end

  # Kernel.system but with exceptions
  def safe_system(cmd, *args)
    unless Unix.system(cmd, *args)
      args = args.map { |arg| arg.to_s.gsub " ", "\\ " } * " "
      raise ErrorDuringExecution, "Failure while executing: #{cmd} #{args}"
    end
  end

  # prints no output
  def quiet_system cmd, *args
    Unix.system(cmd, *args) do
      $stdout.close
      $stderr.close
    end
  end

  def execute(cmd)
    out = `#{cmd}`
    if $? && !$?.success?
      $stderr.puts out
      raise "Failed while executing #{cmd}"
    end
    ohai(cmd, out) if ARGV.verbose?
    out
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
    archs.extend(ArchitectureList)
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

  def curl *args
    curl = Pathname('/usr/bin/curl')
    raise "#{curl} is not executable" unless curl.exist? and curl.executable?

    args = [Homebrew.curl_args, Homebrew.user_agent, *args]
    # See https://github.com/mxcl/homebrew/issues/6103
    args << "--insecure" if MacOS.version < 10.6
    args << "--verbose" if ENV['HOMEBREW_CURL_VERBOSE']
    args << "--silent" unless $stdout.tty?

    safe_system curl, *args
  end

  def available?(bin)
    system("which -s #{bin}")
  end

  def which(infile)
    stdout = execute("which #{infile}")
    Pathname(stdout.strip) unless stdout.empty?
  end

  def interactive_shell(f = nil)
    unless f.nil?
      ENV['HOMEBREW_DEBUG_PREFIX'] = f.prefix
      ENV['HOMEBREW_DEBUG_INSTALL'] = f.name
    end

    fork { exec ENV['SHELL'] }
    Process.wait
    unless $?.success?
      puts "Aborting due to non-zero exit status"
      exit $?
    end
  end
end
