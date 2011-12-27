class Updater
  def initialize
    abort "Please `brew install git' first." unless system "/usr/bin/which -s git"

    report
  end

  def git_repo?
    Dir['.git/*'].length > 0
  end

  # Performs an update of the homebrew source. Returns +true+ if a newer
  # version was available, +false+ if already up-to-date.
  def update!
    initial, current = nil, nil

    @settings[:repo_dir].cd do
      if git_repo?
        safe_system "git checkout -q master"
        initial = read_revision
        # originally we fetched by URL but then we decided that we should
        # use origin so that it's easier for forks to operate seamlessly
        unless `git remote`.split.include? 'origin'
          safe_system "git remote add origin #{@settings[:repo_url]}"
        end
      else
        begin
          safe_system "git init"
          safe_system "git remote add origin #{@settings[:repo_url]}"
          safe_system "git fetch origin"
          safe_system "git reset --hard origin/master"
        rescue Exception
          safe_system "/bin/rm -rf .git"
          raise
        end
      end

      # specify a refspec so that 'origin/master' gets updated
      refspec = "refs/heads/master:refs/remotes/origin/master"
      rebase = "--rebase" if ARGV.include? "--rebase"
      execute "git pull #{rebase} origin #{refspec}"

      current = read_revision
    end

    if initial && initial != current
      # hash with status characters for keys:
      # Added (A), Deleted (D), Modified (M)
      @changes_map = Hash.new { |h, k| h[k] = [] }

      changes = @settings[:repo_dir].cd do
        execute("git diff-tree -r --name-status -z #{initial} #{current}").split("\0")
      end

      while status = changes.shift
        file = changes.shift
        @changes_map[status] << file
      end

      if @changes_map.any?
        @changes = { 'New'     => changed_items('A', @settings[:track_dir]),
                     'Updated' => changed_items('M', @settings[:track_dir]),
                     'Deleted' => changed_items('D', @settings[:track_dir]) }

        return [initial, current]
      end

    end

    # assume nothing was updated
    return false
  end

  def report
    revisions = update!

    if revisions
      puts "Updated #{@settings[:title]} from #{revisions.first[0,8]} to #{revisions.last[0,8]}."

      @changes.each do |type, changes|
        unless changes.empty?
          ohai("#{type} #{@settings[:title_type]}")
          puts_columns changes
        end
      end
    else
      puts "Already up-to-date."
    end
  end

  private
  def read_revision
    execute("git rev-parse HEAD").chomp
  end

  def filter_by_directory(files, dir)
    files.select { |f| f.index(dir) == 0 }
  end

  def basenames(files)
    files.map { |f| File.basename(f, '.rb') }
  end

  def changed_items(status, dir)
    basenames(filter_by_directory(@changes_map[status], dir)).sort
  end

  def execute(cmd)
    out = `#{cmd}`
    if $? && !$?.success?
      $stderr.puts out
      raise "Failed while executing #{cmd}"
    end
    ohai(cmd, out) if ARGV.verbose?
    out
  end
end

class UpdateFormulary < Updater
  def initialize
    @settings = {
      :title      => 'Formulary',
      :repo_url   => 'https://github.com/etehtsea/formulary.git',
      :repo_dir   => FORMULARY_REPOSITORY,
      :track_dir  => 'Formula/',
      :title_type => 'formulae'
    }

    super
  end
end

class UpdateBrew < Updater
  def initialize
    @settings = {
      :title      => 'Homebrew',
      :repo_url   => 'https://github.com/etehtsea/homebrew.git',
      :repo_dir   => HOMEBREW_REPOSITORY,
      :track_dir  => 'Library/Homebrew/cmd',
      :title_type => 'commands'
    }

    super
  end
end
