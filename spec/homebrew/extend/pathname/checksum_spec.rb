require 'spec_helper'
require 'homebrew/extend/pathname'

describe Pathname do
  context 'Checksum' do
   let(:testball) do
     Pathname(File.expand_path('../../../../support/tarballs/testball-0.1.tbz', __FILE__))
   end

   it('#md5')    { testball.md5.should eq('060844753f2a3b36ecfc3192d307dab2') }
   it('#sha1')   { testball.sha1.should eq('482e737739d946b7c8cbaf127d9ee9c148b999f5') }
   it('#sha256') { testball.sha256.should eq('1dfb13ce0f6143fe675b525fc9e168adb2215c5d5965c9f57306bb993170914f') }

   it 'could be spotted in ancestors' do
     Pathname.ancestors.should include(Pathname::Checksum)
   end
  end
end
