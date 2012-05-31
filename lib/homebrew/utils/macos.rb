module Homebrew
  module Utils
    module MacOS
      class << self
        def full_version
          @@full_version ||= `/usr/bin/sw_vers -productVersion`.chomp
        end

        def version
          @@version ||= /(10\.\d+)(\.\d+)?/.match(full_version).captures.first.to_f
        end

        def cat
          if mountain_lion?
            :mountainlion
          elsif lion?
            :lion
          elsif snow_leopard?
            :snowleopard
          elsif leopard?
            :leopard
          else
            nil
          end
        end

        def default_compiler
          @@default_compiler ||=
            if xcode_version >= '4.3'
              :clang
            elsif xcode_version >= '4.2'
              :llvm
            elsif xcode_version < '4.2'
              :gcc
            else
              # FIXME: fallback properly
              :clang
            end
        end

        def gcc_42_build_version
          @@gcc_42_build_version ||= build_version('gcc-4.2')
        end

        def gcc_40_build_version
          @@gcc_40_build_version ||= build_version('gcc-4.0')
        end

        def llvm_build_version
          # for Xcode 3 on OS X 10.5 this will not exist
          # NOTE may not be true anymore but we can't test
          @@llvm_build_version ||= build_version('llvm-gcc')
        end

        def clang_build_version
          @@clang_build_version ||= build_version('clang')
        end

        def clang_version
          @@clang_version ||= if Unix.available?('clang')
            `clang --version 2>/dev/null` =~ /clang version (\d\.\d)/
            $1 if $?.success?
          end
        end

        def xcode_prefix
          @@xcode_prefix ||= if Unix.available?('xcode-select')
            Pathname(`xcode-select -print-path 2>/dev/null`.chomp)
          end
        end

        def xcode_version
          @@xcode_version ||=
            if Unix.available?('xcrun') && File.exist?(`xcrun -find xcodebuild`.strip)
              `xcrun xcodebuild -version 2>/dev/null` =~ /Xcode (\d(\.\d)*)/
              $1 if $?.success?
            else
              # FIXME: added for compatibility with a couple of formulas which are
              # checking xcode version
              'unknown'
            end
        end

        def xcode_installed?
          !!(Unix.available?('xcrun') && File.exist?(`xcrun -find xcodebuild`.strip))
        end

        def x11_installed?
          Pathname('/usr/X11/lib/libpng.dylib').exist?
        end

        def macports_or_fink_installed?
          # See these issues for some history:
          # http://github.com/mxcl/homebrew/issues/#issue/13
          # http://github.com/mxcl/homebrew/issues/#issue/41
          # http://github.com/mxcl/homebrew/issues/#issue/48

          %w[port fink].each do |ponk|
            return ponk if Unix.available?(ponk)
          end

          # we do the above check because macports can be relocated and fink may be
          # able to be relocated in the future. This following check is because if
          # fink and macports are not in the PATH but are still installed it can
          # *still* break the build -- because some build scripts hardcode these paths:
          %w[/sw/bin/fink /opt/local/bin/port].each do |ponk|
            return ponk if File.exist? ponk
          end

          # finally, sometimes people make their MacPorts or Fink read-only so they
          # can quickly test Homebrew out, but still in theory obey the README's
          # advise to rename the root directory. This doesn't work, many build scripts
          # error out when they try to read from these now unreadable directories.
          %w[/sw /opt/local].each do |path|
            path = Pathname.new(path)
            return path if path.exist? and not path.readable?
          end

          false
        end

        def leopard?
          version == 10.5
        end

        # Actually Snow Leopard or newer
        def snow_leopard?
          version >= 10.6
        end

        # Actually Lion or newer
        def lion?
          version >= 10.7 # Actually Lion or newer
        end

        def mountain_lion?
          version >= 10.8 # Actually Mountain Lion or newer
        end

        def prefer_64_bit?
          Hardware.is_64_bit? and not leopard?
        end

      private
        def build_version(cc)
          if Unix.available?(cc)
            regexp = case cc
                     when /gcc/  ; /build (\d{4,})/
                     when /llvm/ ; /LLVM build (\d{4,})/
                     when /clang/; %r[tags/Apple/clang-(\d{2,})]
                     end
            `#{cc} --version 2>/dev/null` =~ regexp
            $1.to_i if $?.success?
          end
        end
      end
    end
  end
end
