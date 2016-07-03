require 'openssl'
require 'base64'
require_relative './errors'

module Dotenv
  module Sync
    class Syncer

      GITIGNORE = '.gitignore'
      DEFAULT_SORT_FILE = '.env'
      DEFAULT_SECRET_FILE = '.env.local'
      DEFAULT_ENCRYPTED_FILE = '.env-encrypted'
      DEFAULT_KEY_FILE = '.env-key'
      DEFAULT_CONFIG_FILE = '.env-config'
      SEPARATOR = ">>>><<<<"

      def initialize(options = {})
        @key_filename = options[:key] || DEFAULT_KEY_FILE
        @secret_filename = options[:secret] || DEFAULT_SECRET_FILE
        @encrypted_filename = options[:encrypted] || DEFAULT_ENCRYPTED_FILE
        validate_gitignore
      end

      def generate_key
        key = cipher.random_key
        write_64(@key_filename, key)
      end

      def push
        validate_file! @secret_filename
        key = read_key!
        data = open(@secret_filename).read()
        data = sort_lines(data.lines)
        cipher.encrypt
        cipher.key = key
        random_iv = cipher.random_iv
        cipher.iv = random_iv
        encrypted = cipher.update(data) + cipher.final
        encrypted = random_iv + SEPARATOR + encrypted
        write_64 @encrypted_filename, encrypted
        puts "Successfully encrypted #{@secret_filename}"
      end

      def pull
        validate_file! @encrypted_filename
        key = read_key!
        data = read_64 @encrypted_filename
        iv, encrypted = data.split(SEPARATOR)
        cipher.decrypt
        cipher.iv = iv
        cipher.key = key
        data = cipher.update(encrypted)
        open(@secret_filename, 'w').write(data)
        puts "Successfully decrypted #{@secret_filename}"
      end

      def sort(filename)
        validate_file!(filename)
        lines = open(filename).readlines()
        output = sort_lines(lines)
        open(filename, 'w').write(output)
        puts "Done sorting"
      end

      private

      def validate_gitignore
        gitignore_file = open(GITIGNORE,'a+')
        lines = gitignore_file.readlines
        additions = [@secret_filename, @key_filename].reject do |secret_file|
          lines.map(&:strip).include? secret_file
        end
        unless additions.empty?
          output = "\n# Dotenv syncing\n" + additions.join("\n")
          gitignore_file.write(output)
        end

        gitignore_file.close
      end

      def write_64(file, data)
        open(file, 'w').write(Base64.encode64(data))
      end

      def read_64(file)
        Base64.decode64(open(file).read)
      end

      def read_key!
        read_64 @key_filename
      rescue Exception => e
        raise MissingKeyFile.new(@key_filename)
      end

      def sort_lines(lines)
        lines.map!(&:strip)
        env_lines = lines.reject { |line| line.start_with?("#") }
        comments = lines - env_lines
        env_lines = env_lines.reject { |line| line.strip.empty? }.sort
        (comments + env_lines).join("\n")
      end

      def cipher
        @cipher ||= OpenSSL::Cipher::AES256.new(:CBC)
      end

      def validate_file!(filename)
        raise FilePresenceError.new(filename) unless File.exists? filename
      end

    end
  end
end