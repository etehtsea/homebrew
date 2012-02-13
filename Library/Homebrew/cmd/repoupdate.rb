require 'updater'

module Homebrew extend self
  def repoupdate
    UpdateFormulary.new
  end
end
