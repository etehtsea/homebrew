require 'updater'
require 'cmd/selfupdate'
require 'cmd/repoupdate'

module Homebrew extend self
  def update
    selfupdate
    repoupdate
  end
end
