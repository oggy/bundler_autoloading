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
      if autoload
        @autoload = normalize_autoload(autoload)
      end
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
