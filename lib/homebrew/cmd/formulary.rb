require 'homebrew/formulary'

module Homebrew
  module Cmd
    def self.formulary
      case ARGV.first
      when 'list'
        oh1 'Formularies'
        puts_columns(Formulary.list)
      when 'add'
        Formulary.add(ARGV.last)
      when 'remove'
        Formulary.remove(ARGV.last)
      when 'init'
        Formulary.init
      end
    end
  end
end
