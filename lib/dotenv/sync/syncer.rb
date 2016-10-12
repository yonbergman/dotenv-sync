require 'openssl'
require 'base64'
require 'dotenv/cli'
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

      CONFLICT_REGEX = %r{
        \A
        <<<<<<<\s*(?<current_branch>.+?)
        (?<current_branch_data>.*?)
        =======
        (?<other_branch_data>.*?)
        >>>>>>>\s*(?<other_branch>.+?)
        \Z
      }xm


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
        data = read(@secret_filename)
        data = sort_lines(data.lines)
        encrypted = encrypt(key, data)
        write_64 @encrypted_filename, encrypted
        puts "Successfully encrypted #{@secret_filename}"
        data
      end

      def pull
        data = load_data
        write(@secret_filename, data)
        puts "Successfully decrypted #{@secret_filename}"
        data
      end

      def merge
        existing_data = read(@secret_filename)
        merged_data = merge_lines(load_data, existing_data)
        write(@secret_filename, merged_data)
        puts "Successfully merged #{@secret_filename}"
        merged_data
      end

      def resolve_merge
        validate_file! @encrypted_filename

        encryption_key = read_key!
        data = read(@encrypted_filename)
        matches = CONFLICT_REGEX.match(data)

        if matches.nil?
          raise ConflictNotFound.new(@encrypted_filename)
        end

        branch_envs = [:current_branch, :other_branch].inject({}) do |h, branch|
          branch_name = matches[branch]

          iv, encrypted = extract(matches["#{branch}_data"])

          decrypted = decrypt(encryption_key, iv, encrypted)

          h[branch_name] = Dotenv::Parser.call(decrypted)
          h
        end

        left_name, left = branch_envs.entries.first
        right_name, right = branch_envs.entries.last

        merged = right.inject(left) do |memo, entry|
          key, right_value = entry
          left_value = memo[key]

          if left_value && left_value != right_value
            puts 'Conflict: ' + key
            puts "#{left_name}: #{left_value}"
            puts "#{right_name}: #{right_value}"
            puts

            # TODO: Ask to choose
          end

          memo[key] = right_value
          memo
        end

        merged = merged.map { |k, v| "#{k}=#{v}" }

        data = sort_lines(merged)

        encrypted = encrypt(encryption_key, data)

        write_64(@encrypted_filename, encrypted)
      end

      def merge_lines(left, right)
        left_lines = left.lines.map(&:strip)
        right_lines = right.lines.map(&:strip)
        merged = left_lines + (right_lines - left_lines)
        sort_lines(merged)
      end

      def load_data
        validate_file! @encrypted_filename

        key = read_key!
        iv, encrypted = extract(read(@encrypted_filename))

        decrypt(key, iv, encrypted)
      end

      def sort(filename)
        validate_file!(filename)
        lines = open(filename).readlines()
        output = sort_lines(lines)
        write(filename, output)
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

      def write(file, data)
        open(file, 'w') do |f|
          f.write(data)
        end
      end

      def write_64(file, data)
        write(file, Base64.encode64(data))
      end

      def read(file)
        open(file).read
      end

      def read_64(file)
        Base64.decode64(read(file))
      end

      def extract(data)
        data = Base64.decode64(data)
        data.split(SEPARATOR)
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

      def decrypt(key, iv, encrypted)
        cipher.decrypt
        cipher.iv = iv
        cipher.key = key
        cipher.update(encrypted) + cipher.final
      end

      def encrypt(key, data)
        cipher.encrypt
        cipher.key = key
        random_iv = cipher.random_iv
        cipher.iv = random_iv

        encrypted = cipher.update(data) + cipher.final

        random_iv + SEPARATOR + encrypted
      end

      def validate_file!(filename)
        raise FilePresenceError.new(filename) unless File.exists? filename
      end

    end
  end
end