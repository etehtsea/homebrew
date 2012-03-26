module Homebrew
  module Cmd
    class << self
      def __config
        puts config_s
      end

    private

      def sha
        sha = Git::Repo.new(Homebrew.repository).head
        sha.empty? ? "(none)" : sha
      end

      def describe(interpreter)
        path = Pathname(Unix.which(interpreter))

        if path.exist?
          path.symlink? ? "#{path} => #{real_path(path)}" : path
        else
          "N/A"
        end
      end

      def real_path(a_path)
        Pathname(a_path).realpath
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
        X11: #{MacOS.x11_installed? ? real_path('/usr/X11') : "N/A"}
        System Ruby: #{RUBY_VERSION}-#{RUBY_PATCHLEVEL}
        /usr/bin/ruby => #{real_path('/usr/bin/ruby')}
        Which Perl:   #{describe('perl')}
        Which Python: #{describe('python')}
        Which Ruby:   #{describe('ruby')}
        EOS
      end
    end
  end
end
