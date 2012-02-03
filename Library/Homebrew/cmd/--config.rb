require 'hardware'

module Homebrew extend self
  def __config
    puts config_s
  end

  def sha
    sha = Homebrew.repository.cd do
      `git rev-parse --verify -q HEAD 2>/dev/null`.chomp
    end

    sha.empty? ? "(none)" : sha
  end

  def describe_perl
    perl = `which perl`.chomp
    return "N/A" unless perl

    real_perl = Pathname.new(perl).realpath.to_s
    return perl if perl == real_perl
    return "#{perl} => #{real_perl}"
  end

  def describe_python
    python = `which python`.chomp
    return "N/A" unless python

    real_python = Pathname.new(python).realpath.to_s

    return python if python == real_python
    return "#{python} => #{real_python}"
  end

  def describe_ruby
    ruby = `which ruby`.chomp
    return "N/A" unless ruby

    real_ruby = Pathname.new(ruby).realpath.to_s
    return ruby if ruby == real_ruby
    return "#{ruby} => #{real_ruby}"
  end

  def real_path a_path
    Pathname.new(a_path).realpath.to_s
  end

  def config_s; <<-EOS.undent
    HOMEBREW_VERSION: #{Homebrew.version}
    HEAD: #{sha}
    HOMEBREW_PREFIX: #{Homebrew.prefix}
    HOMEBREW_CELLAR: #{Homebrew.cellar}
    Hardware: #{Hardware.cores_as_words}-core #{Hardware.bits}-bit #{Hardware.intel_family}
    OS X: #{MacOS.full_version}
    Kernel Architecture: #{`uname -m`.chomp}
    Xcode: #{MacOS.xcode_version}
    GCC-4.0: #{MacOS.gcc_40_build_version ? "build #{MacOS.gcc_40_build_version}" : "N/A"}
    GCC-4.2: #{MacOS.gcc_42_build_version ? "build #{MacOS.gcc_42_build_version}" : "N/A"}
    LLVM: #{MacOS.llvm_build_version ? "build #{MacOS.llvm_build_version}" : "N/A"}
    Clang: #{MacOS.clang_version ? "#{MacOS.clang_version} build #{MacOS.clang_build_version}" : "N/A"}
    MacPorts or Fink? #{MacOS.macports_or_fink_installed?}
    X11 installed? #{MacOS.x11_installed?}
    System Ruby: #{RUBY_VERSION}-#{RUBY_PATCHLEVEL}
    /usr/bin/ruby => #{real_path("/usr/bin/ruby")}
    Which Perl:   #{describe_perl}
    Which Python: #{describe_python}
    Which Ruby:   #{describe_ruby}
    EOS
  end
end
