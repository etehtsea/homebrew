module Homebrew extend self
  def home
    if ARGV.named.empty?
      exec "open", Homebrew.www
    else
      exec "open", *ARGV.formulae.map{ |f| f.homepage }
    end
  end
end
