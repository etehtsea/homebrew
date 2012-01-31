module Homebrew extend self
  def __cellar
    if ARGV.named.empty?
      puts Homebrew.cellar
    else
      puts ARGV.formulae.map{ |f| Homebrew.cellar + f.name }
    end
  end
end
