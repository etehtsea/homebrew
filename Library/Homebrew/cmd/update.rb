require 'updater'
require 'cmd/selfupdate'
require 'cmd/repoupdate'

module Homebrew
  module Cmd
    def self.update
      selfupdate
      repoupdate
    end
  end
end
