require 'updater'

module Homebrew extend self
  def repoupdate
    Updater.new do |u|
      u.title      = 'Formulary'
      u.repo_url   = 'https://github.com/etehtsea/formulary.git'
      u.repo_dir   = Homebrew.formulary
      u.track_dir  = 'Formula/'
    end
  end
end
