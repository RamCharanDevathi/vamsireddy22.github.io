#frozen_string_literal: true
require "minitest/autorun"
require "fileutils"

class TestExecutables < Minitest::Test
  def test_bundler
    skip if RUBY_VERSION =~ /^2\.[345]\./
    # bundler was added in ruby-2.6
    assert_match(/Bundler version/, `bundle --version`)
    assert_match(/Bundler version/, `bundler --version`)
  end

  def test_gem
    assert_match(/\d+\.\d+\.\d+/, `gem --version`)
  end

  def test_erb
    res = IO.popen("erb", "w+") do |io|
      io.write "a<%=1+2%>b"
      io.close_write
      io.read
    end
    assert_match(/a3b/, res)
  end

  def test_irb
    res = IO.popen("irb", "w+") do |io|
      io.write "'ab'*3\n"
      io.close_write
      io.read
    end
    assert_match(/\"ababab\"/, res)
  end

  def test_rake
    assert_match(/rake, version/, `rake --version`)
  end

  def test_rdoc
    assert_match(/\d+\.\d+\.\d+/, `rdoc --version`)
  end

  def test_ri
    assert_match(/A String object holds/, `ri String 2>&1`)
  end

  def test_rubyw
    FileUtils.rm_f("test_rubyw.log")
    system(%q[rubyw -e "File.write('test_rubyw.log','xy')"])
    assert_equal("xy", File.read("test_rubyw.log"))
  end
end
