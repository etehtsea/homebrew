require 'utils/git'

module Homebrew extend self
  def log
    if ARGV.named.empty?
      repo, opts = Homebrew.repository, ARGV.options_only
    else
      repo = Homebrew.formulary
      opts = ARGV.options_only + ARGV.formulae.map(&:path)
    end

    Git::Repo.new(repo).log(opts)
  end
end
