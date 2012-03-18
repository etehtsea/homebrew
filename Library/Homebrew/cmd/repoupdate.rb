require 'updater'

module Homebrew extend self
  def repoupdate
    formularies.each do |name, settings|
      Updater.new do |u|
        u.title      = name
        u.repo_url   = settings['url']
        u.repo_dir   = Homebrew.formularies_path + settings['path']
        u.track_dir  = settings['track_dir']
      end
    end
  end
end
