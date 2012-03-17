require 'spec_helper'
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
  end
end
