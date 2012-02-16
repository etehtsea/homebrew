require 'formula'

# Downloads the tarballs for the given formulae to the Cache
module Homebrew extend self
  def fetch
    raise FormulaUnspecifiedError if ARGV.named.empty?
    Fetcher.new(ARGV).process
  end
end

class Fetcher
  def initialize(argv)
    @argv = argv
  end

  def process
    puts "Fetching: #{bucket * ', '}" if bucket.size > 1

    bucket.each do |f|
      force(f) if @argv.include? "--force" or @argv.include? "-f"
      tarball, _ = f.fetch
      next unless tarball.kind_of? Pathname

      Pathname::Checksum::TYPES.each do |type|
        puts "#{type.to_s.upcase}: #{tarball.send(type)}"
      end

      formula_checksum = f.instance_variable_get("@#{f.checksum_type}").downcase
      tarball_checksum = tarball.send(f.checksum_type)

      unless formula_checksum == tarball_checksum
        opoo "Formula reports different #{f.checksum_type}: #{tarball_checksum}"
      end
    end
  end

  private
  def bucket
    @bucket ||= if @argv.include? '--deps'
      [@argv.formulae, @argv.formulae.map(&:recursive_deps)].flatten.uniq
    else
      @argv.formulae
    end
  end

  def force(f)
    where_to = f.cached_download
    FileUtils.rm_rf where_to if File.exist? where_to
  end
end
