module Homebrew
  module Cmd
    def self.home
      if ARGV.named.empty?
        exec "open", Homebrew.www
      else
        exec "open", *ARGV.formulae.map{ |f| f.homepage }
      end
    end
  end
end
