module Homebrew extend self
  def __cache
    if ARGV.named.empty?
      puts Homebrew.cache
    else
      puts ARGV.formulae.map{ |f| f.cached_download }
    end
  end
end
