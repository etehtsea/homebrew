module Homebrew
  module Utils
    module MakefileInreplace
      extend ::Deprecation

      # Warn if nothing was replaced
      def gsub! before, after, audit_result=true
        sub = super(before, after)
        if audit_result and sub.nil?
          opoo "inreplace: replacement of '#{before}' with '#{after}' failed"
        end

        sub
      end

      # Looks for Makefile style variable defintions and replaces the
      # value with "new_value", or removes the definition entirely.
      def change_var!(flag, new_value)
        new_value = "#{flag}=#{new_value}"
        sub = gsub! Regexp.new("^#{flag}[ \\t]*=[ \\t]*(.*)$"), new_value, false
        opoo "inreplace: changing '#{flag}' to '#{new_value}' failed" if sub.nil?
      end

      # Removes variable assignments completely.
      def remove_var!(flags)
        Array(flags).each do |flag|
          # Also remove trailing \n, if present.
          sub = gsub! Regexp.new("^#{flag}[ \\t]*=(.*)$\n?"), "", false
          opoo "inreplace: removing '#{flag}' failed" if sub.nil?
        end
      end

      # Finds the specified variable
      def get_var(flag)
        m = match Regexp.new("^#{flag}[ \\t]*=[ \\t]*(.*)$")

        m ? m[1] : nil
      end

      deprecate :change_make_var!, :change_var!
      deprecate :remove_make_var!, :remove_var!
      deprecate :get_make_var!, :get_var!
    end
  end
end
