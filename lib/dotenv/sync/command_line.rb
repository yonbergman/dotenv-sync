require 'thor'
require_relative './syncer'

module Dotenv
  module Sync
    class CommandLine < Thor
      desc "sort [DOTENV_FILE=.env]", "Sorts your .env file"
      def sort(filename = Dotenv::Sync::Syncer::DEFAULT_FILE)
        puts "Hello #{filename}"
        Syncer.new.sort(filename)
      end

      desc "pull [DOTENV_FILE=.env]", "Update your .env.local file from the encrypted version"
      def pull(filename = Dotenv::Sync::Syncer::DEFAULT_SECRET_FILE)
        puts "Hello #{filename}"
        Syncer.new.pull
      end

      desc "push [DOTENV_FILE=.env]", "Update the encrypted file from your version of .env.local"
      def push(filename = Dotenv::Sync::Syncer::DEFAULT_SECRET_FILE)
        puts "Hello #{filename}"
        Syncer.new.push
      end

      desc "generate_key [KEY_FILE=.env-key]", "Generate a new key file"
      def generate_key(filename = Dotenv::Sync::Syncer::DEFAULT_KEY_FILE)
        Syncer.new.generate_key(filename)
      end
    end
  end
end