require 'updater'

module Homebrew extend self
  def update
    UpdateBrew.new
    UpdateFormulary.new
  end
end
