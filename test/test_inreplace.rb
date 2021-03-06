require 'testing_env'
require 'homebrew/utils'

class InreplaceTest < Test::Unit::TestCase
  def test_change_var
    # Replace flag
    s1="OTHER=def\nFLAG = abc\nFLAG2=abc"
    s1.extend(MakefileInreplace)
    s1.change_var! "FLAG", "def"
    assert_equal "OTHER=def\nFLAG=def\nFLAG2=abc", s1
  end

  def test_change_var_empty
    # Replace empty flag
    s1="OTHER=def\nFLAG = \nFLAG2=abc"
    s1.extend(MakefileInreplace)
    s1.change_var! "FLAG", "def"
    assert_equal "OTHER=def\nFLAG=def\nFLAG2=abc", s1
  end

  def test_change_var_empty_2
    # Replace empty flag
    s1="FLAG = \nmv file_a file_b"
    s1.extend(MakefileInreplace)
    s1.change_var! "FLAG", "def"
    assert_equal "FLAG=def\nmv file_a file_b", s1
  end

  def test_change_var_append
    # Append to flag
    s1="OTHER=def\nFLAG = abc\nFLAG2=abc"
    s1.extend(MakefileInreplace)
    s1.change_var! "FLAG", "\\1 def"
    assert_equal "OTHER=def\nFLAG=abc def\nFLAG2=abc", s1
  end

  def test_change_var_shell_style
    # Shell variables have no spaces around =
    s1="OTHER=def\nFLAG=abc\nFLAG2=abc"
    s1.extend(MakefileInreplace)
    s1.change_var! "FLAG", "def"
    assert_equal "OTHER=def\nFLAG=def\nFLAG2=abc", s1
  end

  def test_remove_var
    # Replace flag
    s1="OTHER=def\nFLAG = abc\nFLAG2 = def"
    s1.extend(MakefileInreplace)
    s1.remove_var! "FLAG"
    assert_equal "OTHER=def\nFLAG2 = def", s1
  end

  def test_remove_vars
    # Replace flag
    s1="OTHER=def\nFLAG = abc\nFLAG2 = def\nOTHER2=def"
    s1.extend(MakefileInreplace)
    s1.remove_var! ["FLAG", "FLAG2"]
    assert_equal "OTHER=def\nOTHER2=def", s1
  end
end
