module Homebrew
  module Cmd
    def self.cat
      # do not "fix" this to support multiple arguments, the output would be
      # unparsable, if the user wants to cat multiple formula they can call
      # brew cat multiple times.

      raise FormulaUnspecifiedError if ARGV.named.empty?
      Dir.chdir Homebrew.repository
      exec "cat", ARGV.formulae.first.path, *ARGV.options_only
    end
  end
end
