module Homebrew
  module Cmd
    def self.__cache
      if ARGV.named.empty?
        puts Homebrew.cache
      else
        puts ARGV.formulae.map{ |f| f.cached_download }
      end
    end
  end
end
