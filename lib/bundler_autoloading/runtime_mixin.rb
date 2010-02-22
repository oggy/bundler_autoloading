module BundlerAutoloading
  module RuntimeMixin
    def self.included(base)
      base.send :remove_method, :require
      base.send :remove_method, :autorequires_for_groups
    end

    # TODO: This is hopelessly brittle.  Any change to this method in
    # Bundler will be clobbered by us.
    def require(*groups)
      groups.map! { |g| g.to_sym }
      groups = [:default] if groups.empty?
      autorequires = autorequires_for_groups(*groups)

      groups.each do |group|
        (autorequires[group] || [[]]).each do |path, explicit, autoloads|
          if Array(autoloads).empty?
            Bundler.autorequire(path, explicit)
          else
            install_autoloads(autoloads, path, explicit)
          end
        end
      end
    end

    # TODO: This is hopelessly brittle.  Any change to this method in
    # Bundler will be clobbered by us.
    def autorequires_for_groups(*groups)
      groups.map! { |g| g.to_sym }
      autorequires = Hash.new { |h,k| h[k] = [] }

      ordered_deps = []
      specs_for(*groups).each do |g|
        dep = @definition.dependencies.find{|d| d.name == g.name }
        ordered_deps << dep if dep && !ordered_deps.include?(dep)
      end

      ordered_deps.each do |dep|
        dep.groups.each do |group|
          # If there is no autorequire, then rescue from
          # autorequiring the gems name
          if dep.autorequire
            dep.autorequire.each do |file|
              autorequires[group] << [file, true, dep.autoload]
            end
          else
            autorequires[group] << [dep.name, false, dep.autoload]
          end
        end
      end

      if groups.empty?
        autorequires
      else
        groups.inject({}) { |h,g| h[g] = autorequires[g]; h }
      end
    end

    def install_autoloads(autoloads, path, explicit)
      autoloads.each do |specifier|
        install_autoloader_for(specifier.to_s, path, explicit)
      end
    end

    def install_autoloader_for(specifier, path, explicit)
      if specifier.rindex(/(?:::|[#.])/)
        mod_name, separator, base_name, mod = $`, $&, $'
      else
        mod_name, separator, base_name = 'Object', '::', specifier
      end
      Bundler.register_autoload("#{mod_name}#{separator}#{base_name}", path, explicit)
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
          if Bundler.trigger_autoload("#{mod_name}#{separator}\#{name}")
            #{retry_method}(name, *args, &block)
          else
            #{method}_without_bundler_autoloading(name, *args, &block)
          end
        end
        alias #{method}_without_bundler_autoloading #{method}
        alias #{method} #{method}_with_bundler_autoloading
      EOS
    end
  end
end
