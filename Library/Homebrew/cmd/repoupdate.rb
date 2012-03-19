require 'updater'

module Homebrew extend self
  def repoupdate
    formularies_path.mkdir unless formularies_path.directory?

    formularies.each do |name, settings|
      Updater.new do |u|
        u.title      = "#{name.capitalize} formulary"
        u.repo_url   = settings['url']
        u.repo_dir   = Homebrew.formularies_path + name
        u.track_dir  = settings['track_dir']
      end
    end
  end
end
