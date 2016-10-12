require 'thor'
require_relative './syncer'
require_relative './errors'

module Dotenv
  module Sync
    class CommandLine < Thor

      def self.start(args)
        begin
          super(args)
        rescue Dotenv::Sync::CommandNotFound => e
          begin
            require "dotenv/cli"
            Dotenv::CLI.new(ARGV).run
          rescue Exception
            puts "dotenv gem not installed, falling back to dotenv-sync"
            super(["--help"])
          end
        end
      end

      desc "[command]", "Runs the command while loading the env variables from .env (based on the dotenv gem)"
      def any()
        raise NotImplementedError.new
      end

      desc "sort [DOTENV_FILE=.env]", "Sorts your .env file"
      def sort(filename = Dotenv::Sync::Syncer::DEFAULT_SORT_FILE)
        Syncer.new.sort(filename)
      end

      option :key, desc: "The keyfile", default: Syncer::DEFAULT_KEY_FILE, aliases: :k
      option :encrypted, desc: "The shared encrypted file", default: Syncer::DEFAULT_ENCRYPTED_FILE, aliases: :e
      option :secret, desc: "The private secret file", default: Syncer::DEFAULT_SECRET_FILE, aliases: :s
      desc "pull", "Update your .env.local file from the encrypted version"
      def pull
        Syncer.new(options).pull
      end

      option :key, desc: "The keyfile", default: Syncer::DEFAULT_KEY_FILE, aliases: :k
      option :encrypted, desc: "The shared encrypted file", default: Syncer::DEFAULT_ENCRYPTED_FILE, aliases: :e
      option :secret, desc: "The private secret file", default: Syncer::DEFAULT_SECRET_FILE, aliases: :s
      desc "merge", "Update your .env.local file from the encrypted version (preserving local changes)"
      def merge
        Syncer.new(options).merge
      end

      option :key, desc: "The keyfile", default: Syncer::DEFAULT_KEY_FILE, aliases: :k
      option :encrypted, desc: "The shared encrypted file", default: Syncer::DEFAULT_ENCRYPTED_FILE, aliases: :e
      desc "resolve-conflict", "Interactively resolve Git conflicts in your encrypted file"
      def resolve_conflict
        Syncer.new(options).resolve_conflict(self)
      end

      option :key, desc: "The keyfile", default: Syncer::DEFAULT_KEY_FILE, aliases: :k
      option :encrypted, desc: "The shared encrypted file", default: Syncer::DEFAULT_ENCRYPTED_FILE, aliases: :e
      option :secret, desc: "The private secret file", default: Syncer::DEFAULT_SECRET_FILE, aliases: :s
      desc "push", "Update the encrypted file from your version of .env.local"
      def push
        Syncer.new(options).push
      end

      option :key, desc: "The keyfile", default: Syncer::DEFAULT_KEY_FILE, aliases: :k
      desc "generate_key", "Generate a new key file"
      def generate_key
        Syncer.new(options).generate_key
      end

      def self.handle_no_command_error(command)
        raise CommandNotFound.new
      end

    end
  end
end
