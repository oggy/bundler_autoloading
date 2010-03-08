# Bundler Autoloading

Bundler Autoloading lets you tell Bundler to automatically load gems
when a particular constant is referenced, or method is called.  Great
for speeding up those giant Rails applications!

Example `Gemfile`:

    # Load when the Nokogiri constant is referenced:
    gem 'nokogiri', :autoload => 'Nokogiri'

    # Load when the class method ActiveRecord::Base.has_attached_file is called:
    gem 'paperclip', :autoload => 'ActiveRecord::Base.has_attached_file'

    # Load when the instance method Module#inline is called:
    gem 'RubyInline', :autoload => 'Module#inline'

An array may also be given as the value to `:autoload` to load the gem
on the first of several events:

    gem 'forkoff', :autoload => %w[Forkoff Enumerable#forkoff Enumerable#forkoff!]

If true is given as the value, the autoload constant is inferred:

    gem 'rest-client', :autoload => true  # implies 'RestClient'

## Configuration file

Autoloads may be specified via a configuration file, rather than in
the Gemfile itself.  Keeps your Gemfile mean and lean.

Just before calling `Bundler.setup`:

    # Defaults to "config/bundler_autoloading.yml".
    Bundler.config_path = 'path/to/config.yml'

In config file:

    sunspot: true

    record_filter:
      - RecordFilter
      - ActiveRecord::Base.filter
      - ActiveRecord::Base.named_filter
      - ActiveRecord::Base.named_filters
      - ActiveRecord::Associations::AssociationCollection#filter

## Post-autoload hook

To run a callback after a gem is autoloaded:

    BundlerAutoloading.on_autoload do |spec|
      ...
    end

## Rails 2.3

Follow the [usual steps](http://gist.github.com/302406), then change
`config/preinitializer.rb` to this:

    require "rubygems"
    require "bundler"
    require "bundler_autoloading"
    # Bundler.config_path = 'custom_path.yml'  # defaults to config/bundler_autoloading.yml
    BundlerAutoloading.on_autoload do |spec|
      gem_root = spec.full_gem_path
      if File.exist?((path = "#{gem_root}/init.rb"))
        load path
      elsif File.exist?((path = "#{gem_root}/rails/init.rb"))
        load path
      end
    end
    Bundler.setup

Note that this removes lock support--see below.

## Caveats

Bundler Autoloading does not work with locking.  It will probably
never support this.

Instead, I am working on a patch to have this functionality properly
[integrated into Bundler][ticket].  This gem exists as a stopgap for
developers who don't require locking.

## Contributing

* Bug reports: http://github.com/oggy/bundler_autoloading/issues
* Source: http://github.com/oggy/bundler_autoloading
* Patches: Fork on Github, send pull request.
  * Ensure patch includes tests.
  * Leave the version alone, or bump it in a separate commit.

## Copyright

Copyright (c) 2010 George Ogata. See LICENSE for details.

[bundler]: http://github.com/carlhuda/bundler
[ticket]: http://github.com/carlhuda/bundler/issues/137
