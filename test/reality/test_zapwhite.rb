require File.expand_path('../../helper', __FILE__)

class Reality::TestZapwhite < Reality::TestCase
  def test_no_changes_required
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.md text
TEXT
      write_file('README.md', "Hello\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 0)
      assert_equal '', output
    end
  end

  def test_fixing_trailing_whitespace
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.md text
TEXT
      write_file('README.md', "Hello \n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 1)
      assert_equal "Fixing: README.md\n", output
      assert_equal "Hello\n", IO.binread("#{dir}/README.md")
    end
  end

  def test_fixing_trailing_whitespace_where_rule_has_whitespace_pattern
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
Read[[:space:]]Me.txt text
TEXT
      write_file('Read Me.txt', "Hello \n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 1)
      assert_equal "Fixing: Read Me.txt\n", output
      assert_equal "Hello\n", IO.binread("#{dir}/Read Me.txt")
    end
  end

  def test_fixing_trailing_whitespace_not_crlf_specified
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.md text eol=lf
TEXT
      write_file('README.md', "Hello \n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 1)
      assert_equal "Fixing: README.md\n", output
      assert_equal "Hello\n", IO.binread("#{dir}/README.md")
    end
  end

  def test_end_of_file_new_line
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.md text
TEXT
      write_file('README.md', 'Hello')
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 1)
      assert_equal "Fixing: README.md\n", output
      assert_equal "Hello\n", IO.binread("#{dir}/README.md")
    end
  end

  def test_dos_eol
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.bat text eol=crlf
TEXT
      write_file('run.bat', "echo hi\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 1)
      assert_equal "Fixing: run.bat\n", output
      assert_equal "echo hi\r\n", IO.binread("#{dir}/run.bat")
    end
  end

  def test_dedup_new_line
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.md text -dupnl
TEXT
      write_file('README.md', "Hello\n\n\n\n\nHow are you?\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 1)
      assert_equal "Fixing: README.md\n", output
      assert_equal "Hello\n\nHow are you?\n", IO.binread("#{dir}/README.md")
    end
  end

  def test_no_dedup_new_line
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.md text dupnl
TEXT
      write_file('README.md', "Hello\n\n\n\nHow are you?\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 0)
      assert_equal '', output
      assert_equal "Hello\n\n\n\nHow are you?\n", IO.binread("#{dir}/README.md")
    end
  end

  def test_no_eofnl
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.md text -eofnl
TEXT
      write_file('README.md', 'Hello')
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 0)
      assert_equal '', output
      assert_equal 'Hello', IO.binread("#{dir}/README.md")
    end
  end

  def test_generate_gitattributes
    dir = create_git_repo do
      write_file('README.md', "Hello\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --generate-gitattributes", 1)
      assert_equal "Fixing: .gitattributes\n", output
      assert_equal "Hello\n", IO.binread("#{dir}/README.md")
      assert_equal "# DO NOT EDIT: File is auto-generated\n* -text\n*.md text\n", IO.binread("#{dir}/.gitattributes")
    end
  end

  def test_generate_gitattributes_updates_whitespace_subsequently
    dir = create_git_repo do
      write_file('README.md', "Hello  \n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --generate-gitattributes", 2)
      assert_equal "Fixing: .gitattributes\nFixing: README.md\n", output
      assert_equal "Hello\n", IO.binread("#{dir}/README.md")
      assert_equal "# DO NOT EDIT: File is auto-generated\n* -text\n*.md text\n", IO.binread("#{dir}/.gitattributes")
    end
  end

  def test_allow_empty
    dir = create_git_repo do
      write_file('BUILD', "\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN}", 2)
      assert_equal "Fixing: .gitattributes\nFixing: BUILD\n", output
      assert_equal "", IO.binread("#{dir}/BUILD")
      assert_equal "# DO NOT EDIT: File is auto-generated\n* -text\nBUILD text allow_empty\n", IO.binread("#{dir}/.gitattributes")
    end
  end

  def test_generate_gitattributes_matches
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
# DO NOT EDIT: File is auto-generated
* -text
*.md text
TEXT
      write_file('README.md', "Hello\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --generate-gitattributes", 0)
      assert_equal '', output
      assert_equal "Hello\n", IO.binread("#{dir}/README.md")
      assert_equal "# DO NOT EDIT: File is auto-generated\n* -text\n*.md text\n", IO.binread("#{dir}/.gitattributes")
    end
  end

  def test_generate_gitattributes_with_additional_rules
    dir = create_git_repo do
      write_file('README.md', "Hello\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --generate-gitattributes --rule '*.bin -diff' --rule '*.rxt text'", 1)
      assert_equal "Fixing: .gitattributes\n", output
      assert_equal "Hello\n", IO.binread("#{dir}/README.md")
      assert_equal "# DO NOT EDIT: File is auto-generated\n* -text\n*.md text\n*.bin -diff\n*.rxt text\n", IO.binread("#{dir}/.gitattributes")
    end
  end

  def test_verbose_mode
    dir = create_git_repo do
      write_file('README.md', "Hello\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --generate-gitattributes --rule '*.bin -diff' --rule '*.rxt text' --verbose", 1)
      assert_equal <<OUTPUT, output
Base Directory: #{dir}
Check for violations or fix violations: fix
Generate .gitattributes file?: true
Additional .gitattribute rules:
 * *.bin -diff
 * *.rxt text
Exclude patterns:
 * vendor/.*
 * node_modules/.*
Fixing: .gitattributes
OUTPUT
    end
  end

  def test_braids_are_added_to_excludes
    dir = create_git_repo do
      write_file('README.md', "Hello\n")
      write_file('.braids.json',<<BRAIDS_JSON)
{
  "vendor/docs/way_of_stock": {
    "url": "https://github.com/stocksoftware/way_of_stock.git",
    "branch": "master",
    "revision": "0405926c5b4229e7d1f605a65603df64b5667f2d"
  },
  "vendor/tools/buildr_plus": {
    "url": "https://github.com/realityforge/buildr_plus.git",
    "branch": "master",
    "revision": "4a4a0666871861de1ddc7581a02d6d656702fa6b"
  },
  "vendor/tools/dbt": {
    "branch": "master",
    "revision": "554139d3ea275bd54949b9504090c77e4d39ba65",
    "url": "https://github.com/realityforge/dbt.git"
  },
  "vendor/tools/domgen": {
    "branch": "master",
    "revision": "1da8f5d43f9c84ac234c6354af8717bcfde03f88",
    "url": "https://github.com/realityforge/domgen.git"
  },
  "vendor/tools/kinjen": {
    "url": "https://github.com/realityforge/kinjen.git",
    "branch": "master",
    "revision": "34a962de77918bc1a76f1fcf8c92fe6721d5b524"
  },
  "vendor/tools/redfish": {
    "url": "https://github.com/realityforge/redfish.git",
    "branch": "master",
    "revision": "5e6bb18009e682c09631e1234c955373735d27ab"
  },
  "vendor/tools/resgen": {
    "url": "https://github.com/realityforge/resgen.git",
    "branch": "master",
    "revision": "631a5aa371d3c6f2a68c95e5da3ca8e16a6ee0c7"
  }
}
BRAIDS_JSON
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --generate-gitattributes --rule '*.bin -diff' --rule '*.rxt text' --verbose", 1)
      assert_equal <<OUTPUT, output
Base Directory: #{dir}
Check for violations or fix violations: fix
Generate .gitattributes file?: true
Additional .gitattribute rules:
 * *.bin -diff
 * *.rxt text
Exclude patterns:
 * vendor/.*
 * node_modules/.*
 * vendor/docs/way_of_stock
 * vendor/tools/buildr_plus
 * vendor/tools/dbt
 * vendor/tools/domgen
 * vendor/tools/kinjen
 * vendor/tools/redfish
 * vendor/tools/resgen
Fixing: .gitattributes
OUTPUT
    end
  end

  def test_file_with_bom
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.tsql text
TEXT
      write_file('test.tsql', IO.binread(File.expand_path(BASE_DIR + '/test/fixtures/file_with_bom.tsql')))
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 1)
      assert_equal "Fixing: test.tsql\n", output
      assert_equal "CREATE TYPE [dbo].[Boolean__Yes_No_] FROM [tinyint] NOT NULL\n", IO.binread("#{dir}/test.tsql")
    end
  end

  def test_file_with_utf8_encoding
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.tcss text
TEXT
      write_file('test.tcss', IO.binread(File.expand_path(BASE_DIR + '/test/fixtures/utf8.tcss')))
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 0)
      assert_equal '', output
      assert_equal IO.binread(File.expand_path(BASE_DIR + '/test/fixtures/utf8.tcss')), IO.binread("#{dir}/test.tcss")
    end
  end

  def test_file_with_bom_encoding_set
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.tsql text encoding=utf-8
TEXT
      write_file('test.tsql', IO.binread(File.expand_path(BASE_DIR + '/test/fixtures/file_with_bom.tsql')))
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN} --no-generate-gitattributes", 1)
      assert_equal "Fixing: test.tsql\n", output
      assert_equal "CREATE TYPE [dbo].[Boolean__Yes_No_] FROM [tinyint] NOT NULL\n", IO.binread("#{dir}/test.tsql")
    end
  end
end
