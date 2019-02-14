require 'securerandom'
begin
  require 'active_support/encrypted_file'
rescue LoadError
  require 'secure_credentials/active_support/encrypted_file'
end

module SecureCredentials
  # Wraps ActiveSupport::EncryptedFile and provides passing key as an argument.
  # Automatically generates missing key filenames based on store filename.
  class EncryptedFile < ActiveSupport::EncryptedFile
    class << self
      # Same file name but with `.key` extension instead of `.enc`.
      def default_key_path_for(filename)
        filename.sub_ext('.key')
      end
    end

    def initialize(path, key = nil, key_path: nil, env_key: nil)
      @key = key
      super(
        content_path: path,
        key_path: key_path || self.class.default_key_path_for(path),
        env_key: env_key,
        raise_if_missing_key: true,
      )
    end

    def key
      @key || read_env_key || read_key_file || SecureCredentials.master_key || handle_missing_key
    end
  end
end
