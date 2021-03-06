module Homebrew
  module Env
    # -w: keep signal to noise high
    SAFE_CFLAGS_FLAGS = "-w -pipe"

    def setup_build_environment
      # Clear CDPATH to avoid make issues that depend on changing directories
      delete('CDPATH')
      delete('GREP_OPTIONS') # can break CMake (lol)
      delete('CLICOLOR_FORCE') # autotools doesn't like this

      # make any aclocal stuff installed in Homebrew available
      if MacOS.xcode_version < "4.3"
        ENV['ACLOCAL_PATH'] = "#{Homebrew.prefix}/share/aclocal"
      end

      unless Homebrew.prefix.to_s == '/usr/local'
        # /usr/local is already an -isystem and -L directory so we skip it
        self['CPPFLAGS'] = "-isystem #{Homebrew.prefix}/include"
        self['LDFLAGS'] = "-L#{Homebrew.prefix}/lib"
        # CMake ignores the variables above
        self['CMAKE_PREFIX_PATH'] = "#{Homebrew.prefix}"
      end

      # set us up for the user's compiler choice

      # TODO seems that ENV.clang in a Formula.install should warn when called
      # if the user has set something that is tested here

      # test for --flags first so that installs can be overridden on a per
      # install basis. Then test for ENVs in inverse order to flags, this is
      # sensible, trust me
       if ARGV.include? '--use-gcc'
        gcc
      elsif ARGV.include? '--use-llvm'
        llvm
      elsif ARGV.include? '--use-clang'
        clang
      elsif (ENV['CC'] =~ /gcc/) || (ENV['CXX'] =~ /g\+\+/)
        gcc
      elsif (ENV['CC'] =~ /clang/) || (ENV['CXX'] =~ /clang\+\+/)
        clang
      elsif self['HOMEBREW_USE_CLANG']
        clang
      elsif self['HOMEBREW_USE_LLVM']
        clang
      elsif self['HOMEBREW_USE_GCC']
        gcc
      else
        MacOS.default_compiler
      end
    end


    ### Optimizations ###

    def deparallelize
      remove 'MAKEFLAGS', /-j\d+/
    end
    alias_method :j1, :deparallelize

    # recommended by Apple, but, eg. wget won't compile with this flag, so…
    def fast
      remove_from_cflags(/-O./)
      append_to_cflags '-fast'
    end

    def O4
      # LLVM link-time optimization
      remove_from_cflags(/-O./)
      append_to_cflags '-O4'
    end

    def O3
      # Sometimes O4 just takes fucking forever
      remove_from_cflags(/-O./)
      append_to_cflags '-O3'
    end

    def O2
      # Sometimes O3 doesn't work or produces bad binaries
      remove_from_cflags(/-O./)
      append_to_cflags '-O2'
    end

    def Os
      # Sometimes you just want a small one
      remove_from_cflags(/-O./)
      append_to_cflags '-Os'
    end

    def Og
      # Sometimes you want a debug build
      remove_from_cflags(/-O./)
      append_to_cflags '-g -O0'
    end

    def O1
      # Sometimes even O2 doesn't work :(
      remove_from_cflags(/-O./)
      append_to_cflags '-O1'
    end

    def minimal_optimization
      self['CFLAGS'] = self['CXXFLAGS'] = "-Os #{SAFE_CFLAGS_FLAGS}"
    end

    def no_optimization
      self['CFLAGS'] = self['CXXFLAGS'] = SAFE_CFLAGS_FLAGS
    end


    ### Compilers ###

    def gcc_4_0_1
      compiler(:gcc, 'gcc-4.0', 'g++-4.0') do
        replace_in_cflags '-O4', '-O3'
        set_cpu_cflags 'nocona -mssse3',
          :core => 'prescott',
          :bottle => 'generic'
      end
    end
    alias_method :gcc_4_0, :gcc_4_0_1

    def gcc
      # Apple stopped shipping gcc-4.2 with Xcode 4.2
      # However they still provide a gcc symlink to llvm
      # But we don't want LLVM of course.

      compiler(:gcc, 'gcc-4.2', 'g++-4.2') do
        replace_in_cflags '-O4', '-O3'
        set_cpu_cflags 'core2 -msse4',
          :penryn => 'core2 -msse4.1',
          :core2 => 'core2',
          :core => 'prescott',
          :bottle => 'generic'
      end
    end
    alias_method :gcc_4_2, :gcc

    def llvm
      compiler(:llvm, 'llvm-gcc', 'llvm-g++') do
        set_cpu_cflags 'core2 -msse4',
          :penryn => 'core2 -msse4.1',
          :core2 => 'core2',
          :core => 'prescott'
      end
    end

    def clang
      compiler(:clang, 'clang', 'clang++') do
        replace_in_cflags(/-Xarch_i386 (-march=\S*)/, '\1')

        # Clang mistakenly enables AES-NI on plain Nehalem
        set_cpu_cflags 'native',
          :nehalem => 'native -Xclang -target-feature -Xclang -aes'

        append_to_cflags '-Qunused-arguments'
      end
    end

    def fortran
      if self['FC']
        ohai "Building with an alternative Fortran compiler. This is unsupported."
        self['F77'] = self['FC'] unless self['F77']

        if ARGV.include? '--default-fortran-flags'
          flags_to_set = []
          flags_to_set << 'FCFLAGS' unless self['FCFLAGS']
          flags_to_set << 'FFLAGS' unless self['FFLAGS']

          flags_to_set.each { |key| self[key] = cflags }

          # Ensure we use architecture optimizations for GCC 4.2.x
          set_cpu_flags flags_to_set, 'core2 -msse4',
            :penryn => 'core2 -msse4.1',
            :core2 => 'core2',
            :core => 'prescott',
            :bottle => 'generic'
        elsif not self['FCFLAGS'] or self['FFLAGS']
          opoo <<-EOS.undent
          No Fortran optimization information was provided.  You may want to consider
          setting FCFLAGS and FFLAGS or pass the `--default-fortran-flags` option to
          `brew install` if your compiler is compatible with GCC.

          If you like the default optimization level of your compiler, ignore this
          warning.
          EOS
        end

      elsif Unix.which('gfortran').size > 0
        ohai <<-EOS.undent
        Using Homebrew-provided fortran compiler.
        This may be changed by setting the FC environment variable.
        EOS
        self['FC'] = `/usr/bin/which gfortran`.chomp
        self['F77'] = self['FC']

        fc_flag_vars.each {|key| self[key] = cflags}
        # Ensure we use architecture optimizations for GCC 4.2.x
        set_cpu_flags fc_flag_vars, 'core2 -msse4',
          :penryn => 'core2 -msse4.1',
          :core2 => 'core2',
          :core => 'prescott',
          :bottle => 'generic'
      else
        onoe <<-EOS.undnet
        This formula requires a fortran compiler, but we could not find one by
        looking at the FC environment variable or searching your PATH for `gfortran`.
        Please take one of the following actions:

        - Decide to use the build of gfortran 4.2.x provided by Homebrew using
              `brew install gfortran`

        - Choose another Fortran compiler by setting the FC environment variable:
              export FC=/path/to/some/fortran/compiler
        Using an alternative compiler may produce more efficient code, but we will
        not be able to provide support for build errors.
        EOS
        exit 1
      end
    end


    ### Other ###

    # Some configure scripts won't find libxml2 without help
    def libxml2
      append 'CPPFLAGS', '-I/usr/include/libxml2'
    end

    def x11
      opoo "You do not have X11 installed, this formula may not build." unless MacOS.x11_installed?

      # There are some config scripts (e.g. freetype) here that should go in the path
      prepend 'PATH', '/usr/X11/bin', ':'
      # CPPFLAGS are the C-PreProcessor flags, *not* C++!
      append 'CPPFLAGS', '-I/usr/X11/include'
      append 'LDFLAGS', '-L/usr/X11/lib'
      # CMake ignores the variables above
      append 'CMAKE_PREFIX_PATH', '/usr/X11', ':'
    end
    alias_method :libpng, :x11

    # we've seen some packages fail to build when warnings are disabled!
    def enable_warnings
      remove_from_cflags '-w'
      remove_from_cflags '-Qunused-arguments'
    end

    # Snow Leopard defines an NCURSES value the opposite of most distros
    # See: http://bugs.python.org/issue6848
    def ncurses_define
      append 'CPPFLAGS', "-DNCURSES_OPAQUE=0"
    end

    # Shortcuts for reading common flags
    def cc;      self['CC'] or "gcc";  end
    def cxx;     self['CXX'] or "g++"; end
    def cflags;  self['CFLAGS'];       end
    def cxxflags;self['CXXFLAGS'];     end
    def cppflags;self['CPPFLAGS'];     end
    def ldflags; self['LDFLAGS'];      end

    def m64
      append_to_cflags '-m64'
      append 'LDFLAGS', '-arch x86_64'
    end

    def m32
      append_to_cflags '-m32'
      append 'LDFLAGS', '-arch i386'
    end

    # i386 and x86_64 (no PPC)
    def universal_binary
      append_to_cflags '-arch i386 -arch x86_64'
      replace_in_cflags '-O4', '-O3' # O4 seems to cause the build to fail
      append 'LDFLAGS', '-arch i386 -arch x86_64'

      unless @compiler == :clang
        # Can't mix "-march" for a 32-bit CPU  with "-arch x86_64"
        replace_in_cflags(/-march=\S*/, '-Xarch_i386 \0') if Hardware.is_32_bit?
      end
    end

    def prepend key, value, separator = ' '
      # Value should be a string, but if it is a pathname then coerce it.
      value = value.to_s

      [*key].each do |key|
        unless self[key].to_s.empty?
          self[key] = value + separator + self[key]
        else
          self[key] = value
        end
      end
    end

    def append key, value, separator = ' '
      # Value should be a string, but if it is a pathname then coerce it.
      value = value.to_s

      [*key].each do |key|
        unless self[key].to_s.empty?
          self[key] = self[key] + separator + value
        else
          self[key] = value
        end
      end
    end

    def append_to_cflags f
      append cc_flag_vars, f
    end

    def remove key, value
      [*key].each do |key|
        next if self[key].nil?
        self[key] = self[key].sub value, '' # can't use sub! on ENV
        self[key] = nil if self[key].empty? # keep things clean
      end
    end

    def remove_from_cflags f
      remove cc_flag_vars, f
    end

    def replace_in_cflags before, after
      cc_flag_vars.each do |key|
        self[key] = self[key].sub before, after if self[key]
      end
    end

    def make_jobs
      # '-j' requires a positive integral argument
      if self['HOMEBREW_MAKE_JOBS'].to_i > 0
        self['HOMEBREW_MAKE_JOBS']
      else
        Hardware.processor_count
      end
    end

  private

    # Shortcuts for lists of common flags
    def cc_flag_vars
      %w{CFLAGS CXXFLAGS OBJCFLAGS OBJCXXFLAGS}
    end

    def fc_flag_vars
      %w{FCFLAGS FFLAGS}
    end

    # Convenience method to set all C compiler flags in one shot.
    def set_cflags f
      cc_flag_vars.each { |key| self[key] = f }
    end

    # Sets architecture-specific flags for every environment variable
    # given in the list `flags`.
    def set_cpu_flags flags, default, map = {}
      cflags =~ %r{(-Xarch_i386 )-march=}
      xarch = $1.to_s
      remove flags, %r{(-Xarch_i386 )?-march=\S*}
      remove flags, %r{( -Xclang \S+)+}
      remove flags, %r{-mssse3}
      remove flags, %r{-msse4(\.\d)?}
      append flags, xarch unless xarch.empty?

      if ARGV.build_bottle?
        append flags, '-mtune=' + map.fetch(:bottle) if map.has_key? :bottle
      else
        # Don't set -msse3 and older flags because -march does that for us
        append flags, '-march=' + map.fetch(Hardware.intel_family, default)
      end

      # not really a 'CPU' cflag, but is only used with clang
      remove flags, '-Qunused-arguments'
    end

    def set_cpu_cflags default, map = {}
      set_cpu_flags cc_flag_vars, default, map
    end

    def compiler(cf, cc, cxx, *flags)
      self['MAKEFLAGS'] = "-j#{make_jobs}" unless self['MAKEFLAGS']
      self['CC'] = cc unless self['CC']
      self['CXX'] = cxx unless self['CXX']

      unless self['CFLAGS']
        # Os is the default Apple uses for all its stuff so let's trust them
        set_cflags "-Os #{SAFE_CFLAGS_FLAGS}"
        yield if block_given?
      end

      @compiler = cf

      # In rare cases this may break your builds, as the tool for some reason wants
      # to use a specific linker. However doing this in general causes formula to
      # build more successfully because we are changing CC and many build systems
      # don't react properly to that.
      self['LD'] = self['CC']

      self['CXXFLAGS'] = self['CFLAGS'] unless self['CXXFLAGS']
    end
  end
end
