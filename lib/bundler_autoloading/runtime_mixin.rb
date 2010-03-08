module BundlerAutoloading
  module RuntimeMixin
    def self.included(base)
      base.send :alias_method, :specs_for_without_bundler_autoloading, :specs_for
      base.send :alias_method, :specs_for, :specs_for_with_bundler_autoloading
    end

    def specs_for_with_bundler_autoloading(*args, &block)
      specs = specs_for_without_bundler_autoloading(*args, &block)
      BundlerAutoloading.specs = index_specs_by_name(specs)
      specs
    end

    def index_specs_by_name(specs)
      by_name = {}
      specs.each do |spec|
        by_name[spec.name] = spec
      end
      by_name
    end
  end
end
