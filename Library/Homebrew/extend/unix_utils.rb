require 'vendor/unix_utils'
require 'pathname'

module UnixUtils
  def self.which(infile)
    argv = ['which', infile]
    stdout = spawn argv
    Pathname(stdout.strip) unless stdout.empty?
  end
end
