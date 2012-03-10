require 'pathname'
require 'exceptions'

module Utils; end
require 'utils/architecture_list'
require 'utils/makefile_inreplace'
require 'utils/output'
require 'utils/tty'
require 'utils/unix'
require 'utils/git'
require 'utils/github'
require 'utils/hardware'
require 'utils/macos'

module Utils
  include Output
  include Unix

  def which_editor
    editor = ENV['HOMEBREW_EDITOR'] || ENV['EDITOR']
    # If an editor wasn't set, try to pick a sane default
    return editor unless editor.nil?

    # Find Textmate
    return 'mate' if Unix.available?('mate')
    # Find # BBEdit / TextWrangler
    return 'edit' if Unix.available?('edit')
    # Default to vim
    return '/usr/bin/vim'
  end

  def inreplace path, before=nil, after=nil
    [*path].each do |path|
      f = File.open(path, 'r')
      s = f.read

      if before == nil and after == nil
        s.extend(MakefileInreplace)
        yield s
      else
        sub = s.gsub!(before, after)
        if sub.nil?
          opoo "inreplace in '#{path}' failed"
          puts "Expected replacement of '#{before}' with '#{after}'"
        end
      end

      f.reopen(path, 'w').write(s)
      f.close
    end
  end

  def ignore_interrupts
    std_trap = trap("INT") {}
    yield
  ensure
    trap("INT", std_trap)
  end

  def nostdout
    if ARGV.verbose?
      yield
    else
      begin
        require 'stringio'
        real_stdout = $stdout
        $stdout = StringIO.new
        yield
      ensure
        $stdout = real_stdout
      end
    end
  end
end
