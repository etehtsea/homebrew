require 'formulary'

module Homebrew extend self
  def formulary
    case ARGV.first
    when 'list'
      oh1 'Formularies'
      puts_columns(Formulary.list)
    when 'add'
      Formulary.add(ARGV.last)
    when 'remove'
      Formulary.remove(ARGV.last)
    end
  end
end
