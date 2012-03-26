module Homebrew
  module Cmd
    def self.__prefix
      if ARGV.named.empty?
        puts Homebrew.prefix
      else
        puts ARGV.formulae.map{ |f| f.installed_prefix }
      end
    end
  end
end
