require 'bundler_autoloading/kernel_mixin'
require 'bundler_autoloading/dependency_mixin'
require 'bundler_autoloading/runtime_mixin'

module BundlerAutoloading
  class AutoloadError < Bundler::BundlerError; status_code(8); end

  class << self
    attr_reader :config_path

    def config_path=(config_path)
      @config_path = config_path
      @config = nil
    end

    def config
      @config ||= File.file?(config_path) ? YAML.load_file(config_path) : {}
    end

    def install_autoloads(autoloads, path, explicit, gem_name)
      autoloads.each do |specifier|
        install_autoloader_for(specifier.to_s, path, explicit, gem_name)
      end
    end

    def autorequire(path, explicit)
      if explicit
        Kernel.require(path)
      else
        begin
          Kernel.require(path)
        rescue LoadError
        end
      end
    end

    def trigger_autoload(specifier)
      autorequires = autoloads[specifier] or
        # No autoload registered.
        return false

      if autorequires == :loaded
        # This constant/method should have been loaded.
        raise AutoloadError, "Gem did not autoload `#{specifier}'"
      elsif autorequires == :loading
        # This constant/method is being referred to by the gem that
        # should be loading it. Pretend we're not here.
        return false
      end

      autoloads[specifier] = :loading
      gem_names = []
      autorequires.each do |path, explicit, gem_name|
        gem_names << gem_name unless gem_names.any?{|name| name == gem_name}
        autorequire(path, explicit)
      end
      autoloads[specifier] = :loaded
      if @on_autoload_callback
        gem_names.each{|gem_name| @on_autoload_callback.call(specs[gem_name])}
      end
      true
    end

    def register_autoload(specifier, path, explicit, gem_name)
      autoloads[specifier] << [path, explicit, gem_name]
    end

    def on_autoload(&block)
      @on_autoload_callback = block
    end

    attr_accessor :specs

    private

    def install_autoloader_for(specifier, path, explicit, gem_name)
      if specifier.rindex(/(?:::|[#.])/)
        mod_name, separator, base_name, mod = $`, $&, $'
      else
        mod_name, separator, base_name = 'Object', '::', specifier
      end
      BundlerAutoloading.register_autoload("#{mod_name}#{separator}#{base_name}", path, explicit, gem_name)
      mod = mod_name.split(/::/).inject(Object){|mod, n| mod.const_get(n)}

      case separator
      when '#'
        check_autoload_trigger(specifier) { mod.method_defined?(base_name) }
        install_instance_method_autoloader(mod, mod_name, separator)
      when '.'
        check_autoload_trigger(specifier) { mod.respond_to?(base_name) }
        install_class_method_autoloader(mod, mod_name, separator)
      when '::'
        check_autoload_trigger(specifier) { mod.const_defined?(base_name) }
        install_constant_autoloader(mod, mod_name, separator)
      end
    end

    def check_autoload_trigger(specifier)
      !yield or
        raise ArgumentError, "`#{specifier}' already defined"
    end

    def install_instance_method_autoloader(mod, mod_name, separator)
      define_autoloader(mod, mod_name, separator, :method_missing, :send)
    end

    def install_class_method_autoloader(mod, mod_name, separator)
      singleton_class = class << mod; self; end
      define_autoloader(singleton_class, mod_name, separator, :method_missing, :send)
    end

    def install_constant_autoloader(mod, mod_name, separator)
      singleton_class = class << mod; self; end
      define_autoloader(singleton_class, mod_name, separator, :const_missing, :const_get)
    end

    def define_autoloader(mod, mod_name, separator, method, retry_method)
      return if mod.method_defined?("#{method}_with_bundler_autoloading")
      mod.module_eval <<-EOS
        def #{method}_with_bundler_autoloading(name, *args, &block)
          if BundlerAutoloading.trigger_autoload("#{mod_name}#{separator}\#{name}")
            #{retry_method}(name, *args, &block)
          else
            #{method}_without_bundler_autoloading(name, *args, &block)
          end
        end
        alias #{method}_without_bundler_autoloading #{method}
        alias #{method} #{method}_with_bundler_autoloading
      EOS
    end

    def autoloads
      @autoloads ||= Hash.new{|h,k| h[k] = []}
    end
  end

  self.config_path = 'config/bundler_autoloading.yml'
end

Kernel.send :include, BundlerAutoloading::KernelMixin
Bundler::Dependency.send :include, BundlerAutoloading::DependencyMixin
Bundler::Runtime.send :include, BundlerAutoloading::RuntimeMixin
