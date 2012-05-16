require 'homebrew/utils/git'

module Homebrew
  module Cmd
    def self.log
      if ARGV.named.empty?
        repo, opts = Homebrew.repository, ARGV.options_only
      else
        repo = Homebrew.formulary
        opts = ARGV.options_only + ARGV.formulae.map(&:path)
      end

      Git::Repo.new(repo).log(opts)
    end
  end
end
