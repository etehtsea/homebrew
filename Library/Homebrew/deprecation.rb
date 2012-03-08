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
    :HOMEBREW_LOGS          => 'Homebrew.logs',
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
    warn("#{name} is deprecated. Please use #{deprecations[name]} instead")
    eval(deprecations[name])
  else
    super
  end
end
