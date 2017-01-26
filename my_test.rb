require 'test/unit'
require_relative 'app'

class MyTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  def test_fetch_state
    myapp = fetch("https://api.github.com/repos/qualisystems/vcentershell/issues/2",
                  'state',
                  {user: 'qualisystems', repo: 'vcentershell', auth: 'aaa', issue: '2'})

    assert_equal(myapp, "closed")
  end

  def test_fetch_milestone
    myapp = fetch("https://api.github.com/repos/qualisystems/vcentershell/issues/832",
                  'milestone.title',
                  {user: 'qualisystems', repo: 'vcentershell', auth: 'aaa', issue: '832'})

    assert_equal(myapp, '7.2 Internal Release 5')
  end

  def test_fetch_no_milestone
    myapp = fetch("https://api.github.com/repos/qualisystems/vcentershell/issues/2",
                  'milestone.title',
                  {user: 'qualisystems', repo: 'vcentershell', auth: 'aaa', issue: '2'})

    assert_equal(myapp, 'No milestone')
  end


end