require 'homebrew/updater'

module Homebrew
  module Formulary
    class << self
      def path
        @formulary ||= Homebrew.prefix + 'formulary'
      end

      def exists?
        path.directory?
      end

      def create
        FileUtils.mkdir(path)
      rescue Errno::EEXIST
        opoo "Formulary directory exists"
      end

      def init
        create unless exists?

        u = Updater.new('etehtsea/formulary')
        Git::Repo.new(u.repo_dir).exists?
      end

      def list
        Dir.entries(path)[2..-1].sort
      end

      def add(name)
        create unless exists?
        dir = name.split('/').last

        if list.include?(dir)
          onoe "Already added"
        else
          begin
            u = Updater.new(name)
            Git::Repo.new(u.repo_dir).exists?
          rescue ErrorDuringExecution => e
            onoe e.message
            FileUtils.rm_rf(Homebrew.formulary + dir)
          end
        end
      end

      def remove(name)
        repo_dir = name.split('/').last
        if list.include?(repo_dir)
          FileUtils.rm_rf(path + repo_dir)
        else
          onoe "Repo not found"
        end
      end
    end
  end
end
