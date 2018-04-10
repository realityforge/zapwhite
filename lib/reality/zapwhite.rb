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
require 'json'

module Reality
  class Zapwhite

    def initialize(base_directory)
      @base_directory = base_directory
      @attributes = Reality::Git::Attributes.parse(@base_directory)
      @exclude_patterns = %w(vendor/.* node_modules/.*) + load_braid_mirrors
      @check_only = false
      @additional_gitattribute_rules = []
    end

    def exclude_patterns
      @exclude_patterns
    end

    attr_accessor :additional_gitattribute_rules

    attr_writer :generate_gitattributes

    def generate_gitattributes?
      @generate_gitattributes
    end

    def check_only?
      !!@check_only
    end

    attr_writer :check_only

    # Run normalization process across directory.
    # Return the number of files that need normalization
    def run
      normalize_count = 0

      if generate_gitattributes?
        output_options = {:prefix => '# DO NOT EDIT: File is auto-generated', :normalize => true}
        new_gitattributes = generate_gitattributes!
        new_content = new_gitattributes.as_file_contents(output_options)
        old_content = File.exist?(@attributes.attributes_file) ? IO.read(@attributes.attributes_file) : nil
        if new_content != old_content
          @attributes = new_gitattributes
          if check_only?
            puts 'Non-normalized .gitattributes file'
          else
            puts 'Fixing: .gitattributes'
            @attributes.write(output_options)
          end
          normalize_count += 1
        end
      end

      files = {}

      collect_file_attributes(files)

      files.each_pair do |filename, config|
        full_filename = "#{@base_directory}/#{filename}"
        original_bin_content = File.binread(full_filename)

        encoding = config[:encoding].nil? ? 'utf-8' : config[:encoding].gsub(/^UTF/,'utf-')

        content = File.read(full_filename, :encoding => "bom|#{encoding}")

        content =
          config[:dos] ?
            clean_dos_whitespace(filename, content, config[:eofnl]) :
            clean_whitespace(filename, content, config[:eofnl])
        if config[:nodupnl]
          while content.gsub!(/\n\n\n/, "\n\n")
            # Keep removing duplicate new lines till they have gone
          end
        end
        if content.bytes != original_bin_content.bytes
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

    def load_braid_mirrors
      braid_file = "#{@base_directory}/.braids.json"
      File.exist?(braid_file) ? JSON.parse(IO.read(braid_file)).keys : []
    end

    def generate_gitattributes!
      attributes = Reality::Git::Attributes.new(@base_directory)
      template = create_template_gitattributes
      each_git_filename do |f|
        full_filename = "#{@base_directory}/#{f}"
        template.rules_for_path(full_filename).each do |rule|
          attributes.rule(rule.pattern, rule.attributes.merge(:priority => rule.priority))
          template.remove_rule(rule)
        end
      end
      self.additional_gitattribute_rules.each do |line|
        rule = Reality::Git::AttributeRule.parse_line(line)
        attributes.rule(rule.pattern, rule.attributes.merge(:priority => 2))
      end
      attributes
    end

    def collect_file_attributes(files)
      each_git_filename do |f|
        full_filename = "#{@base_directory}/#{f}"
        if File.exist?(full_filename)
          attr = @attributes.attributes(f)
          if attr['text']
            files[f] = {
              :dos => (attr['eol'] == 'crlf'),
              :encoding => attr['encoding'],
              :nodupnl => attr['dupnl'].nil? ? false : !attr['dupnl'],
              :eofnl => attr['eofnl'].nil? ? true : !!attr['eofnl']
            }
          end
        end
      end
    end

    def each_git_filename
      exclude_patterns = self.exclude_patterns.collect {|s| /^#{s}$/}

      in_dir(@base_directory) do
        `git ls-files`.split("\n").each do |f|
          yield f unless exclude_patterns.any? {|p| p =~ f}
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

    def create_template_gitattributes
      attributes = Reality::Git::Attributes.new(@base_directory)
      attributes.rule('*', :text => false)

      attributes.dos_text_rule('*.rdl', :eofnl => false)
      attributes.unix_text_rule('*.sh')
      attributes.text_rule('*.md')

      attributes.text_rule('.gitignore')
      attributes.text_rule('.gitattributes')

      attributes.text_rule('.node-version')

      # Ruby defaults
      attributes.text_rule('Gemfile')
      attributes.text_rule('*.gemspec')
      attributes.text_rule('.ruby-version')
      attributes.text_rule('*.rb')
      attributes.text_rule('*.yaml')
      attributes.text_rule('*.yml')

      attributes.text_rule('*.haml')
      attributes.text_rule('*.rhtml')

      # Documentation defaults
      attributes.text_rule('*.txt')
      attributes.text_rule('*.md')
      attributes.text_rule('*.textile')
      attributes.text_rule('*.rdoc')
      attributes.text_rule('*.html')
      attributes.text_rule('*.xhtml')
      attributes.text_rule('*.css')
      attributes.text_rule('*.js')
      attributes.binary_rule('*.jpg')
      attributes.binary_rule('*.jpeg')
      attributes.binary_rule('*.png')
      attributes.binary_rule('*.bmp')
      attributes.binary_rule('*.ico')

      attributes.binary_rule('*.pdf')
      attributes.binary_rule('*.doc')

      # Common file formats
      attributes.text_rule('*.json')
      attributes.text_rule('*.xml')
      attributes.text_rule('*.xsd')
      attributes.text_rule('*.xsl')
      attributes.text_rule('*.wsdl')

      # Build system defaults
      attributes.text_rule('buildfile')
      attributes.text_rule('Buildfile')
      attributes.text_rule('Rakefile')
      attributes.text_rule('rakefile')
      attributes.text_rule('*.rake')

      attributes.text_rule('*.graphql')
      attributes.text_rule('*.graphqls')
      attributes.text_rule('*.ts')
      attributes.text_rule('*.tsx')
      attributes.text_rule('*.ts')
      attributes.text_rule('*.tsx')
      attributes.text_rule('Jenkinsfile')
      attributes.text_rule('*.groovy')
      attributes.dos_text_rule('*.rdl', :eofnl => false)
      attributes.text_rule('*.erb')
      attributes.text_rule('*.sass')
      attributes.text_rule('*.scss')
      attributes.text_rule('*.less')
      attributes.text_rule('*.sql')
      attributes.text_rule('*.java')
      attributes.text_rule('*.jsp')
      attributes.text_rule('*.properties')
      attributes.rule('*.jar', :binary => true)
      attributes.text_rule('Vagrantfile')
      attributes.text_rule('Dockerfile')
      attributes.text_rule('LICENSE')
      attributes.text_rule('CHANGELOG')

      # Shell scripts
      attributes.dos_text_rule('*.cmd')
      attributes.dos_text_rule('*.bat')
      attributes.text_rule('*.sh')

      # WASM development files
      attributes.text_rule('*.wast')
      attributes.text_rule('*.wat')
      attributes.binary_rule('*.wasm')

      # Native development files
      attributes.text_rule('*.c')
      attributes.binary_rule('*.dll')
      attributes.binary_rule('*.so')

      # IDE files
      attributes.text_rule('*.iml')
      attributes.text_rule('*.ipr')

      attributes
    end
  end
end
