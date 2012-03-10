module Utils::Hardware
  # These methods use info spewed out by sysctl.
  # Look in <mach/machine.h> for decoding info.
  CPU_TYPES = { 7 => :intel, 18 => :ppc }
  INTEL_FAMILIES = {
    0x73d67300 => :core,        # Yonah: Core Solo/Duo
    0x426f69ef => :core2,       # Merom: Core 2 Duo
    0x78ea4fbc => :penryn,      # Penryn
    0x6b5a4cd2 => :nehalem,     # Nehalem
    0x573B5EEC => :arrandale,   # Arrandale
    0x5490B78C => :sandybridge, # Sandy bridge
  }

  class << self
    def cpu_type
      @cpu_type ||= CPU_TYPES[sysctl_value 'hw.cputype'] || :dunno
    end

    def intel_family
      @intel_family ||= INTEL_FAMILIES[sysctl_value 'hw.cpufamily'] || :dunno
    end

    def processor_count
      @processor_count ||= sysctl_value 'hw.ncpu'
    end

    def cores_as_words
      quantity = { 1 => 'single', 2 => 'dual' , 4 => 'quad' }
      @cores_as_words ||= quantity[processor_count] || processor_count.to_s
    end

    def is_32_bit?
      !is_64_bit?
    end

    def is_64_bit?
      sysctl_value 'hw.cpu64bit_capable'
    end

    def bits
      is_64_bit? ? 64 : 32
    end

    private
    def sysctl_value(variable)
      `/usr/sbin/sysctl -n #{variable}`.to_i
    end
  end
end
