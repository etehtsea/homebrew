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

    # Where brews installed via URL are cached
    def cache_formula
      @@cache_formula ||= cache + "Formula"
    end

    # Where bottles are cached
    def cache_bottles
      @@cache_bottles ||= cache + "Bottles"
    end

    def brew_file
      @@brew_file ||= ENV['HOMEBREW_BREW_FILE'] || Unix.which('brew')
    end

    # Where we link under
    def prefix
      @@prefix ||= Pathname.new(brew_file).dirname.parent
    end

    # Where .git is found
    def repository
      @@repository ||= Pathname.new(brew_file).realpath.dirname.parent
    end

    def formulary
      @@formulary ||= prefix + 'formulary'
    end

    # Where we store built products; /usr/local/Cellar if it exists,
    # otherwise a Cellar relative to the Repository.
    def cellar
      @@cellar ||= ((prefix + "Cellar").exist? ? prefix : repository) + "Cellar"
    end

    def logs
      @@logs ||= Pathname.new('~/Library/Logs/Homebrew/').expand_path
    end

    def user_agent
      @@user_agent ||= "Homebrew #{version}" \
                       "(Ruby #{RUBY_VERSION}-#{RUBY_PATCHLEVEL};" \
                       "Mac OS X #{MacOS.full_version})"
    end

    def curl_args
      '-qf#LA'
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

    def library_path=(path)
      @@library_path=path
    end

    def library_path
      @@library_path ||= nil
    end
  end
end

module Homebrew extend self
  include FileUtils
end
