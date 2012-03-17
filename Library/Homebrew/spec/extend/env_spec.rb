require 'spec_helper'
require 'extend/ENV'
ENV.extend(Homebrew::Env)

describe ENV do
  { :gcc_4_0_1 => ['gcc-4.0', 'g++-4.0'],
    :gcc_4_2   => ['gcc-4.2', 'g++-4.2'],
    :llvm      => ['llvm-gcc', 'llvm-g++'],
    :clang     => ['clang', 'clang++']
  }.each do |method, binaries|
    cc, cxx = binaries
    context "#{method} should set" do
      let(:env) do
        {}.tap do |o|
          o.extend(Homebrew::Env)
          o.send(method)
        end
      end

      ['CFLAGS', 'CXXFLAGS', 'OBJCFLAGS', 'OBJCXXFLAGS'].each do |flag|
        it(flag) { env[flag].should_not be_empty }
      end

      ['CC', 'LD'].each do |flag|
        it(flag) { env[flag].should eq(cc) }
      end

      it('CXX') { env['CXX'].should eq(cxx) }
    end
  end

  it("deparallelize") do
    ENV.deparallelize
    ENV['MAKEFLAGS'].should be_nil
  end

  { :minimal => '-Os -w -pipe',
    :no      => '-w -pipe'
  }.each do |opt, flags|
    it "#{opt} optimization" do
      ENV.send("#{opt}_optimization")
      ENV['CFLAGS'].should eq(flags)
      ENV['CXXFLAGS'].should eq(flags)
    end
  end

  it("libxml2") do
    ENV.libxml2
    ENV['CPPFLAGS'].should eq('-I/usr/include/libxml2')
  end

  if File.exists?('/usr/X11/lib/libpng.dylib')
    context "x11" do
      before(:all) { ENV.x11 }

      it 'prepend to PATH' do
        ENV['PATH'].split(':').first.should eq('/usr/X11/bin')
      end

      it 'append to CPPFLAGS' do
        ENV['CPPFLAGS'].should match(/-I\/usr\/X11\/include/)
      end

      it 'append to LDFLAGS' do
        ENV['LDFLAGS'].should match(/-L\/usr\/X11\/lib/)
      end

      it 'append to CMAKE_PREFIX_PATH' do
        ENV['CMAKE_PREFIX_PATH'].match(/\/usr\/X11:/)
      end
    end
  end

  context "optimization level" do
    let(:env) do
      { 'CFLAGS' => '-O4' }.tap { |o| o.extend(Homebrew::Env) }
    end

    [:fast, :O4, :O3, :O2, :Os, :O1].each do |opt|
      it(opt) { env.send(opt); env['CFLAGS'].should eq("-#{opt}") }
    end

    it(:Og) { env.Og; env['CFLAGS'].should eq('-g -O0') }
  end

  it "enable warnings" do
    env = {'CFLAGS' => '-w -Qunused-arguments'}.tap do |o|
      o.extend(Homebrew::Env)
    end
    env.enable_warnings

    env['CFLAGS'].should eq(' ')
  end

  it "ncurses_define" do
    ENV.ncurses_define
    ENV['CPPFLAGS'].should match(/-DNCURSES_OPAQUE=0/)
  end

  { '64' => 'x86_64',
    '32' => 'i386'
  }.each do |k, v|
    it("m#{k}") do
      ENV.send("m#{k}")
      ENV['CFLAGS'].should match(/-m#{k}/)
      ENV['LDFLAGS'].should match(/-arch #{v}/)
    end
  end

  context "respects flags set manually in the env" do
    before do
      ['CC', 'CXX', 'CFLAGS', 'MAKEJOBS', 'CXXFLAGS'].each do |flag|
        ENV.delete(flag)
      end

      ENV['CC']  = 'gcc-4.7'
      ENV['CXX'] = 'g++-4.7'
      ENV['CFLAGS'] = '-w -pipe -march=native -fomit-frame-pointer'
      ENV['MAKEJOBS'] = '-j5'

      # set default compiler
      ENV.clang
    end

    it("CC") { ENV['CC'].should eq('gcc-4.7') }
    it("CXX") { ENV['CXX'].should eq('g++-4.7') }
    it("CFLAGS") do
      ENV['CFLAGS'].should eq('-w -pipe -march=native -fomit-frame-pointer')
    end
    it("CXXFLAGS") { ENV['CXXFLAGS'].should eq(ENV['CFLAGS']) }
    it('LD') { ENV['LD'].should eq(ENV['CC']) }
    it('MAKEJOBS') { ENV['MAKEJOBS'].should eq('-j5') }
  end
end
