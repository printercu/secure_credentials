require 'active_support/ordered_options'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/module/delegation'

module SecureCredentials
  # Wraps store into compatible with Rails::Application#credentials interface.
  class Credentials
    attr_reader :store
    private :store

    delegate_missing_to :data

    def initialize(store)
      @store = store
    end

    # Required by `rails encrypted` command.
    delegate :change, :read, to: :store

    # Required by `rails encrypted` command.
    def key
      store.send(:encrypted_file).key if store.encrypted?
    rescue ActiveSupport::EncryptedFile::MissingKeyError
      nil
    end

    def data
      @data ||= ActiveSupport::OrderedOptions.new.merge(store.content.deep_symbolize_keys)
    end
  end
end
