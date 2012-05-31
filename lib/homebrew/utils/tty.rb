module Homebrew
  module Utils
    module Tty
      class << self
        def blue  ; bold 34     ; end
        def white ; bold 39     ; end
        def red   ; bold 31; end
        def yellow; underline 33; end
        def reset ; escape 0    ; end
        def em    ; underline 39; end
        def green ; color 92    ; end

        def width
          `/usr/bin/tput cols`.strip.to_i
        end

        private
        def color(n);     escape "0;#{n}"; end
        def bold(n);      escape "1;#{n}"; end
        def underline(n); escape "4;#{n}"; end

        def escape(n)
          "\033[#{n}m" if $stdout.tty?
        end
      end
    end

    module Color
      class << self
        def blue(n)  ; wrap(:blue, n)  ; end
        def white(n) ; wrap(:white, n) ; end
        def red(n)   ; wrap(:red, n)   ; end
        def yellow(n); wrap(:yellow, n); end
        def reset(n) ; wrap(:reset, n) ; end
        def em(n)    ; wrap(:em, n)    ; end
        def green(n) ; wrap(:green, n) ; end

      private

        def wrap(color, n)
          "#{Tty.send(color)}#{n}#{Tty.reset}"
        end
      end
    end
  end
end
