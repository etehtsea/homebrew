require 'homebrew/formula_installer'
require 'homebrew/blacklist'
require 'homebrew/doctor'

module Homebrew
  module Cmd
    class << self
      def install
        raise FormulaUnspecifiedError if ARGV.named.empty?

        ARGV.named.each do |name|
          msg = Blacklist.include? name
          raise "No available formula for #{name}\n#{msg}" if msg
        end unless ARGV.force?

        Doctor.preinstall_checks

        install_formulae ARGV.formulae
      end

    private

      def install_formulae formulae
        formulae = [formulae].flatten.compact
        unless formulae.empty?
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
    end
  end
end
