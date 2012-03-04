require 'extend/pathname'
require 'extend/ARGV'
require 'extend/string'
require 'extend/unix_utils'
require 'deprecation'
require 'git'
require 'utils'
require 'exceptions'
require 'fileutils'
require 'macos'
require 'homebrew'
require 'github'

include Utils

ARGV.extend(HomebrewArgvExtension)
