require 'vendor/unix_utils'

module UnixUtils
  def self.which(infile)
    argv = ['which', infile]
    stdout = spawn argv
    stdout.strip
  end
end
