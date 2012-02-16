module MacOS
  class << self
    def full_version
      @@full_version ||= `/usr/bin/sw_vers -productVersion`.chomp
    end

    def version
      @@version ||= /(10\.\d+)(\.\d+)?/.match(full_version).captures.first.to_f
    end

    def dev_tools_path
      @@dev_tools_path ||= if File.file? "/usr/bin/cc" and File.file? "/usr/bin/make"
        # probably a safe enough assumption
        "/usr/bin"
      elsif File.file? "#{xcode_prefix}/usr/bin/make"
        # cc stopped existing with Xcode 4.3, there are c89 and c99 options though
        "#{xcode_prefix}/usr/bin"
      else
        # yes this seems dumb, but we can't throw because the existance of
        # dev tools is not mandatory for installing formula. Eventually we
        # should make forumla specify if they need dev tools or not.
        "/usr/bin"
      end
    end

    def default_cc
      # Xcode 4.3.0 has no /Applications/Xcode/Contents/Developer/usr/bin/cc
      # Xcode 4.3.0 has no GCC
      cc = Pathname("#{dev_tools_path}/cc")
      llvm_gcc = Pathname("#{dev_tools_path}/llvm-gcc")
      @@default_cc |= (cc.file? ? cc : llvm_gcc).realpath.basename.to_s
    end

    def default_compiler
      @@default_compiler ||= case default_cc
                             when /^llvm/; :llvm
                             when "clang"; :clang
                             else
                               # guess :(
                               xcode_version >= "4.2" ? :llvm : :gcc
                             end
    end

    def gcc_42_build_version
      @@gcc_42_build_version ||= if File.exist? "#{dev_tools_path}/gcc-4.2" \
        and not Pathname.new("#{dev_tools_path}/gcc-4.2").realpath.basename.to_s =~ /^llvm/
        `#{dev_tools_path}/gcc-4.2 --version` =~ /build (\d{4,})/
        $1.to_i
      end
    end

    def gcc_40_build_version
      @@gcc_40_build_version ||= if File.exist? "#{dev_tools_path}/gcc-4.0"
        `#{dev_tools_path}/gcc-4.0 --version` =~ /build (\d{4,})/
        $1.to_i
      end
    end

    # usually /Developer
    def xcode_prefix
      @@xcode_prefix ||= begin
        path = `/usr/bin/xcode-select -print-path 2>&1`.chomp
        path = Pathname.new path
        if path.directory? and path.absolute?
          path
        elsif File.directory? '/Developer'
          # we do this to support cowboys who insist on installing
          # only a subset of Xcode
          Pathname.new '/Developer'
        elsif File.directory? '/Applications/Xcode.app/Contents/Developer'
          # fallback for broken Xcode 4.3 installs
          Pathname.new '/Applications/Xcode.app/Contents/Developer'
        else
          nil
        end
      end
    end

    def xcode_version
      @@xcode_version ||= begin
        raise unless system "/usr/bin/which -s xcodebuild"
        `xcodebuild -version 2>&1` =~ /Xcode (\d(\.\d)*)/
        raise if $1.nil?
        $1
      rescue
        # for people who don't have xcodebuild installed due to using
        # some variety of minimal installer, let's try and guess their
        # Xcode version
        case llvm_build_version.to_i
        when 0..2063 then "3.1.0"
        when 2064..2065 then "3.1.4"
        when 2366..2325
          # we have no data for this range so we are guessing
          "3.2.0"
        when 2326
          # also applies to "3.2.3"
          "3.2.4"
        when 2327..2333 then "3.2.5"
        when 2335
          # this build number applies to 3.2.6, 4.0 and 4.1
          # https://github.com/mxcl/homebrew/wiki/Xcode
          "4.0"
        else
          "4.2"
        end
      end
    end

    def llvm_build_version
      # for Xcode 3 on OS X 10.5 this will not exist
      # NOTE may not be true anymore but we can't test
      @@llvm_build_version ||= if File.exist? "#{dev_tools_path}/llvm-gcc"
        `#{dev_tools_path}/llvm-gcc --version` =~ /LLVM build (\d{4,})/
        $1.to_i
      end
    end

    def clang_version
      @@clang_version ||= if File.exist? "#{dev_tools_path}/clang"
        `#{dev_tools_path}/clang --version` =~ /clang version (\d\.\d)/
        $1
      end
    end

    def clang_build_version
      @@clang_build_version ||= if File.exist? "#{dev_tools_path}/clang"
        `#{dev_tools_path}/clang --version` =~ %r[tags/Apple/clang-(\d{2,})]
        $1.to_i
      end
    end

    def x11_installed?
      Pathname.new('/usr/X11/lib/libpng.dylib').exist?
    end

    def macports_or_fink_installed?
      # See these issues for some history:
      # http://github.com/mxcl/homebrew/issues/#issue/13
      # http://github.com/mxcl/homebrew/issues/#issue/41
      # http://github.com/mxcl/homebrew/issues/#issue/48

      %w[port fink].each do |ponk|
        path = `/usr/bin/which -s #{ponk}`
        return ponk unless path.empty?
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
      version >= 10.7
    end

    def prefer_64_bit?
      Hardware.is_64_bit? and snow_leopard?
    end

    def bottles_supported?
      lion? and Homebrew.prefix.to_s == '/usr/local' and Homebrew.cellar.to_s == '/usr/local/Cellar'
    end
  end
end
