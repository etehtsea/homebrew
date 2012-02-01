## Compatibility layer introduced in 0.8 (refactor)

# maybe never used by anyone, but alas it must continue to exist
def versions_of(keg_name)
  `/bin/ls #{Homebrew.cellar}/#{keg_name}`.collect { |version| version.strip }.reverse
end

def dump_config
  require 'cmd/--config'
  Homebrew.__config
end

def dump_build_env env
  require 'cmd/--env'
  Homebrew.dump_build_env env
end

def default_cc
  MacOS.default_cc
end

def gcc_42_build
  MacOS.gcc_42_build_version
end

alias :gcc_build :gcc_42_build

def gcc_40_build
  MacOS.gcc_40_build_version
end

def llvm_build
  MacOS.llvm_build_version
end

def x11_installed?
  MacOS.x11_installed?
end

def macports_or_fink_installed?
  MacOS.macports_or_fink_installed?
end

def outdated_brews
  require 'cmd/outdated'
  Homebrew.outdated_brews
end

def search_brews text
  require 'cmd/search'
  Homebrew.search_brews text
end

def snow_leopard_64?
  MacOS.prefer_64_bit?
end

class Formula
  # in compatability because the naming is somewhat confusing
  def self.resolve_alias name
    opoo 'Formula.resolve_alias is deprecated and will eventually be removed'

    # Don't resolve paths or URLs
    return name if name.include?("/")

    aka = Homebrew.repository + "Library/Aliases" + name
    if aka.file?
      aka.realpath.basename('.rb').to_s
    else
      name
    end
  end

  # This used to be called in "def install", but should now be used
  # up in the DSL section.
  def fails_with_llvm msg=nil, data=nil
    handle_llvm_failure FailsWithLLVM.new(msg, data)
  end
end

class UnidentifiedFormula < Formula; end

module Deprecation
  def deprecate(old_method, new_method)
    define_method(old_method) do |*args, &block|
      warn "Warning: #{old_method}() is deprecated. Use #{new_method}()."
      send(new_method, *args, &block)
    end
  end
end

def Object.const_missing(name)
  deprecations = {
    :HOMEBREW_VERSION       => 'Homebrew.version',
    :HOMEBREW_WWW           => 'Homebrew.www',
    :HOMEBREW_CACHE         => 'Homebrew.cache',
    :HOMEBREW_CACHE_FORMULA => 'Homebrew.cache_formula',
    :HOMEBREW_CACHE_BOTTLES => 'Homebrew.cache_bottles',
    :HOMEBREW_BREW_FILE     => 'Homebrew.brew_file',
    :HOMEBREW_PREFIX        => 'Homebrew.prefix',
    :HOMEBREW_CELLAR        => 'Homebrew.cellar',
    :HOMEBREW_USER_AGENT    => 'Homebrew.user_agent',
    :HOMEBREW_CURL_ARGS     => 'Homebrew.curl_args',
    :HOMEBREW_LIBRARY_PATH  => 'Homebrew.library_path',
    :HOMEBREW_REPOSITORY    => 'Homebrew.repository',
    :FORMULARY_REPOSITORY   => 'Homebrew.formulary',
    :RECOMMENDED_LLVM       => 'Homebrew.recommended_llvm',
    :RECOMMENDED_GCC_40     => 'Homebrew.recommended_gcc_40',
    :RECOMMENDED_GCC_42     => 'Homebrew.recommended_gcc_42',
    :FORMULA_META_FILES     => 'Homebrew.formula_meta_files',
    :ISSUES_URL             => 'Homebrew.issues_url',
    :MACOS_FULL_VERSION     => 'MacOS.full_version',
    :MACOS_VERSION          => 'MacOS.version'
  }

  if deprecations[name]
    warn("#{name} is deprecated. Please use #{deprecations[name]}")
    eval(deprecations[name])
  else
    super
  end
end
