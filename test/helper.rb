#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
