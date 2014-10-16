# -*- encoding: utf-8 -*-

module Fluent
  class FeedlyInput < Fluent::Input
    Plugin.register_input('feedly', self)

    config_param :access_token, :string
    config_param :state_file, :string
    config_param :tag, :string

    config_param :subscribe_categories, :array, :default => ['global.all']
    config_param :run_interval, :time, :default => 60*10 #10m
    config_param :fetch_count, :integer, :default => 20
    config_param :fetch_time_range, :time, :default => 60*60*24*3 #3d
    config_param :fetch_time_range_on_startup, :time, :default => 60*60*24*14 #2w
    config_param :enable_sandbox, :bool, :default => false

    unless method_defined?(:log)
      define_method(:log) { $log }
    end

    def initialize
      require 'feedlr'
      require 'digest/sha2'

      super
    end

    def configure(conf)
      super

      if not @fetch_count >= 20 && @fetch_count <= 10000
        raise Fluent::ConfigError, "Feedly: fetch_count param (#{@fetch_count}) should be between 20 and 10000."
      end

      @client = Feedlr::Client.new(
        oauth_access_token: @access_token,
        sandbox: @enable_sandbox,
      )
    end

    def start
      @profile_id = @client.user_profile.id
      @state_store = StateStore.new(@state_file)
      @thread = Thread.new(&method(:run))
    end

    def shutdown
      Thread.kill(@thread)
    end

    def run
      @initial_loop = true
      loop do
        begin
          fetch
        rescue => e
          log.error "Feedly: unexpected error has occoured.", :error => e.message, :error_class => e.class
          log.error_backtrace e.backtrace
          sleep @run_interval
          retry
        end
        sleep @run_interval
      end
    end

    def fetch
      @subscribe_categories.each do |category_name|
        category_id = "user/#{@profile_id}/category/#{category_name}"
        fetch_time_range = get_fetch_time_range
        loop {
          request_option = { count: @fetch_count, continuation: get_continuation_id, newerThan: fetch_time_range }
          cursor = @client.stream_entries_contents(category_id, request_option)
          cursor.items.each do |item|
            Engine.emit(@tag, Engine.now, item)
          end
          log.debug "Feedly: fetched articles.", articles: cursor.items.size, request_option: request_option
          set_continuation_id(cursor.continuation)
          break if get_continuation_id.nil?
        }
      end
    end

    def get_fetch_time_range
      if @initial_loop
        @initial_loop = false
        range = @fetch_time_range_on_startup
      else
        range = @fetch_time_range
      end
      return (Time.now.to_i - range ) * 1000
    end

    def subscribe_categories_hash
      Digest::SHA512.digest(@subscribe_categories.sort.join(''))
    end

    def set_continuation_id(continuation_id)
      @state_store.set("continuation", {
        id: continuation_id,
        subscribe_categories_hash: subscribe_categories_hash
      })
      @state_store.update!
    end

    def get_continuation_id
      record = @state_store.get('continuation')
      if subscribe_categories_hash == record[:subscribe_categories_hash]
        return record[:id]
      else
        return nil
      end
    end

    # implementation has copied from its code.
    # https://github.com/fluent/fluent-plugin-sql/blob/master/lib/fluent/plugin/in_sql.rb
    class StateStore
      def initialize(path)
        @path = path
        if File.exists?(@path)
          @data = YAML.load_file(@path)
          if @data == false || @data == []
            # this happens if an users created an empty file accidentally
            @data = {}
          elsif !@data.is_a?(Hash)
            raise "state_file on #{@path.inspect} is invalid"
          end
        else
          @data = {}
        end
      end

      def set(key, data)
        @data.store(key.to_sym, data)
      end

      def get(key)
        @data[key.to_sym] ||= {}
      end

      def update!
        File.open(@path, 'w') {|f|
          f.write YAML.dump(@data)
        }
      end
    end
  end
end
