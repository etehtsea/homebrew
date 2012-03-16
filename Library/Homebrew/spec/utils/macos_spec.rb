require 'spec_helper'
require 'homebrew'
require 'extend/ARGV'
ARGV.extend(HomebrewArgvExtension)

describe MacOS do
  its(:full_version) { should match(/^10\.[5-9]\.\d{1,2}$/) }
  its(:version) do
    should eq(`/usr/bin/sw_vers -productVersion`.chomp.match(/10\../)[0].to_f)
  end

  { :gcc_40_build_version => ['gcc-4.0', 5300],
    :gcc_42_build_version => ['gcc-4.2', 5500],
    :llvm_build_version   => ['llvm-gcc',5500],
    :clang_build_version  => ['clang',     60]
  }.each do |method, value|
    binary, build_version = value

    it "should set proper #{method}" do
      if system("which -s #{binary}")
        MacOS.send(method).should satisfy { |v| v > build_version }
      else
        MacOS.send(method).should be_nil
      end
    end
  end

  if system("which -s xcode-select")
    its(:xcode_prefix) { should be_a Pathname }
    its(:xcode_prefix) { should_not eq(Pathname('/')) }
    its(:xcode_installed?) { should_not be_nil }
    its(:xcode_version) { should match(/(\d\.\d\.\d)|($unknown^)/) }
    its(:x11_installed?) { should_not be_nil }
    its(:macports_or_fink_installed?) { should_not be_nil }
  end

  [:leopard?, :snow_leopard?, :lion?, :mountain_lion?,
   :prefer_64_bit?].each do |method|
    its(method) { should_not be_nil }
  end
end
