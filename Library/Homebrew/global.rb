require 'extend/pathname'
require 'extend/ARGV'
require 'extend/string'
require 'deprecation'
require 'utils'
require 'exceptions'
require 'fileutils'
require 'macos'
require 'homebrew'
require 'github'

include Utils

ARGV.extend(HomebrewArgvExtension)
