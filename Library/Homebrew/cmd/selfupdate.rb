require 'updater'

module Homebrew extend self
  def selfupdate
    UpdateBrew.new
  end
end
