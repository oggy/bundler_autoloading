module BundlerAutoloading
  module KernelMixin
    def self.included(base)
      base.send :alias_method, :require_without_bundler_autoloading, :require
      base.send :alias_method, :require, :require_with_bundler_autoloading
      base.send :module_function, :require
    end

    # See DependencyMixin for my alibi.
    def require_with_bundler_autoloading(unholy_mess) # :nodoc:
      if unholy_mess.is_a?(Array)
        autorequire, explicit, autoloads, gem_name = *unholy_mess

        if autoloads
          action = lambda do |path, explicit|
            BundlerAutoloading.install_autoloads(autoloads, path, explicit, gem_name)
          end
        else
          action = lambda do |path, explicit|
            BundlerAutoloading.autorequire(path, explicit)
          end
        end

        if autorequire
          autorequire.each do |file|
            action.call(file, true)
          end
        else
          action.call(file, false)
        end
      else
        require_without_bundler_autoloading(unholy_mess)
      end
    end
  end
end
