require 'thor'

module Dotenv
  module Sync
    class FilePresenceError < Thor::Error
      def initialize(filename)
        super("File doesn't exist #{filename}")
      end
    end

    class MissingKeyFile < Thor::Error
      def initialize(filename)
        super("Missing keyfile: #{filename} - either generate or download the file")
      end
    end

    class NotImplementedError < Thor::Error
      def initialize
        super("Can't run any() command")
      end
    end

    class ConflictNotFound < Thor::Error
      def initialize(filename)
        super("No conflict found in #{filename}.")
      end
    end

    class CommandNotFound < StandardError
    end
  end
end