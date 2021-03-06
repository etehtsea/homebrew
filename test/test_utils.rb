require 'testing_env'

require 'homebrew/extend/ARGV' # needs to be after test/unit to avoid conflict with OptionsParser
ARGV.extend(HomebrewArgvExtension)

require 'homebrew/utils'


class UtilTests < Test::Unit::TestCase

  def test_put_columns_empty
    assert_nothing_raised do
      # Issue #217 put columns with new results fails.
      puts_columns []
    end
  end

  def test_arch_for_command
    arches=archs_for_command '/usr/bin/svn'
    if `sw_vers -productVersion` =~ /10\.(\d+)/ and $1.to_i >= 7
      assert_equal 2, arches.length
      assert arches.include?(:x86_64)
    elsif `sw_vers -productVersion` =~ /10\.(\d+)/ and $1.to_i == 6
      assert_equal 3, arches.length
      assert arches.include?(:x86_64)
      assert arches.include?(:ppc7400)
    else
      assert_equal 2, arches.length
      assert arches.include?(:ppc7400)
    end
    assert arches.include?(:i386)
  end

end
