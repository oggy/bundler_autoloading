# Bundler Autoloading

Adds (limited) support to [Bundler][bundler] for autoloading gems.

Bundler Autoloading lets you tell Bundler to automatically load gems
when a particular constant is referenced, or method is called.

Example `Gemfile`:

    gem 'bundler_autoloading'

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

## Why would I want this?

If your application is taking too long to start up, and you're loading
lots of gems, many of which you only need a fraction of the time.  For
example, a large Rails application which loads a whole heap of gems it
only needs to serve a small number of routes.

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
