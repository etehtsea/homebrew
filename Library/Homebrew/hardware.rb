module Hardware
  # These methods use info spewed out by sysctl.
  # Look in <mach/machine.h> for decoding info.

  class << self
    def cpu_type
      @cpu_type ||= `/usr/sbin/sysctl -n hw.cputype`.to_i

      case @cpu_type
      when 7 ; :intel
      when 18; :ppc
      else :dunno
      end
    end

    def intel_family
      @intel_family ||= `/usr/sbin/sysctl -n hw.cpufamily`.to_i

      case @intel_family
      when 0x73d67300; :core        # Yonah: Core Solo/Duo
      when 0x426f69ef; :core2       # Merom: Core 2 Duo
      when 0x78ea4fbc; :penryn      # Penryn
      when 0x6b5a4cd2; :nehalem     # Nehalem
      when 0x573B5EEC; :arrandale   # Arrandale
      when 0x5490B78C; :sandybridge # Sandy bridge
      else :dunno
      end
    end

    def processor_count
      @processor_count ||= `/usr/sbin/sysctl -n hw.ncpu`.to_i
    end

    def cores_as_words
      case processor_count
      when 1; 'single'
      when 2; 'dual'
      when 4; 'quad'
      else processor_count
      end
    end

    def is_32_bit?
      !is_64_bit?
    end

    def is_64_bit?
      sysctl_bool("hw.cpu64bit_capable")
    end

    def bits
      is_64_bit? ? 64 : 32
    end

    protected
    def sysctl_bool(property)
      result = nil
      IO.popen("/usr/sbin/sysctl -n #{property} 2>/dev/null") do |f|
        result = f.gets.to_i # should be 0 or 1
      end
      $?.success? && result == 1 # sysctl call succeded and printed 1
    end
  end
end
