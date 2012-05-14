# This software is in the public domain, furnished "as is", without technical
# support, and with no warranty, express or implied, as to its usefulness for
# any purpose.

# Require this file to build a testing environment.

ABS__FILE__=File.expand_path(__FILE__)

lib = File.expand_path('../../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
$:.push File.expand_path('../', __FILE__)
require 'homebrew'

# these are defined in homebrew.rb, but we don't want to break our actual
# homebrew tree, and we do want to test everything :)
module Homebrew
  class << self
    def prefix; Pathname.new '/private/tmp/testbrew/prefix'; end
    def repository; Homebrew.prefix; end
    def cache; Homebrew.prefix.parent+"cache"; end
    def cache_formila; Homebrew.prefix.parent+"formula_cache"; end
    def cellar; Homebrew.prefix.parent+"cellar"; end
    def user_agent; "Homebrew"; end
    def www; 'http://example.com'; end
    def curl_args; '-fsLA'; end
  end
end

module MacOS
  def self.version; 10.6; end
end

(Homebrew.formulary + 'main/Formula').mkpath
Dir.chdir Homebrew.prefix
at_exit { Homebrew.prefix.parent.rmtree }

# Test fixtures and files can be found relative to this path
TEST_FOLDER = Pathname.new(ABS__FILE__).parent.realpath

require 'fileutils'
module Homebrew extend self
  include FileUtils
end

require 'test/unit' # must be after at_exit
