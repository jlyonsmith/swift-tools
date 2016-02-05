require 'minitest/autorun'

class TestEnder < Minitest::Test
  def setup()
    @bin_dir = File.expand_path(File.join(File.dirname(__FILE__), '../bin'))
    @ender_dir = File.expand_path(File.join(File.dirname(__FILE__), 'ender'))

    gen_test_file("cr.txt", "\r")
    gen_test_file("lf.txt", "\n")
    gen_test_file("crlf.txt", "\r\n")
    gen_test_file("mixed1.txt", "\n\r\n\r")
    gen_test_file("mixed2.txt", "\n\n\r\n\r")
    gen_test_file("mixed3.txt", "\n\r\n\r\r")
    gen_test_file("mixed4.txt", "\n\r\n\r\r\n")
  end

  def gen_test_file(file, content)
    File.open(File.join(@ender_dir, file), 'w') { |f| f.write(content) }
  end

  def test_vamper_help
    output = `#{@bin_dir}/ender --help`
    assert_match /Usage:/, output
  end

  def test_cr_txt
    output = `cd #{@ender_dir}; #{@bin_dir}/ender cr.txt`
    assert output.end_with?("\"cr.txt\", cr, 2 lines\n"), output
  end

  def test_lf_txt
    output = `cd #{@ender_dir}; #{@bin_dir}/ender lf.txt`
    assert output.end_with?("\"lf.txt\", lf, 2 lines\n"), output
  end

  def test_crlf_txt
    output = `cd #{@ender_dir}; #{@bin_dir}/ender crlf.txt`
    assert output.end_with?("\"crlf.txt\", crlf, 2 lines\n"), output
  end

  # TODO: The rest of these...

  # eval $ENDER mixed1.txt
  # eval $ENDER mixed2.txt
  # eval $ENDER mixed3.txt
  # eval $ENDER mixed4.txt
  # eval $ENDER -m lf -o cr2lf.txt cr.txt
  # eval $ENDER -m cr -o lf2cr.txt lf.txt
  # eval $ENDER -m lf -o crlf2lf.txt crlf.txt
  # eval $ENDER -m cr -o crlf2cr.txt crlf.txt
  # eval $ENDER -m auto mixed1.txt
  # eval $ENDER -m auto mixed2.txt
  # eval $ENDER -m auto mixed3.txt
  # eval $ENDER -m auto mixed4.txt
end
