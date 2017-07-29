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

require 'securerandom'
require 'minitest/autorun'
require 'test/unit/assertions'

require 'fileutils'

module Reality
  class TestCase < Minitest::Test
    BASE_DIR = File.expand_path("#{File.dirname(__FILE__)}/..")
    ZAPWHITE_BIN = ((defined?(JRUBY_VERSION) || Gem.win_platform?) ? 'ruby ' : '') + File.join(BASE_DIR, 'bin', 'zapwhite')

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
      @workspace_dir ||= File.expand_path(ENV['TEST_TMP_DIR'] || "#{BASE_DIR}/tmp/workspace")
    end

    # Evaluate block after changing directory to specified directory
    def in_dir(dir, &block)
      original_dir = Dir.pwd
      begin
        Dir.chdir(dir)
        block.call
      ensure
        Dir.chdir(original_dir)
      end
    end

    def run_command(command, exitcode = 0)
      output = `#{command}`
      status = $?.exitstatus
      raise "Error executing command: #{command}\nExpected exitcode #{exitcode}, Actual exitcode #{status}\nOutput: #{output}" unless status == exitcode
      output
    end

    def create_git_repo
      directory = "#{working_dir}#{::SecureRandom.hex}"

      FileUtils.mkdir_p directory

      in_dir(directory) do
        run_command('git init')
        run_command("git config --local user.name \"Your Name\"")
        run_command("git config --local user.email \"you@example.com\"")
        yield
        run_command('git add *')
        run_command("git commit -m \"initial commit\"")
      end

      directory
    end

    # Write .gitattributes relative to current working directory
    def write_gitattributes_file(content)
      write_file('.gitattributes', content)
    end

    # Write file relative to current working directory
    def write_file(filename, content)
      FileUtils.mkdir_p File.dirname(filename)
      IO.binwrite(filename, content)
    end
  end
end
