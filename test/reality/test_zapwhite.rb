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
      output = run_command("#{ZAPWHITE_BIN}", 0)
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
      output = run_command("#{ZAPWHITE_BIN}", 1)
      assert_equal "Fixing: README.md\n", output
      assert_equal "Hello\n", IO.binread("#{dir}/README.md")
    end
  end

  def test_fixing_trailing_whitespace_not_crlf_specified
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.md text -crlf
TEXT
      write_file('README.md', "Hello \n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN}", 1)
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
      output = run_command("#{ZAPWHITE_BIN}", 1)
      assert_equal "Fixing: README.md\n", output
      assert_equal "Hello\n", IO.binread("#{dir}/README.md")
    end
  end

  def test_dos_eol
    dir = create_git_repo do
      write_gitattributes_file(<<TEXT)
*.bat text crlf
TEXT
      write_file('run.bat', "echo hi\n")
    end
    in_dir(dir) do
      output = run_command("#{ZAPWHITE_BIN}", 1)
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
      output = run_command("#{ZAPWHITE_BIN}", 1)
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
      output = run_command("#{ZAPWHITE_BIN}", 0)
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
      output = run_command("#{ZAPWHITE_BIN}", 0)
      assert_equal '', output
      assert_equal 'Hello', IO.binread("#{dir}/README.md")
    end
  end
end
