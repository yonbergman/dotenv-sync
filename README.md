# Dotenv::Sync

Dotenv-sync is a small utility that lets you sync `.env` secrets in your repo.

This assumes you use [dotenv](https://github.com/bkeepers/dotenv) to manage and load your environment variables locally and relies on the fact that _dotenv_ supports environment specific dotenv files.

## How it works
dotenv-sync assumes you have two seperate files:

```
.env        - containts all non-secret env variables and shared on git
.env.local  - contatins only the secrets and is not shared on git directly
```

This gem then uses a shared secret keyfile `.env-key` __which should not be commited__,
to encrypt and decrypt the `.env.local` file and share it in the repo as `.env-encrypted`.

You can use _1Password for teams_ or _Vault_ for sharing your secret keyfile.

### Overview
![](/docs/dotenv-sync.png)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dotenv-sync'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dotenv-sync

## Usage

Dotenv-sync provides a command line file with several commands to run.

```
dotenv-sync [command]                # Runs the command while loading the env variables from .env (based on the dotenv gem)
dotenv-sync generate_key             # Generate a new key file
dotenv-sync pull                     # Update your .env.local file from the encrypted version
dotenv-sync push                     # Update the encrypted file from your version of .env.local
dotenv-sync sort [DOTENV_FILE=.env]  # Sorts your .env file
dotenv-sync help [COMMAND]           # Describe available commands or one specific command
```

### First use
When initializing a new project you need to run `dotenv-sync generate_key` followed by `dotenv-sync push` to create the key which should be securely shared and the `.env-encrypted` file which can be commited.

### Subsequent uses
If you're updating `.env.local` and want to share a change run `dotenv-sync push` and then commit the changed `.env-encrypted` file.

If you're pulling a change from git and see that `.env-encypted` changed run `dotenv-sync pull` to update your local `.env.local`

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yonbergman/dotenv-sync. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

