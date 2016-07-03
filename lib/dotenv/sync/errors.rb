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
  end
end