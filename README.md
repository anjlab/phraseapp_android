# PhraseappAndroid

This gem is intended to make managing PhraseApp translations in Android projects much easier.

## Installation

    $ gem install phraseapp_android

## Usage

    $ ./phrase_app_translations COMMAND

Commands:

    list_missing        List missing translations
    pull                Download translations from PhraseApp
    push                Upload translations to PhraseApp
    reformat            Sort translations texts alphabetically in local files
    check_formatting    Check formatting arguments in local files

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/anjlab/phraseapp_android. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

