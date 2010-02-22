module BundlerAutoloading
  module BundlerExtension
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
      autorequires.each do |args|
        autorequire(*args)
      end
      autoloads[specifier] = :loaded
      true
    end

    def register_autoload(specifier, path, explicit)
      autoloads[specifier] << [path, explicit]
    end

    private

    def autoloads
      @autoloads ||= Hash.new{|h,k| h[k] = []}
    end
  end
end
