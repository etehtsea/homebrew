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

    def xctools_fucked?
      # Xcode 4.3 tools hang if "/" is set
      `/usr/bin/xcode-select -print-path 2>/dev/null`.chomp == "/"
    end

    def default_cc
      cc = unless xctools_fucked?
        out = `/usr/bin/xcrun -find cc 2> /dev/null`.chomp
        out if $?.success?
      end
      cc = "#{dev_tools_path}/cc" if cc.nil? or cc.empty?

      unless File.executable? cc
        # If xcode-select isn't setup then xcrun fails and on Xcode 4.3
        # the cc binary is not at #{dev_tools_path}. This return is almost
        # worthless however since in this particular setup nothing much builds
        # but I wrote the code now and maybe we'll fix the other issues later.
        cc = "#{xcode_prefix}/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc"
      end
      @@default_cc ||= Pathname.new(cc).realpath.basename.to_s rescue nil
    end

    def default_compiler
      @@default_compiler ||= case default_cc
                             when /^llvm/; :llvm
                             when "clang"; :clang
                             else
                               # guess :(
                               if xcode_version >= "4.3"
                                 :clang
                               elsif xcode_version >= "4.2"
                                 :llvm
                               else
                                 :gcc
                               end
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

    def xcode_prefix
      @@xcode_prefix ||= begin
        path = `/usr/bin/xcode-select -print-path 2>/dev/null`.chomp
        path = Pathname.new path
        if $?.success? and path.directory? and path.absolute?
          path
        elsif File.directory? '/Developer'
          # we do this to support cowboys who insist on installing
          # only a subset of Xcode
          Pathname.new '/Developer'
        elsif File.directory? '/Applications/Xcode.app/Contents/Developer'
          # fallback for broken Xcode 4.3 installs
          Pathname.new '/Applications/Xcode.app/Contents/Developer'
        else
          # Ask Spotlight where Xcode is. If the user didn't install the
          # helper tools and installed Xcode in a non-conventional place, this
          # is our only option. See: http://superuser.com/questions/390757
          path = `mdfind "kMDItemDisplayName==Xcode&&kMDItemKind==Application"`
          path = "#{path}/Contents/Developer"
          if path.empty? or not File.directory? path
            nil
          else
            path
          end
        end
      end
    end

    def xcode_version
      @@xcode_version ||= begin
        # Xcode 4.3 xc* tools hang indefinately if xcode-select path is set thus
        raise if `xcode-select -print-path 2>/dev/null`.chomp == "/"

        raise unless system "/usr/bin/which -s xcodebuild"
        `xcodebuild -version 2>/dev/null` =~ /Xcode (\d(\.\d)*)/
        raise if $1.nil? or not $?.success?
        $1
      rescue
        # For people who's xcode-select is unset, or who have installed
        # xcode-gcc-installer or whatever other combinations we can try and
        # supprt. See https://github.com/mxcl/homebrew/wiki/Xcode
        case nil
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
        case (clang_version.to_f * 10).to_i
          when 0..14;  "3.2.2"
          when 15;     "3.2.4"
          when 16;     "3.2.5"
          when 17..20; "4.0"
          when 21;     "4.1"
          when 22..30; "4.2"
          when 31;     "4.3"
          else
            "4.3"
          end
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
      version >= 10.7 # Actually Lion or newer
    end

    def mountain_lion?
      version >= 10.8 # Actually Mountain Lion or newer
    end

    def prefer_64_bit?
      Hardware.is_64_bit? and not leopard?
    end

    def bottles_supported?
      lion? and Homebrew.prefix.to_s == '/usr/local' and Homebrew.cellar.to_s == '/usr/local/Cellar'
    end
  end
end
