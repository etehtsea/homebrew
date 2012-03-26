require 'updater'

module Homebrew extend self
  def selfupdate
    Updater.new do |u|
      u.title      = 'Core'
      u.repo_url   = 'https://github.com/etehtsea/homebrew.git'
      u.repo_dir   = Homebrew.repository
      u.filter  = 'Library/Homebrew/cmd'
    end
  end
end
