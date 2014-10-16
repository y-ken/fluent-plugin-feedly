require 'helper'

class FeedlyInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    access_token     YOUR_ACCESS_TOKEN
    state_file       /var/log/td-agent/feedly.state
    tag              input.feedly
    run_interval     30m
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::FeedlyInput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    d = create_driver(CONFIG)
    assert_equal 'YOUR_ACCESS_TOKEN', d.instance.access_token
    assert_equal '/var/log/td-agent/feedly.state', d.instance.state_file
    assert_equal 1800, d.instance.run_interval
    assert_equal 'input.feedly', d.instance.tag
  end
end

