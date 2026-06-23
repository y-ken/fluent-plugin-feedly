require 'helper'
require 'tempfile'

class FeedlyStateStoreTest < Test::Unit::TestCase
  StateStore = Fluent::FeedlyInput::StateStore

  def setup
    @tmp = Tempfile.new(['feedly_state', '.yml'])
    @path = @tmp.path
    @tmp.close
    @tmp.unlink # start from a non-existent path
  end

  def teardown
    File.delete(@path) if File.exist?(@path)
  end

  def test_missing_file_starts_empty
    store = StateStore.new(@path)
    assert_equal({}, store.get('continuation'))
  end

  def test_round_trip_persists_symbol_keyed_state
    store = StateStore.new(@path)
    store.set('continuation', { id: 'cont-123', subscribe_categories_hash: 'hash-abc' })
    store.update!

    # Re-read from disk: this exercises File.exist? and the Psych 4 safe loader,
    # which both used to raise on modern Ruby.
    reloaded = StateStore.new(@path)
    assert_equal({ id: 'cont-123', subscribe_categories_hash: 'hash-abc' },
                 reloaded.get('continuation'))
  end

  def test_empty_file_is_treated_as_empty_state
    File.open(@path, 'w') { |f| f.write('') }
    store = StateStore.new(@path)
    assert_equal({}, store.get('continuation'))
  end

  def test_invalid_state_file_raises
    File.open(@path, 'w') { |f| f.write(YAML.dump('not-a-hash')) }
    assert_raise(RuntimeError) { StateStore.new(@path) }
  end
end
