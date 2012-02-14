class Updater
  def initialize
    if update!
      report(title, title_type)
    else
      puts "Already up-to-date."
    end
  end

  private
  def report
    puts "Updated #{@title} from #{@initial[0,8]} to #{@current[0,8]}."

    # get installed formulas list
    installed = Homebrew.cellar.children.
      select { |pn| pn.directory? }.
      map    { |pn| pn.basename.to_s }.sort if Homebrew.cellar.directory?

    @changes.each do |type, changes|
      unless changes.empty?
        ohai("#{type} #{@title_type}")

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
        @changes = { 'New'     => changed_items('A', @track_dir),
                     'Updated' => changed_items('M', @track_dir),
                     'Deleted' => changed_items('D', @track_dir) }
        return true
      end
    end

    # assume nothing was updated
    return false
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
end

class UpdateFormulary < Updater
  def initialize
    @title      = 'Formulary',
    @repo_url   = 'https://github.com/etehtsea/formulary.git',
    @repo_dir   = Homebrew.formulary,
    @track_dir  = 'Formula/',
    @title_type = 'formulae'

    super
  end
end

class UpdateBrew < Updater
  def initialize
    @title      = 'Homebrew',
    @repo_url   = 'https://github.com/etehtsea/homebrew.git',
    @repo_dir   = Homebrew.repository,
    @track_dir  = 'Library/Homebrew/cmd',
    @title_type = 'commands'

    super
  end
end
