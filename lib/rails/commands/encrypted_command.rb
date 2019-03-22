# Backport of encrypted:edit command from Rails 5.2 to Rails 5.1.

if Gem::Version.new(ActiveSupport::VERSION::STRING) >= Gem::Version.new('5.2')
  raise 'This file should not be required with your rails version. Please file an issue.'
end

# rubocop:disable all

module Rails
  module Command
    module Helpers
      module Editor
        private
          def ensure_editor_available(command:)
            if ENV["EDITOR"].to_s.empty?
              say "No $EDITOR to open file in. Assign one like this:"
              say ""
              say %(EDITOR="mate --wait" #{command})
              say ""
              say "For editors that fork and exit immediately, it's important to pass a wait flag,"
              say "otherwise the credentials will be saved immediately with no chance to edit."

              false
            else
              true
            end
          end

          def catch_editing_exceptions
            yield
          rescue Interrupt
            say "Aborted changing file: nothing saved."
          rescue ActiveSupport::EncryptedFile::MissingKeyError => error
            say error.message
          end
      end
    end
  end
end

module Rails
  module Command
    class EncryptedCommand < Rails::Command::Base # :nodoc:
      include Helpers::Editor

      class_option :key, aliases: "-k", type: :string,
        default: "config/master.key", desc: "The Rails.root relative path to the encryption key"

      no_commands do
        def help
          say "Usage:\n  #{self.class.banner}"
          say ""
        end
      end

      def edit(file_path)
        require_application_and_environment!
        encrypted = Rails.application.encrypted(file_path, key_path: options[:key])

        ensure_editor_available(command: "bin/rails encrypted:edit") || (return)
        ensure_encryption_key_has_been_added(options[:key]) if encrypted.key.nil?
        ensure_encrypted_file_has_been_added(file_path, options[:key])

        catch_editing_exceptions do
          change_encrypted_file_in_system_editor(file_path, options[:key])
        end

        say "File encrypted and saved."
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        say "Couldn't decrypt #{file_path}. Perhaps you passed the wrong key?"
      end

      def show(file_path)
        require_application_and_environment!
        encrypted = Rails.application.encrypted(file_path, key_path: options[:key])

        say encrypted.read.presence || missing_encrypted_message(key: encrypted.key, key_path: options[:key], file_path: file_path)
      end

      private
        def ensure_encryption_key_has_been_added(key_path)
          encryption_key_file_generator.add_key_file(key_path)
          encryption_key_file_generator.ignore_key_file(key_path)
        end

        def ensure_encrypted_file_has_been_added(file_path, key_path)
          encrypted_file_generator.add_encrypted_file_silently(file_path, key_path)
        end

        def change_encrypted_file_in_system_editor(file_path, key_path)
          Rails.application.encrypted(file_path, key_path: key_path).change do |tmp_path|
            system("#{ENV["EDITOR"]} #{tmp_path}")
          end
        end


        def encryption_key_file_generator
          require "rails/generators"
          # require "rails/generators/rails/encryption_key_file/encryption_key_file_generator"

          Rails::Generators::EncryptionKeyFileGenerator.new
        end

        def encrypted_file_generator
          require "rails/generators"
          # require "rails/generators/rails/encrypted_file/encrypted_file_generator"

          Rails::Generators::EncryptedFileGenerator.new
        end

        def missing_encrypted_message(key:, key_path:, file_path:)
          if key.nil?
            "Missing '#{key_path}' to decrypt data. See bin/rails encrypted:help"
          else
            "File '#{file_path}' does not exist. Use bin/rails encrypted:edit #{file_path} to change that."
          end
        end
    end
  end
end

require "rails/generators"
require "rails/generators/base"

module Rails
  module Generators
    class EncryptedFileGenerator < Base # :nodoc:
      def add_encrypted_file_silently(file_path, key_path, template = encrypted_file_template)
        unless File.exist?(file_path)
          setup = { content_path: file_path, key_path: key_path, env_key: "RAILS_MASTER_KEY", raise_if_missing_key: true }
          ActiveSupport::EncryptedFile.new(setup).write(template)
        end
      end

      private
        def encrypted_file_template
          <<-YAML.strip_heredoc
          # aws:
          #   access_key_id: 123
          #   secret_access_key: 345

          YAML
        end
    end
  end
end

module Rails
  module Generators
    class EncryptionKeyFileGenerator < Base # :nodoc:
      def add_key_file(key_path)
        key_path = Pathname.new(key_path)

        unless key_path.exist?
          key = ActiveSupport::EncryptedFile.generate_key

          log "Adding #{key_path} to store the encryption key: #{key}"
          log ""
          log "Save this in a password manager your team can access."
          log ""
          log "If you lose the key, no one, including you, can access anything encrypted with it."

          log ""
          add_key_file_silently(key_path, key)
          log ""
        end
      end

      def add_key_file_silently(key_path, key = nil)
        create_file key_path, key || ActiveSupport::EncryptedFile.generate_key
        key_path.chmod 0600
      end

      def ignore_key_file(key_path, ignore: key_ignore(key_path))
        if File.exist?(".gitignore")
          unless File.read(".gitignore").include?(ignore)
            log "Ignoring #{key_path} so it won't end up in Git history:"
            log ""
            append_to_file ".gitignore", ignore
            log ""
          end
        else
          log "IMPORTANT: Don't commit #{key_path}. Add this to your ignore file:"
          log ignore, :on_green
          log ""
        end
      end

      def ignore_key_file_silently(key_path, ignore: key_ignore(key_path))
        append_to_file ".gitignore", ignore if File.exist?(".gitignore")
      end

      private
        def key_ignore(key_path)
          [ "", "/#{key_path}", "" ].join("\n")
        end
    end
  end
end

# rubocop:enable all
