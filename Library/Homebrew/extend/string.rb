class String
  module Undent
    def undent
      gsub(/^.{#{slice(/^ +/).length}}/, '')
    end
  end

  include Undent

  unless method_defined?(:start_with?)
    def start_with? prefix
      return false unless prefix.is_a?(String)
      self[0, prefix.length] == prefix
    end
  end
end
