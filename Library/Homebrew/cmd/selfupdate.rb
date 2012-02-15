require 'updater'

module Homebrew extend self
  def selfupdate
    oh1 "Core"
    Updater.new do |u|
      u.title      = 'Homebrew'
      u.repo_url   = 'https://github.com/etehtsea/homebrew.git'
      u.repo_dir   = Homebrew.repository
      u.track_dir  = 'Library/Homebrew/cmd'
    end
  end
end
