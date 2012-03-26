module Homebrew
  module Cmd
    def self.__cellar
      if ARGV.named.empty?
        puts Homebrew.cellar
      else
        puts ARGV.formulae.map{ |f| Homebrew.cellar + f.name }
      end
    end
  end
end
