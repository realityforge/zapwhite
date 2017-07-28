$:.unshift File.expand_path('../../lib', __FILE__)

require 'securerandom'
require 'minitest/autorun'
require 'test/unit/assertions'
require 'reality/zapwhite'

class Reality::TestCase < Minitest::Test
  include Test::Unit::Assertions

  def setup
    self.setup_working_dir
  end

  def teardown
    self.teardown_working_dir
  end

  def setup_working_dir
    @cwd = Dir.pwd

    FileUtils.mkdir_p self.working_dir
    Dir.chdir(self.working_dir)
  end

  def teardown_working_dir
    Dir.chdir(@cwd)
    if passed?
      FileUtils.rm_rf self.working_dir if File.exist?(self.working_dir)
    else
      $stderr.puts "Test #{self.class.name}.#{name} Failed. Leaving working directory #{self.working_dir}"
    end
  end

  def working_dir
    @working_dir ||= "#{workspace_dir}/#{self.class.name.gsub(/[\.\:]/, '_')}_#{name}_#{::SecureRandom.hex}"
  end

  def workspace_dir
    @workspace_dir ||= File.expand_path(ENV['TEST_TMP_DIR'] || "#{File.dirname(__FILE__)}/../tmp/workspace")
  end
end
