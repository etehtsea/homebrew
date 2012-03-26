require 'formula'
require 'tab'
require 'keg'

module Homebrew
  module Cmd
    class << self
      def info
        if ARGV.named.empty?
          if ARGV.include? "--all"
            Formula.each do |f|
              info_formula f
              puts '---'
            end
          else
            puts "#{Homebrew.cellar.children.length} kegs, #{Homebrew.cellar.abv}"
          end
        elsif valid_url ARGV[0]
          info_formula Formula.factory(ARGV.shift)
        else
          ARGV.formulae.each{ |f| info_formula f }
        end
      end

      def info_formula f
        exec 'open', github_info(f.name) if ARGV.flag? '--github'

        puts "#{f.name} #{f.version}"
        puts f.homepage

        if f.keg_only?
          puts
          puts "This formula is keg-only."
          puts f.keg_only?
          puts
        end

        puts "Depends on: #{f.deps*', '}" unless f.deps.empty?

        if f.rack.directory?
          kegs = f.rack.children
          kegs.each do |keg|
            next if keg.basename.to_s == '.DS_Store'
            print "#{keg} (#{keg.abv})"
            print " *" if Keg.new(keg).linked? and kegs.length > 1
            puts
            tab = Tab.for_keg keg
            unless tab.used_options.empty?
              puts "  Installed with: #{tab.used_options*', '}"
            end
          end
        else
          puts "Not installed"
        end

        the_caveats = (f.caveats || "").strip
        unless the_caveats.empty?
          puts
          puts f.caveats
          puts
        end

        history = github_info f.name
        puts history if history

      rescue FormulaUnavailableError
        # check for DIY installation
        d = Homebrew.prefix + name
        if d.directory?
          ohai "DIY Installation"
          d.children.each{ |keg| puts "#{keg} (#{keg.abv})" }
        else
          raise "No such formula or keg"
        end
      end

      def valid_url u
        u[0..6] == 'http://' or u[0..7] == 'https://' or u[0..5] == 'ftp://'
      end

    private

      def github_info name
        formula_name = Formula.path(name).basename
        user = 'mxcl'
        branch = 'master'

        if Git.installed?
          gh_user= Git::Config.get('github.user')
          /^\*\s*(.*)/.match(Git::Repo.new(Homebrew.repository).branch)
          unless $1.nil? || $1.empty? || $1.chomp == 'master' || gh_user.empty?
            branch = $1.chomp
            user = gh_user
          end
        end

        "http://github.com/#{user}/homebrew/commits/#{branch}/Library/Formula/#{formula_name}"
      end
    end
  end
end
