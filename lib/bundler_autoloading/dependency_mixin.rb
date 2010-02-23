module BundlerAutoloading
  module DependencyMixin
    def self.included(base)
      base.send :alias_method, :initialize_without_bundler_autoloading, :initialize
      base.send :alias_method, :initialize, :initialize_with_bundler_autoloading
    end

    attr_reader :autoload

    def initialize_with_bundler_autoloading(name, version, options = {}, &block)
      autoload = options['autoload']
      initialize_without_bundler_autoloading(name, version, options = {}, &block)

      # Intuitively, we should just be monkeypatching
      # Runtime#autorequires_for_groups and Runtime#require. The only
      # sane way to do this, however, is to completely plaster over
      # these methods with a hacked version, which is just asking to
      # be killed by a Bundler upgrade.
      #
      # Instead, we hijack #autorequire here. This thing eventually
      # gets jammed into Kernel.require, which we mangle so it
      # understands what this unholy mess means.
      @autorequire = [[@autorequire || name, !!@autorequire,
          autoload ? normalize_autoload(autoload) : nil]]
    end

    def normalize_autoload(autoload)
      if autoload == true
        infer_namespace(name)
      else
        Array(autoload)
      end
    end

    def infer_namespace(gem_name)
      gem_name.gsub(/[\W_]+/, '_').gsub(/(?:^|_)(.)/){$1.upcase}.sub(/^\d/, '_\\&')
    end
  end
end
