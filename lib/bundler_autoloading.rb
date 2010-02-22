require 'bundler_autoloading/bundler_extension'
require 'bundler_autoloading/runtime_mixin'
require 'bundler_autoloading/dependency_mixin'

module BundlerAutoloading
  class AutoloadError < Bundler::BundlerError; status_code(8); end
end

Bundler.send :extend, BundlerAutoloading::BundlerExtension
Bundler::Runtime.send :include, BundlerAutoloading::RuntimeMixin
Bundler::Dependency.send :include, BundlerAutoloading::DependencyMixin
