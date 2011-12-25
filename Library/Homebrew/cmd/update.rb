require 'updater'

module Homebrew extend self
  def update
    UpdateFormulary.new
  end
end
