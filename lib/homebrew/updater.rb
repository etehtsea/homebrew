module Homebrew
  class Updater
    attr_accessor :title, :repo_url, :repo_dir, :filter

    def initialize(name = nil)
      if name
        @repo_url = "https://github.com/#{name}.git"
        dir = name.split('/').last
        @repo_dir = Formulary.path + dir
        @title    = "#{dir.capitalize} formulary"
        @filter = /\.rb$/
      end

      if block_given?
        yield self
      end

      oh1 title
      if update!
        report
      else
        puts "Already up-to-date."
      end
    end

    private
    def report
      puts "Updated from #{@initial[0,8]} to #{@current[0,8]}."

      # get installed formulas list
      installed = Homebrew.cellar.children.
        select { |pn| pn.directory? }.
        map    { |pn| pn.basename.to_s }.sort if Homebrew.cellar.directory?

      @changes.each do |type, changes|
        unless changes.empty?
          ohai type

          if installed.any?
            changes.map! { |item| installed.include?(item) ? "#{item}*" : item }
          end

          puts_columns changes
        end
      end
    end

    # Performs an update of the homebrew source. Returns +true+ if a newer
    # version was available, +false+ if already up-to-date.
    def update!
      @repo_dir.mkdir unless @repo_dir.directory?
      repo = Git::Repo.new(@repo_dir, @repo_url)

      if repo.exists?
        repo.checkout
        @initial = repo.head
        repo.add_origin
      else
        repo.init
      end

      repo.pull
      @current = repo.head

      if @initial && @initial != @current
        # hash with status characters for keys:
        # Added (A), Deleted (D), Modified (M)
        @changes_map = Hash.new { |h, k| h[k] = [] }

        changes = repo.changes(@initial, @current)

        while status = changes.shift
          file = changes.shift
          @changes_map[status] << file
        end

        if @changes_map.any?
          @changes = { 'New'     => changed_items('A', @filter),
                       'Updated' => changed_items('M', @filter),
                       'Deleted' => changed_items('D', @filter) }
          return true
        end
      end

      # assume nothing was updated
      return false
    end

    def filter(files, regexp)
      files.select { |f| !(f.index(regexp).nil?) }
    end

    def basenames(files)
      files.map { |f| File.basename(f, '.rb') }
    end

    def changed_items(status, regexp)
      basenames(filter(@changes_map[status], regexp)).sort
    end
  end
end
