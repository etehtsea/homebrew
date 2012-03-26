require 'doctor'

module Homebrew
  module Cmd
    def self.doctor
      raring_to_brew = true

      Doctor::Check.methods(false).sort.each do |method|
        out = Doctor::Check.send(method)
        unless out.nil? or out.empty?
          puts unless raring_to_brew
          lines = out.to_s.split('\n')
          opoo lines.shift
          puts lines
          raring_to_brew = false
        end
      end

      puts "Your system is raring to brew." if raring_to_brew
      exit raring_to_brew ? 0 : 1
    end
  end
end
