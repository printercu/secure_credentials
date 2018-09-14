# SecureCredentials

[![Gem Version](https://badge.fury.io/rb/secure_credentials.svg)](http://badge.fury.io/rb/secure_credentials)
[![Code Climate](https://codeclimate.com/github/printercu/secure_credentials/badges/gpa.svg)](https://codeclimate.com/github/printercu/secure_credentials)
[![Build Status](https://travis-ci.org/printercu/secure_credentials.svg)](https://travis-ci.org/printercu/secure_credentials)

## Rationale

Rails 5.2 brings good idea of storing encrypted credentials in the repo:
credentials are securely tracked in version control, less chance to face an issue
during deployment, etc. However there are several drawbacks in current implementation:

- It's hard to manage environment-specific credentials.
  For example, to use different browser api keys in development and production,
  one is whitelisted for `locahost` and other one for app's domain.
- In most cases it's required to share `master.key` with every developer.
  This is not acceptable for a lot of teams, and framework must serve their needs too.

There are a couple ways to workaround this issues, but all of them brings
unnecessary complexity. This gem takes best from new encrypted credentials (`credentials.yml.enc`)
and multi-environmental secrets (`secrets.yml`). It allows to use combination
of encrypted and plain files for same configuration in different environments.
For example, having encrypted `credentials.production.yml.enc` for production
and multi-environmental `credentials.yml` for all other environments.

There are some other issues caused by storing `master.key` in local repo.
See this wiki page for details:<br>
[Rails 5.2 credentials are not secure](https://github.com/printercu/secure_credentials/wiki/Rails-5.2-credentials-are-not-secure).

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

SecureCredentials::Store provides read-write access to YAML configuration files. It supports:

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
  - in envvar identified by `env_key`, default is to upcased basename appended with `_KEY`
    (ex., `SECRETS_KEY`);
  - in file found at `key_path`,
    by default it uses filename and replaces `.yml.enc` with `.key`
    (`secrets.production.key` for `secrets.production.yml.enc`);
  - `SecureCredentials.master_key` which is read from `config/master.key` in Rails apps.

To edit encrypted files use `rails encrypted:edit path/to/file.yml.enc -k path/to/key.key`.
Missing `.key` and `.yml` files are automatically created when you edit them for the first time.

## Best practices

- __Don't keep master.key in local working directory!__

  It's like a PIN-code written on backside of credit card.
  Keep it in secure place and use it when you need to modify credentials.

- Don't share production credentials with those team members who don't need to access them.

  Secrets get less secret every time they are shared.
  It's better to share some particular keys to selected developers,
  instead of giving everybody access to all keys.

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
