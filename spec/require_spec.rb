require 'spec_helper'

describe "Bundler.require" do
  describe "without autoload" do
    it "should load the gem as normal" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib"
      G

      run "Bundler.require; p !!defined?(SlowLib)"
      out.should == "true"
    end

    it "should not affect the require option" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/other-name.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :require => 'other-name'
      G

      run "Bundler.require; p !!defined?(SlowLib)"
      out.should == "true"
    end
  end

  describe "with autoload" do
    it "does not load the gem" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => true
      G

      run "Bundler.require; p !!defined?(SlowLib)"
      out.should == "false"
    end

    it "loads the gem when the implied constant is referenced, if :autoload => true is given" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => true
      G

      run "Bundler.require; SlowLib; p !!defined?(SlowLib)"
      out.should == "true"
    end

    it "loads the gem when the given constant is referenced" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module OtherName; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'OtherName'
      G

      run "Bundler.require; OtherName; p !!defined?(OtherName)"
      out.should == "true"
    end

    it "runs the on_autoload callback after autoloading the gem" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'SlowLib'
      G

      run "BundlerAutoloading.on_autoload{|spec| puts spec.name}; Bundler.require; SlowLib"
      out.should == "slow_lib"
    end

    it "does not run the on_autoload callback for gems that are not autoloaded" do
      build_lib "fast_lib", "1.0.0" do |s|
        s.write "lib/fast_lib.rb", "module FastLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "fast_lib"
      G

      run "BundlerAutoloading.on_autoload{|spec| puts spec.name}; Bundler.require; FastLib"
      out.should == ""
    end

    it "accepts a symbol for a constant" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module OtherName; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => :OtherName
      G

      run "Bundler.require; OtherName; p !!defined?(OtherName)"
      out.should == "true"
    end

    it "loads the gem when the given class method is called" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end; def Module.foo; 100; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'Module.foo'
      G

      run "Bundler.require; p Module.foo; p !!defined?(SlowLib)"
      out.should == "100\ntrue"
    end

    it "loads the gem when the given instance method is called" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end; class Module; def foo; 100; end; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'Module#foo'
      G

      run "Bundler.require; Module.new.foo; p !!defined?(SlowLib)"
      out.should == "true"
    end

    it "loads the gem when any of the given constants are referenced, or methods are called" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end; class Module; def foo; 100; end; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => ['SlowLib', 'Module#foo']
      G

      run "Bundler.require; p !!defined?(SlowLib)"
      out.should == "false"

      run "Bundler.require; SlowLib; p !!defined?(SlowLib)"
      out.should == "true"

      run "Bundler.require; Module.new.foo; p !!defined?(SlowLib)"
      out.should == "true"
    end

    it "should raise an ArgumentError if an autoload constant is already defined" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'SlowLib'
      G

      run <<-R
        SlowLib = :boom
        begin
          Bundler.require
          puts 'LOSE'
        rescue ArgumentError
          puts 'WIN'
        end
      R
      out.should == "WIN"
    end

    it "should raise an ArgumentError if an autoload instance method is already defined" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'Module#foo'
      G

      run <<-R
        class Module
          def foo
            :boom
          end
        end

        begin
          Bundler.require
          puts 'LOSE'
        rescue ArgumentError
          puts 'WIN'
        end
      R
      out.should == "WIN"
    end

    it "should raise an ArgumentError if an autoload class method is already defined" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'Module.foo'
      G

      run <<-R
        def Module.foo
          :boom
        end

        begin
          Bundler.require
          puts 'LOSE'
        rescue ArgumentError
          puts 'WIN'
        end
      R
      out.should == "WIN"
    end

    it "should raise an AutoloadError if the autoloaded gem doesn't define the triggering constant" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'WrongConstant'
      G

      run <<-R
        begin
          Bundler.require
          WrongConstant
          puts 'LOSE'
        rescue BundlerAutoloading::AutoloadError
          puts 'WIN'
        end
      R
      out.should == "WIN"
    end

    it "should raise an AutoloadError if the autoloaded gem doesn't define the triggering instance method" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'String#wrong_method'
      G

      run <<-R
        begin
          Bundler.require
          ''.wrong_method
          puts 'LOSE'
        rescue BundlerAutoloading::AutoloadError
          puts 'WIN'
        end
      R
      out.should == "WIN"
    end

    it "should raise an AutoloadError if the autoloaded gem doesn't define the triggering class method" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'String.wrong_method'
      G

      run <<-R
        begin
          Bundler.require
          String.wrong_method
          puts 'LOSE'
        rescue BundlerAutoloading::AutoloadError
          puts 'WIN'
        end
      R
      out.should == "WIN"
    end

    it "should not load a library twice if autoloaded via two different triggers" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "Foo = Bar = 1; puts 'loaded'"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => %w'Foo Bar'
      G

      run <<-R
        Bundler.require
        Foo
        Bar
      R
      out.should == "loaded"
    end

    it "should be invisible to the autoloaded library if it tries to reference the triggering constant before setting it" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", <<-EOS
          begin
            SlowLib
            puts 'LOSE'
          rescue NameError
            puts 'WIN'
          end
        EOS
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'SlowLib'
      G

      run <<-R
        Bundler.require
        SlowLib
      R
      out.should == "WIN"
    end

    it "should be invisible to the autoloaded library if it tries to reference the triggering instance method before defining it" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", <<-EOS
          begin
            ''.foo
            puts 'LOSE'
          rescue NameError
            puts 'WIN'
          end
        EOS
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'String#foo'
      G

      run <<-R
        Bundler.require
        ''.foo
      R
      out.should == "WIN"
    end

    it "should be invisible to the autoloaded library if it tries to reference the triggering class method before defining it" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", <<-EOS
          begin
            String.foo
            puts 'LOSE'
          rescue NameError
            puts 'WIN'
          end
        EOS
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib", :autoload => 'String.foo'
      G

      run <<-R
        Bundler.require
        String.foo
      R
      out.should == "WIN"
    end

    it "should use autoloads defined in the config file if not explicitly specified" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib"
      G

      write_file 'config/bundler_autoloading.yml', <<-C
        slow_lib:
          - SlowLib
      C

      run <<-C
        Bundler.require
        p !!defined?(SlowLib)
        SlowLib
        p !!defined?(SlowLib)
      C
      out.should == "false\ntrue"
    end

    it "should allow specifying the config path" do
      build_lib "slow_lib", "1.0.0" do |s|
        s.write "lib/slow_lib.rb", "module SlowLib; end"
      end

      gemfile <<-G
        require 'bundler_autoloading'
        path "#{lib_path}"
        gem "slow_lib"
      G

      write_file 'custom_path.yml', <<-C
        slow_lib:
          - SlowLib
      C

      @out = ruby <<-C
        require 'rubygems'
        require 'bundler'
        require 'bundler_autoloading'
        BundlerAutoloading.config_path = 'custom_path.yml'
        Bundler.setup

        Bundler.require
        p !!defined?(SlowLib)
        SlowLib
        p !!defined?(SlowLib)
      C
      out.should == "false\ntrue"
    end
  end

  def write_file(path, content)
    path = bundled_app(path)
    FileUtils.mkdir_p File.dirname(path)
    File.open(path, 'w'){|f| f.print content}
  end
end
