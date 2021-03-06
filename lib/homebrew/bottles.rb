require 'homebrew/tab'
require 'homebrew/extend/ARGV'

def bottle_filename f
  "#{f.name}-#{f.version}#{bottle_native_suffix}"
end

def bottles_supported?
  Homebrew.prefix.to_s == '/usr/local' and Homebrew.cellar.to_s == '/usr/local/Cellar'
end

def install_bottle? f
  !ARGV.build_from_source? && bottle_current?(f) && bottle_native?(f)
end

def bottle_native? f
  return true if bottle_native_regex.match(f.bottle_url)
  # old brew bottle style
  return true if Homebrew::MacOS.lion? && old_bottle_regex.match(f.bottle_url)
  return false
end

def built_bottle? f
  Homebrew::Tab.for_formula(f).built_bottle
end

def bottle_current? f
  !f.bottle_url.nil? && Pathname.new(f.bottle_url).version == f.version
end

def bottle_native_suffix
  ".#{Homebrew::MacOS.cat}#{bottle_suffix}"
end

def bottle_suffix
  ".bottle.tar.gz"
end

def bottle_native_regex
  /(\.#{Homebrew::MacOS.cat}\.bottle\.tar\.gz)$/
end

def bottle_regex
  /(\.[a-z]+\.bottle\.tar\.gz)$/
end

def old_bottle_regex
  /(-bottle\.tar\.gz)$/
end
