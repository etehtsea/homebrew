module Git
  class Repo
    def initialize(dir, url)
      unless system "/usr/bin/which -s git"
        abort "Please `brew install git' first."
      end

      @url = url
      Dir.chdir(dir)
    end

    def exists?
      !Dir['.git/*'].empty?
    end

    def init
      begin
        safe_system "git init"
        safe_system "git remote add origin #{@url}"
        safe_system "git fetch origin"
        safe_system "git reset --hard origin/master"
      rescue Exception
        safe_system "/bin/rm -rf .git"
        raise
      end
    end

    def head
      execute("git rev-parse HEAD").chomp
    end

    def add_origin
      # originally we fetched by URL but then we decided that we should
      # use origin so that it's easier for forks to operate seamlessly
      unless `git remote`.split.include? 'origin'
        safe_system "git remote add origin #{@url}"
      end
    end

    def checkout(arg = 'master')
      safe_system "git checkout -q #{arg}"
    end

    def pull
      # specify a refspec so that 'origin/master' gets updated
      refspec = "refs/heads/master:refs/remotes/origin/master"
      rebase = "--rebase" if ARGV.include? "--rebase"
      execute "git pull -q #{rebase} origin #{refspec}"
    end

    def changes(initial, current)
      execute("git diff-tree -r --name-status -z #{initial} #{current}").split("\0")
    end

    private
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
end
