require 'extend/ENV'
require 'utils/hardware'
require 'keg'

ENV.extend(Homebrew::Env)
ENV.setup_build_environment

module Homebrew
  module Cmd
    def self.test
      raise KegUnspecifiedError if ARGV.named.empty?

      ARGV.formulae.each do |f|
        # Cannot test uninstalled formulae
        unless f.installed?
          puts "#{f.name} not installed"
          next
        end

        # Cannot test formulae without a test method
        unless f.respond_to? :test
          puts "#{f.name} defines no test"
          next
        end

        puts "Testing #{f.name}"
        begin
          # tests can also return false to indicate failure
          puts "#{f.name}: failed" if f.test == false
        rescue
          puts "#{f.name}: failed"
        end
      end
    end
  end
end
