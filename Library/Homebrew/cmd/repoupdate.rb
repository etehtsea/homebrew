require 'formulary'

module Homebrew extend self
  def repoupdate
    Formulary.list.each do |f|
      path = Formulary.path + f
      repo_url = Git::Repo.new(path).config('remote.origin.url')
      repo = repo_url.split('/').last(2).join('/').gsub(/\.git$/, '')
      Updater.new(repo)
    end
  end
end
