# -*- encoding: utf-8 -*-

module Fluent
  class FeedlyInput < Fluent::Input
    Plugin.register_input('feedly', self)

    config_param :access_token, :string
    config_param :tag, :string
    config_param :run_interval, :time, :default => '10m'
    config_param :subscribe_categories, :array, :default => ['global.all']
    config_param :state_file, :string

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

      @client = Feedlr::Client.new(
        oauth_access_token: @access_token,
        #sandbox: false,
        #logger: Logger.new(STDOUT) #debug use
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
      #未読記事を順次クロールしてemitする
      #カテゴリ毎にポジション情報を保持する必要がある
      log.info "start crawling"
      @subscribe_categories.each do |category_name|
        category_id = "user/#{@profile_id}/category/#{category_name}"
        continuation = get_continuation
        loop {
          cursor = @client.stream_entries_contents(category_id, {
            count: 3000, 
            continuation: continuation
          })
          cursor.items.each do |item|
            Engine.emit(@tag, Engine.now, item)
          end
          continuation = cursor.continuation
          break if continuation.nil?
          set_continuation(continuation)
        }
      end
    end

    def subscribe_categories_hash
      Digest::SHA512.digest(@subscribe_categories.sort.join(''))
    end

    def set_continuation(continuation)
      @state_store.set("continuation", {
        subscribe_categories_hash: subscribe_categories_hash,
        continuation: continuation
      })
      @state_store.update!
    end

    def get_continuation
      record = @state_store.get('continuation')
      if subscribe_categories_hash == record[:subscribe_categories_hash]
        return record[:continuation]
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
