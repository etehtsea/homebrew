require 'homebrew/cmd/outdated'
require 'homebrew/cmd/install'
require 'homebrew/doctor'

class Fixnum
  def plural_s
    if self > 1 then "s" else "" end
  end
end

module Homebrew
  module Cmd
    class << self
      def upgrade
        Doctor.preinstall_checks

        outdated = if ARGV.named.empty?
          outdated_brews
        else
          ARGV.formulae.select do |f|
            unless f.rack.exist? and not f.rack.children.empty?
              onoe "#{f} not installed"
            else
              true
            end
          end
        end

        # Expand the outdated list to include outdated dependencies then sort and
        # reduce such that dependencies are installed first and installation is not
        # attempted twice. Sorting is implicit the way `recursive_deps` returns
        # root dependencies at the head of the list and `uniq` keeps the first
        # element it encounters and discards the rest.
        outdated.map!{ |f| f.recursive_deps.reject{ |d| d.installed?} << f }
        outdated.flatten!
        outdated.uniq!

        if outdated.length > 1
          oh1 "Upgrading #{outdated.length} outdated package#{outdated.length.plural_s}, with result:"
          puts outdated.map{ |f| "#{f.name} #{f.version}" } * ", "
        end

        outdated.each do |f|
          upgrade_formula f
        end
      end

    private

      def upgrade_formula f
        outdated_keg = Keg.new(f.linked_keg.realpath) rescue nil

        installer = FormulaInstaller.new f
        installer.show_header = false

        oh1 "Upgrading #{f.name}"

        # first we unlink the currently active keg for this formula otherwise it is
        # possible for the existing build to interfere with the build we are about to
        # do! Seriously, it happens!
        outdated_keg.unlink if outdated_keg

        installer.install
        installer.caveats
        installer.finish
      rescue CannotInstallFormulaError => e
        onoe e
      rescue BuildError => e
        e.dump
        puts
      ensure
        # restore previous installation state if build failed
        outdated_keg.link if outdated_keg and not f.installed? rescue nil
      end
    end
  end
end
