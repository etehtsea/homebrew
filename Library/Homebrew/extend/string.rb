class String
  module Undent
    def undent
      gsub(/^.{#{slice(/^ +/).length}}/, '')
    end
  end

  include Undent

  unless method_defined?(:start_with?)
    def start_with? prefix
      prefix = prefix.to_s
      self[0, prefix.length] == prefix
    end
  end
end
