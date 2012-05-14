require 'spec_helper'

describe Hardware do
  its(:processor_count) { should == Hardware.send(:sysctl_value, 'hw.ncpu') }

  context :cpu_type do
    subject { Hardware.cpu_type }

    it { should be_a Symbol }

    it "should be known" do
      Hardware::CPU_TYPES.values.should include subject
    end

    it "should be dunno if unknown" do
      Hardware.clone.tap do |o|
        o.instance_eval do
          @cpu_type = nil
          def sysctl_value(variable); 0; end
        end
      end.cpu_type.should == :dunno
    end
  end

  context :intel_family do
    subject { Hardware.intel_family }

    it { should be_a Symbol }

    it "should be known" do
      Hardware::INTEL_FAMILIES.values.should include subject
    end

    it "should be dunno if unknown" do
      Hardware.clone.tap do |o|
        o.instance_eval do
          @intel_family = nil
          def sysctl_value(variable); 0; end
        end
      end.intel_family.should == :dunno
    end
  end if Hardware.cpu_type == :intel

  context :cores_as_words do
    subject { Hardware.cores_as_words }

    it { should be_a String }

    { 1 => 'single', 2 => 'dual', 4 => 'quad', 6 => '6' }.each do |k, v|
      specify do
        Hardware.clone.tap do |o|
          o.instance_eval do
            @cores_as_words = nil
            eval("def processor_count; #{k}; end")
          end
        end.cores_as_words.should == v
      end
    end
  end
end
