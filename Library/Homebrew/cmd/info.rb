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

        history = github_info f.name
        puts history if history

        the_caveats = (f.caveats || "").strip
        unless the_caveats.empty?
          puts
          ohai "Caveats"
          puts f.caveats
        end

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

      def github_info(name)
        path = Formula.path(name).realpath

        repo = Git::Repo.new(path.dirname)
        url = repo.config('remote.origin.url').gsub(/.git$/, '')
        repo_name = url.split('/').last
        rel_path = path.to_s.gsub(/#{Homebrew.formulary}\/#{repo_name}\//, '')
        branch = repo.branch.gsub(/^\* /, '')

        "#{url}/commits/#{branch}/#{rel_path}"
      end
    end
  end
end
