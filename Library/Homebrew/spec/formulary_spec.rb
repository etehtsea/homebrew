require 'spec_helper'
require 'formulary'

describe Formulary do
  before(:all) { `rm -rf /tmp/formulary` }

  before do
    Homebrew.stub(:prefix => Pathname('/tmp'))
  end

  it ".path" do
    Formulary.path.should eq(Pathname('/tmp/formulary'))
  end

  it ".exists?" do
    Formulary.exists?.should be_false
  end

  context ".create" do
    it "should create formulary if not exists" do
      Formulary.create.should eq(['/tmp/formulary'])
    end

    it "should warn if formulary path exists" do
      Formulary.create.should be_nil
    end
  end

  context ".init" do
    it "should pull main formulary" do
      Formulary.init.should be_true
    end
  end

  context ".list" do
    it 'returns repo list' do
      Formulary.list.should eq(['formulary'])
    end
  end

  context ".add" do
    it "should add repo" do
      Formulary.add('josegonzalez/homebrew-php').should be_true
    end

    it "should do nothing if repo is already added" do
      Formulary.add('josegonzalez/homebrew-php').should be_nil
    end
  end

  context ".remove" do
    it "should remove repo" do
      Formulary.remove('josegonzales/homebrew-php').should be_true
    end

    it "should do nothing if repo not found" do
      Formulary.remove('josegonzales/homebrew-php').should be_nil
    end
  end
end
