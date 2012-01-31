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

  def config_s; <<-EOS.undent
    HOMEBREW_VERSION: #{Homebrew.version}
    HEAD: #{sha}
    HOMEBREW_PREFIX: #{Homebrew.prefix}
    HOMEBREW_CELLAR: #{Homebrew.cellar}
    Hardware: #{Hardware.cores_as_words}-core #{Hardware.bits}-bit #{Hardware.intel_family}
    OS X: #{MacOS.full_version}
    Kernel Architecture: #{`uname -m`.chomp}
    Ruby: #{RUBY_VERSION}-#{RUBY_PATCHLEVEL}
    /usr/bin/ruby => #{Pathname.new('/usr/bin/ruby').realpath.to_s}
    Xcode: #{MacOS.xcode_version}
    GCC-4.0: #{MacOS.gcc_40_build_version ? "build #{MacOS.gcc_40_build_version}" : "N/A"}
    GCC-4.2: #{MacOS.gcc_42_build_version ? "build #{MacOS.gcc_42_build_version}" : "N/A"}
    LLVM: #{MacOS.llvm_build_version ? "build #{MacOS.llvm_build_version}" : "N/A"}
    Clang: #{MacOS.clang_version ? "#{MacOS.clang_version} build #{MacOS.clang_build_version}" : "N/A"}
    MacPorts or Fink? #{macports_or_fink_installed?}
    X11 installed? #{x11_installed?}
    EOS
  end
end
