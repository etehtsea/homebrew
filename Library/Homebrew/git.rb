module Git
  class << self
    def installed?
      system "/usr/bin/which -s git"
    end

    def version
      `git --version`.chomp
    end
  end

  class Config
    def self.get(option)
      `git config --get #{option}`.chomp
    end
  end

  class Repo
    def initialize(dir, url = nil)
      abort "Please `brew install git' first." unless Git.installed?
      @url = url
      Dir.chdir(dir)
    end

    def branch
      `git branch`.chomp
    end

    def log(args)
      if args.empty?
        exec "git", "log"
      else
        exec "git", "log", *args
      end
    end

    def short_status(path = nil)
      `git status -s #{path} 2> /dev/null`.chomp
    end

    def exists?
      !Dir['.git/*'].empty?
    end

    def init
      begin
        safe_system "git init"
        add_origin(@url)
        safe_system "git fetch origin"
        safe_system "git reset --hard origin/master"
      rescue Exception
        safe_system "/bin/rm -rf .git"
        raise
      end
    end

    def head
      execute("git rev-parse --verify -q HEAD 2>/dev/null").chomp
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
