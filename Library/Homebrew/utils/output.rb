module Utils
  module Output
    # args are additional inputs to puts until a nil arg is encountered
    def ohai title, *sput
      title = title.to_s[0, Tty.width - 4] if $stdout.tty? unless ARGV.verbose?
      puts "#{Tty.blue}==>#{Tty.white} #{title}#{Tty.reset}"
      puts sput unless sput.empty?
    end

    def oh1 title
      title = title.to_s[0, Tty.width - 4] if $stdout.tty? unless ARGV.verbose?
      puts "#{Tty.green}==> #{Tty.reset}#{title}"
    end

    def opoo warning
      puts "#{Tty.red}Warning#{Tty.reset}: #{warning}"
    end

    def onoe error
      lines = error.to_s.split'\n'
      puts "#{Tty.red}Error#{Tty.reset}: #{lines.shift}"
      puts lines unless lines.empty?
    end

    def pretty_duration s
      return "2 seconds" if s < 3 # avoids the plural problem ;)
      return "#{s.to_i} seconds" if s < 120
      return "%.1f minutes" % (s/60)
    end

    def puts_columns items
      return if items.empty?

      if $stdout.tty?
        # determine the best width to display for different console sizes
        console_width = `/bin/stty size`.chomp.split(" ").last.to_i
        console_width = 80 if console_width <= 0
        longest = items.sort_by { |item| item.length }.last
        optimal_col_width = (console_width.to_f / (longest.length + 2).to_f).floor
        cols = optimal_col_width > 1 ? optimal_col_width : 1

        IO.popen("/usr/bin/pr -#{cols} -t -w#{console_width}", "w"){ |io| io.puts(items) }
      else
        puts items
      end
    end
  end
end
