# SecureCredentials

Makes it possible to use best of encrypted credentials
and environment-dependent secrets. Sharing encryption keys with
every developer in a team is a security issue, and purpose of this gem
is to help you to avoid it.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'secure_credentials'
```

And then execute:

    $ bundle

## Usage

By default this gem patches Rails::Application to make `#credentials`, `#secrets` and `#encrypted`
use Rails-compatible wrapper around SecureCredentials::Store.

SecureCredentials::Store provides read-write interface for YAML configuration files. It supports:

  - both encrypted and plain files,
  - both file-per-environment and multi-environment files.

It takes base path of configuration file (for example, `config/secrets`)
and environment value. Then it tries to find the most appropriate file
for this configuration in following order:

    "#{base}.#{env}.yml.enc"
    "#{base}.#{env}.yml"
    "#{base}.yml.enc"
    "#{base}.yml"

If environment specific file is present, it's whole content is returned.
Otherwise `env` is used to fetch appropriate section.

Key for decoding encoded files can be passed:

  - in `key` argument;
  - envvar identified by `env_key`, default is to upcased basename appended with `_KEY`
    (ex., `SECRETS_KEY`);
  - in file found at `key_path`,
    by default it uses filename and replaces `.yml.enc` with `.key`
    (`secrets.production.key` for `secrets.production.yml.enc`);
  - `SecureCredentials.master_key` which is read from `config/master.key` in Rails apps.

Use `rails encrypted path/to/file.yml.enc -k path/to/key.key` to edit encrypted files.
Missing `.key` and `.yml` files are automatically created when you edit them for the first time.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/printercu/secure_credentials.
