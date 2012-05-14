require 'testing_env'

require 'homebrew/extend/ARGV' # needs to be after test/unit to avoid conflict with OptionsParser
ARGV.extend(HomebrewArgvExtension)

class HardwareTests < Test::Unit::TestCase
  # these will raise if we don't recognise your mac, but that prolly
  # indicates something went wrong rather than we don't know
  def test_hardware_cpu_type
    assert [:intel, :ppc].include?(Hardware.cpu_type)
  end

  def test_hardware_intel_family
    if Hardware.cpu_type == :intel
      assert [:core, :core2, :penryn, :nehalem, :sandybridge].include?(Hardware.intel_family)
    end
  end

  def test_cores_as_word
    Hardware.instance_eval { @processor_count = 'invalid' }
    assert Hardware.cores_as_words == Hardware.processor_count
  end
end
