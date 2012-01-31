module Homebrew extend self
  def log
    cd Homebrew.repository
    if ARGV.named.empty?
      exec "git", "log", *ARGV.options_only
    else
      exec "git", "log", *ARGV.options_only + ARGV.formulae.map(&:path)
    end
  end
end
