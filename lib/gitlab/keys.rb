# frozen_string_literal: true

module Gitlab
  class Keys
    attr_accessor :auth_file, :logger

    def initialize(logger = Gitlab::AppLogger)
      @auth_file = Gitlab.config.gitlab_shell.auth_file
      @logger = logger
    end

    def add_key(id, key)
      lock do
        public_key = strip(key)
        logger.info("Adding key (#{id}): #{public_key}")
        open_auth_file('a') { |file| file.puts(key_line(id, public_key)) }
      end

      true
    end

    def batch_add_keys(keys)
      lock(300) do # Allow 300 seconds (5 minutes) for batch_add_keys
        open_auth_file('a') do |file|
          keys.each do |key|
            public_key = strip(key[:key])
            logger.info("Adding key (#{key[:id]}): #{public_key}")
            file.puts(key_line(key[:id], public_key))
          end
        end
      end

      true
    end

    def rm_key(id)
      lock do
        logger.info("Removing key (#{id})")
        open_auth_file('r+') do |f|
          while line = f.gets
            next unless line.start_with?("command=\"#{command(id)}\"")

            f.seek(-line.length, IO::SEEK_CUR)
            # Overwrite the line with #'s. Because the 'line' variable contains
            # a terminating '\n', we write line.length - 1 '#' characters.
            f.write('#' * (line.length - 1))
          end
        end
      end

      true
    end

    def clear
      open_auth_file('w') { |file| file.puts '# Managed by gitlab-rails' }

      true
    end

    def list_key_ids
      logger.info('Listing all key IDs')

      [].tap do |a|
        open_auth_file('r') do |f|
          f.each_line do |line|
            key_id = line.match(/key-(\d+)/)

            next unless key_id

            a << key_id[1].chomp.to_i
          end
        end
      end
    end

    private

    def lock(timeout = 10)
      File.open("#{auth_file}.lock", "w+") do |f|
        begin
          f.flock File::LOCK_EX
          Timeout.timeout(timeout) { yield }
        ensure
          f.flock File::LOCK_UN
        end
      end
    end

    def open_auth_file(mode)
      File.open(auth_file, mode, 0o600) do |file|
        file.chmod(0o600)
        yield file
      end
    end

    def key_line(id, key)
      key = key.chomp

      if key.include?("\n") || key.include?("\t")
        raise KeyError, "Invalid public_key: #{key.inspect}"
      end

      %Q(command="#{command(id)}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty #{strip(key)})
    end

    def command(id)
      unless /\A[a-z0-9-]+\z/ =~ id
        raise KeyError, "Invalid ID: #{id.inspect}"
      end

      "#{File.join(Gitlab.config.gitlab_shell.path, 'bin', 'gitlab-shell')} #{id}"
    end

    def strip(key)
      key.split(/[ ]+/)[0, 2].join(' ')
    end
  end
end
