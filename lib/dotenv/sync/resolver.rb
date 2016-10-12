module Dotenv
  module Sync
    module Resolver
      CONFLICT_REGEX = %r{
        \A
        <<<<<<<\s*(?<current_branch>.+?)$
        (?<current_branch_data>.*?)
        =======
        (?<other_branch_data>.*?)
        >>>>>>>\s*(?<other_branch>.+?)
        \Z
      }xm

      NEWLINE = "\n"

      def resolve_conflict(thor)
        def bold(thor, s)
          thor.set_color(s, :bold)
        end

        validate_file! @encrypted_filename

        encryption_key = read_key!
        data = read(@encrypted_filename)
        matches = CONFLICT_REGEX.match(data)

        if matches.nil?
          raise ConflictNotFound.new(@encrypted_filename)
        end

        branch_envs = [:current_branch, :other_branch].map do |branch|
          branch_name = matches[branch]

          iv, encrypted = extract(matches["#{branch}_data"])

          decrypted = decrypt(encryption_key, iv, encrypted)

          comments = decrypted.lines.map(&:strip).take_while { |l| l.start_with?('#') }.join(NEWLINE)
          envvars = Dotenv::Parser.call(decrypted)

          [branch_name, comments, envvars]
        end

        left_name, left_comments, left = branch_envs.first
        right_name, right_comments, right = branch_envs.last

        merged = right.inject(left) do |memo, entry|
          key, right_value = entry
          left_value = memo[key]

          if left_value && left_value != right_value
            s = ['Conflict found on key: ' + bold(thor, left_name)]
            s << "  [1] #{bold(thor, left_name)}:\t#{left_value}"
            s << "  [2] #{bold(thor, right_name)}:\t#{right_value}"
            s = s.join(NEWLINE)

            thor.say(s)

            puts

            choice = thor.ask('Please pick preferred value:', limited_to: %w(1 2))

            right_value = left_value if choice == '1'
          end

          memo[key] = right_value
          memo
        end

        merged = merged.map { |k, v| "#{k}=#{v}" }

        data = right_comments + NEWLINE + sort_lines(merged)

        encrypted = encrypt(encryption_key, data)

        write_64(@encrypted_filename, encrypted)
      end
    end
  end
end
