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

require 'reality/gitattributes'

module Reality
  class Zapwhite

    def initialize(base_directory)
      @base_directory = base_directory
      @attributes = Reality::GitAttributes.new(@base_directory)
      @exclude_patterns = %w(vendor/.* node_modules/.*)
      @check_only = false
    end

    def exclude_patterns
      @exclude_patterns
    end

    def check_only?
      !!@check_only
    end

    attr_writer :check_only

    # Run normalization process across directory.
    # Return the number of files that need normalization
    def run
      normalize_count = 0
      files = {}

      collect_files(files)

      files.each_pair do |filename, config|
        full_filename = "#{@base_directory}/#{filename}"
        content = File.read(full_filename)

        content = patch_encoding(content) unless config[:encoding]
        original_content = content.dup
        content =
          config[:dos] ?
            clean_dos_whitespace(filename, content, config[:eofnl]) :
            clean_whitespace(filename, content, config[:eofnl])
        if config[:nodupnl]
          while content.gsub!(/\n\n\n/, "\n\n")
            # Keep removing duplicate new lines till they have gone
          end
        end
        if content != original_content
          normalize_count += 1
          if check_only?
            puts "Non-normalized whitespace in #{filename}"
          else
            puts "Fixing: #{filename}"
            File.open(full_filename, 'wb') do |out|
              out.write content
            end
          end
        end
      end

      normalize_count
    end

    private

    def collect_files(files)
      exclude_patterns = self.exclude_patterns.collect {|s| /^#{s}$/}

      in_dir(@base_directory) do
        `git ls-files`.split("\n").each do |f|
          full_filename = "#{@base_directory}/#{f}"
          if !exclude_patterns.any? {|p| p =~ f} && File.exist?(full_filename)
            attr = @attributes.attributes(f)
            if attr['text']
              files[f] = {
                :dos => (!!attr['crlf']),
                :encoding => attr['encoding'],
                :nodupnl => attr['dupnl'].nil? ? false : !attr['dupnl'],
                :eofnl => attr['eofnl'].nil? ? true : !!attr['eofnl']
              }
            end
          end
        end
      end
    end

    def clean_whitespace(filename, content, eofnl)
      begin
        content.gsub!(/\r\n/, "\n")
        content.gsub!(/[ \t]+\n/, "\n")
        content.gsub!(/[ \r\t\n]+\Z/, '')
        content += "\n" if eofnl
      rescue
        puts "Skipping whitespace cleanup: #{filename}"
      end
      content
    end

    def clean_dos_whitespace(filename, content, eofnl)
      begin
        content.gsub!(/\r\n/, "\n")
        content.gsub!(/[ \t]+\n/, "\n")
        content.gsub!(/[ \r\t\n]+\Z/, '')
        content += "\n" if eofnl
        content.gsub!(/\n/, "\r\n")
      rescue
        puts "Skipping dos whitespace cleanup: #{filename}"
      end
      content
    end

    def patch_encoding(content)
      content =
        content.respond_to?(:encode!) ?
          content.encode!('UTF-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '') :
          content
      content.gsub!(/^\xEF\xBB\xBF/, '')
      content
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
  end
end
