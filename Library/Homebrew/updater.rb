class Updater
  def initialize
    abort "Please `brew install git' first." unless system "/usr/bin/which -s git"
  end

  def git_repo?
    Dir['.git/*'].length > 0
  end

  # Performs an update of the homebrew source. Returns +true+ if a newer
  # version was available, +false+ if already up-to-date.
  def update!(path, repository_url)
    initial, current = nil, nil

    path.cd do
      if git_repo?
        safe_system "git checkout -q master"
        initial = read_revision
        # originally we fetched by URL but then we decided that we should
        # use origin so that it's easier for forks to operate seamlessly
        unless `git remote`.split.include? 'origin'
          safe_system "git remote add origin #{repository_url}"
        end
      else
        begin
          safe_system "git init"
          safe_system "git remote add origin #{repository_url}"
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
      # Added (A), Copied (C), Deleted (D), Modified (M), Renamed (R)
      @changes_map = Hash.new { |h, k| h[k] = [] }

      changes = path.cd do
        execute("git diff-tree -r --name-status -z #{initial} #{current}").split("\0")
      end

      while status = changes.shift
        file = changes.shift
        @changes_map[status] << file
      end

      if @changes_map.any?
        yield

        return [initial, current]
      end

    end

    # assume nothing was updated
    return false
  end

  def report(title, repo, url)
    revisions = update!(repo, url) do
      yield
    end

    if revisions
      puts "Updated #{title} from #{revisions.first[0,8]} to #{revisions.last[0,8]}."

      @sections.each do |title, changes|
        unless changes.first.empty?
          ohai(title)
          if changes.size == 2
            puts_columns changes.first, changes.last
          else
            puts_columns changes
          end
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

  # extracts items by status from @changes_map
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
  REPOSITORY_URL = "https://github.com/etehtsea/formulary.git"
  FORMULA_DIR = "Formula/"

  def initialize
    super

    report("Formulary", FORMULARY_REPOSITORY, REPOSITORY_URL) do
      installed = HOMEBREW_CELLAR.children.
        select { |pn| pn.directory? }.
        map    { |pn| pn.basename.to_s }.sort if HOMEBREW_CELLAR.directory?
      @sections = {
        "New formulae"     => [changed_items('A', FORMULA_DIR)],
        "Removed formulae" => [changed_items('D', FORMULA_DIR), installed],
        "Updated formulae" => [changed_items('M', FORMULA_DIR), installed] }
    end
  end
end

class UpdateBrew < Updater
  REPOSITORY_URL = "https://github.com/etehtsea/homebrew.git"
  CMD_DIR = 'Library/Homebrew/cmd'

  def initialize
    super

    report("Homebrew", HOMEBREW_REPOSITORY, REPOSITORY_URL) do
      @sections = {
        "New commands"     => [changed_items('A', CMD_DIR)],
        "Removed commands" => [changed_items('D', CMD_DIR)] }
    end
  end
end
