module Spec
  module Rubygems
    def self.setup
      Gem.clear_paths

      ENV['GEM_HOME'] = ENV['GEM_PATH'] = Path.base_system_gems.to_s
      ENV['PATH'] = "#{Path.system_gem_path}/bin:#{ENV['PATH']}"

      unless File.exist?("#{Path.base_system_gems}")
        FileUtils.mkdir_p(Path.base_system_gems)
        puts "running `gem install builder --no-rdoc --no-ri`"
        `gem install builder --no-rdoc --no-ri`
      end

      ENV['HOME'] = Path.home.to_s

      Gem::DefaultUserInteraction.ui = Gem::SilentUI.new
    end

    def gem_command(command, args = "", options = {})
      if command == :exec && !options[:no_quote]
        args = args.gsub(/(?=")/, "\\")
        args = %["#{args}"]
      end
      lib  = File.join(File.dirname(__FILE__), '..', '..', 'lib')
      %x{#{Gem.ruby} -I#{lib} -rubygems -S gem --backtrace #{command} #{args}}.strip
    end
  end
end