require 'securerandom'
begin
  require 'active_support/encrypted_file'
rescue LoadError
  require 'secure_credentials/active_support/encrypted_file'
end

module SecureCredentials
  # Wraps ActiveSupport::EncryptedFile to accept key as an argument.
  class EncryptedFile < ActiveSupport::EncryptedFile
    def initialize(key: nil, key_path: nil, env_key: nil, **options)
      @key = key
      super(
        **options,
        env_key: env_key,
        key_path: key_path || key && '' # original implementation does not accept nil
      )
    end

    def key
      @key || super
    end
  end
end
