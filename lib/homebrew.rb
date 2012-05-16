require 'homebrew/deprecation'
require 'homebrew/extend/pathname'
require 'homebrew/bottles'
require 'homebrew/extend/ARGV'
require 'homebrew/extend/string'
require 'homebrew/utils'
require 'homebrew/exceptions'
require 'fileutils'
require 'yaml'

include Utils

ARGV.extend(HomebrewArgvExtension)

module Homebrew
  class << self
    def version
      '0.9.0'
    end

    def www
      'http://mxcl.github.com/homebrew/'
    end

    # Public: Download cache directory
    #
    # Returns cache directory as a Pathname
    def cache
      @@cache ||= if ENV['HOMEBREW_CACHE']
                    Pathname(ENV['HOMEBREW_CACHE'])
                  else
                    home_library = Pathname("/Library/Caches/Homebrew")
                    if Process.uid == 0 || !home_library.writable?
                      home_library
                    else
                      Pathname("~/Library/Caches/Homebrew").expand_path
                    end
                  end
    end

    # Public: Where brews installed via URL are cached
    #
    # Returns formulas cache directory as a Pathname
    def cache_formula
      @@cache_formula ||= cache + "Formula"
    end

    # Public: Where bottles are cached
    #
    # Returns bottles cache directory as a Pathname
    def cache_bottles
      @@cache_bottles ||= cache + "Bottles"
    end

    # Public: Where brew binary is located
    #
    # Returns Pathname to brew binary
    def brew_file
      @@brew_file ||= ENV['HOMEBREW_BREW_FILE'] || Unix.which('brew')
    end

    # Public: Where we link under
    #
    # Returns Pathname
    def prefix
      @@prefix ||= Pathname('/usr/local/')
    end

    # Public: Where .git is found
    #
    # Returns Pathname
    def repository
      @@repository ||= Pathname(brew_file).realpath.dirname.parent
    end

    # Public: Where formularies is found
    #
    # Returns Pathname
    def formulary
      @@formulary ||= prefix + 'formulary'
    end

    # Public: Where we store built products; /usr/local/Cellar if it exists,
    # otherwise a Cellar relative to the Repository.
    #
    # Returns Pathname
    def cellar
      @@cellar ||= ((prefix + "Cellar").exist? ? prefix : repository) + "Cellar"
    end

    # Public: Where logs are found
    #
    # Returns Pathname
    def logs
      @@logs ||= Pathname('~/Library/Logs/Homebrew/').expand_path
    end

    def recommended_llvm
      2326
    end

    def recommended_gcc_40
      @@recommended_gcc_40 ||= (MacOS.version >= 10.6) ? 5494 : 5493
    end

    def recommended_gcc_42
      @@recommended_gcc_42 ||= (MacOS.version >= 10.6) ? 5664 : 5577
    end

    def formula_meta_files
      %w[README README.md ChangeLog CHANGES COPYING LICENSE LICENCE COPYRIGHT AUTHORS]
    end

    def issues_url
      "https://github.com/mxcl/homebrew/wiki/checklist-before-filing-a-new-issue"
    end
  end
end

module Homebrew extend self
  include FileUtils
end
