require 'homebrew/formula'

module Homebrew
  module Cmd
    class << self
      def outdated
        outdated_brews.each do |f|
          if $stdout.tty? and not ARGV.flag? '--quiet'
            versions = f.rack.cd{ Dir['*'] }.join(', ')
            puts "#{f.name.ljust(15)} (#{Color.red versions} -> #{Color.green f.version})"
          else
            puts f.name
          end
        end
      end

    private

      def outdated_brews
        Homebrew.cellar.subdirs.map do |rack|
          # Skip kegs with no versions installed
          next unless rack.subdirs

          # Skip HEAD formulae, consider them "evergreen"
          next if rack.subdirs.map{ |keg| keg.basename.to_s }.include? "HEAD"

          name = rack.basename.to_s
          f = Formula.factory name rescue nil
          f if f and not f.installed?
        end.compact
      end
    end
  end
end
