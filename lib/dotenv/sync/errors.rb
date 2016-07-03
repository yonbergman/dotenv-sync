module Dotenv
  module Sync
    class FilePresenceError < StandardError
      def initialize(filename)
        super("File doesn't exist #{filename}")
      end
    end
  end
end