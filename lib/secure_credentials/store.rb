require 'secure_credentials/encrypted_file'
require 'yaml'

module SecureCredentials
  # Store provides read-write interface for YAML configuration files. It supports:
  #
  #   - both encrypted and plain files,
  #   - both file-per-environment and multi-environment files.
  #
  # It takes base path of configuration file (for example, `config/secrets`)
  # and environment value. Then it tries to find the most appropriate file
  # for this configuration in following order:
  #
  #     "#{base}.#{env}.yml.enc"
  #     "#{base}.#{env}.yml"
  #     "#{base}.yml.enc"
  #     "#{base}.yml"
  #
  # Key for decoding encoded files can be passed:
  #
  #   - in `key` argument;
  #   - envvar identified by `env_key`, default is to upcased basename appended with `_KEY`
  #     (ex., `SECRETS_KEY`);
  #   - in file found at `key_path`,
  #     by default it uses filename and replaces `.yml.enc` with `.key`
  #     (`secrets.production.key` for `secrets.production.yml.enc`);
  #   - SecureCredentials.master_key.
  #
  # If environment specific file is present, it's whole content is returned.
  # Otherwise `env` is used to fetch appropriate section.
  class Store
    class << self
      # Finds the most appropriate existing file for given path and env.
      # Returns `[environmental?, encrypted?, filename]`.
      def detect_filename(path, env)
        stub_ext_path = Pathname.new("#{path}.stub")
        if path.basename.to_s.include?('.yml')
          [false, path.basename.to_s.end_with?('.enc'), path]
        else
          [
            [true,  true,   stub_ext_path.sub_ext(".#{env}.yml.enc")],
            [true,  false,  stub_ext_path.sub_ext(".#{env}.yml")],
            [false, true,   stub_ext_path.sub_ext('.yml.enc')],
            [false, false,  stub_ext_path.sub_ext('.yml')],
          ].find { |x| x[2].exist? }
        end
      end

      def env_key_for(path)
        "#{path.basename.to_s.upcase}_KEY"
      end

      # ERB -> YAML.safe_load with aliases support.
      def load_yaml(string)
        YAML.safe_load(ERB.new(string).result, [], [], true)
      end
    end

    attr_reader :path, :filename, :env, :environmental, :encrypted
    alias_method :environmental?, :environmental
    alias_method :encrypted?, :encrypted

    def initialize(path, key = nil, env: nil, key_path: nil, env_key: nil)
      @path = path = Pathname.new(path)
      @env = env
      @environmental, @encrypted, @filename = self.class.detect_filename(path, env)
      @key = key
      @key_path = key_path || filename && filename.sub_ext('').sub_ext('.key')
      @env_key = env_key || self.class.env_key_for(path)
    end

    # Fetches appropriate environmental content or returns whole content
    # in the case of single-environment file.
    def content
      result = environmental? ? full_content : full_content[env.to_s]
      result || {}
    end

    # Read file content.
    def read
      return '' unless filename && filename.exist?
      if encrypted?
        encrypted_file.read
      else
        filename.read
      end
    end

    # Prepares file for edition, yields filename and then saves updated file.
    def change(&block)
      raise FileNotFound, "File not found for '#{path}'" unless filename && filename.exist?
      if encrypted?
        encrypted_file.change(&block)
      else
        yield filename
      end
    end

    private

    attr_reader :key, :key_path, :env_key

    def full_content
      string = read
      result = self.class.load_yaml(string) if string.present?
      result || {}
    end

    def encrypted_file
      EncryptedFile.new(filename, key, key_path: key_path, env_key: env_key)
    end
  end
end
