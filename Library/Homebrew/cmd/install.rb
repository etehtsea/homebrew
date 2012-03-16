require 'formula_installer'
require 'blacklist'
require 'doctor'

module Homebrew extend self
  def install
    raise FormulaUnspecifiedError if ARGV.named.empty?

    ARGV.named.each do |name|
      msg = blacklisted? name
      raise "No available formula for #{name}\n#{msg}" if msg
    end unless ARGV.force?

    if Process.uid.zero? and not File.stat(Homebrew.brew_file).uid.zero?
      # note we only abort if Homebrew is *not* installed as sudo and the user
      # calls brew as root. The fix is to chown brew to root.
      abort "Cowardly refusing to `sudo brew install'"
    end

    install_formulae ARGV.formulae
  end

  def perform_preinstall_checks
    [:ppc, :writable_install_location, :cellar_exists].each do |t|
      check(t, true)
    end

    [:xcode_exists, :latest_xcode, :other_package_managers].each do |t|
      check(t)
    end
  end

  def install_formulae formulae
    formulae = [formulae].flatten.compact
    unless formulae.empty?
      perform_preinstall_checks
      formulae.each do |f|
        begin
          fi = FormulaInstaller.new(f)
          fi.install
          fi.caveats
          fi.finish
        rescue CannotInstallFormulaError => e
          onoe e.message
        end
      end
    end
  end

private
  def check(task, critical = false)
    result = Doctor.send(task)
    unless result.nil? or result.empty?
      if critical
        raise result
      else
        puts result
      end
    end
  end
end
