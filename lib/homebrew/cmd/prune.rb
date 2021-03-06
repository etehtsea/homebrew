require 'homebrew/keg'

module Homebrew
  module Cmd
    # $n and $d are used by the ObserverPathnameExtension to keep track of
    # certain filesystem actions.

    def self.prune
      $n = 0
      $d = 0
      dirs = []

      %w[bin sbin etc lib include share Library/LinkedKegs].map{ |d| Homebrew.prefix+d }.each do |path|
        path.find do |path|
          path.extend ObserverPathnameExtension
          if path.symlink?
            unless path.resolved_path_exists?
              if ENV['HOMEBREW_KEEP_INFO'] and path.to_s =~ Keg::INFOFILE_RX
                path.uninstall_info
              end
              path.unlink
            end
          elsif path.directory?
            dirs << path
          end
        end
      end

      dirs.sort.reverse_each{ |d| d.rmdir_if_possible }

      if $n == 0 and $d == 0
        puts "Nothing pruned" if ARGV.verbose?
      else
        print "Pruned #{$n} symbolic links "
        print "and #{$d} directories " if $d > 0
        puts  "from #{Homebrew.prefix}"
      end
    end
  end
end
