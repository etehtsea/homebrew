require 'homebrew/updater'
require 'homebrew/cmd/selfupdate'
require 'homebrew/cmd/repoupdate'

module Homebrew
  module Cmd
    def self.update
      selfupdate
      repoupdate
    end
  end
end
