require 'spec_helper'
# just to check own String#start_with?
# because it was introduces in RUBY >= 1.8.7
class StdString < String; end
class String; undef_method(:start_with?); end
require 'extend/string'

describe String do
  context "Undent" do
    it "#undent strips dots and spaces in here-docs" do
      undented = <<-EOS.undent
      hi
......my friend over
      there
      EOS
      undented.should eq("hi\nmy friend over\nthere\n")
    end

    it "could be spotted in ancestors" do
      String.ancestors.should include(String::Undent)
    end
  end

  context "#start_with?" do
    it 'should be defined' do
      String.method_defined?(:start_with?).should be_true
    end

    context "should work as std one for" do
      it 'strings' do
        test_result = 'my friend over'.start_with?('my friend')
        std_result  = StdString.new('my friend over').start_with?('my friend')
        test_result.should eq std_result
      end

      it 'not strings' do
        '4'.start_with?(4).should eq StdString.new('4').start_with?(4)
      end
    end
  end
end
