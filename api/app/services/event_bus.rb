class EventBus
  class << self
    def publish_event(event, prefix: '')

      routing_key = build_routing_key(event, prefix)
      payload = build_event_payload(event)

      channel_pool.with do |channel|
        channel.
          topic(eventbus_exchange, durable: true).
          publish(payload, routing_key: routing_key)
      end
    end

    def replay_events(prefix: '')
      puts "Replaying all events (prefix: '#{prefix}')"

      StateTransitionEvent.order(created_at: 1).all.each do |e|
        publish_event(e, prefix: prefix)
      end

      true
    end

    private
      def build_routing_key(event, prefix)
        routing_key_prefix = prefix.to_s.strip
        routing_key = routing_key_prefix.empty? ? "" : "#{routing_key_prefix}."
        routing_key += "entity_event.#{event.entity_type.downcase}.#{event.event}"
        puts "* publishing event to #{eventbus_exchange} => #{routing_key}"
        routing_key
      end

      def build_event_payload(event)
        data = event.attributes.clone

        data['id'] = data.delete('_id').to_s
        data['entity_id'] = data['entity_id'].to_s

        pp data
        puts ""
        data.to_json
      end

      def channel_pool
        return @pool if @pool

        uri = ENV['RABBITMQ_URI'] || 'amqp://localhost'
        size = ( ENV['CHANNEL_POOL_SIZE'] || 5 ).to_i
        timeout = ( ENV['CHANNEL_POOL_TIMEOUT'] || 60 ).to_i

        @conn = Bunny.new(uri)
        @conn.start

        @pool = ConnectionPool.new(size: size, timeout: timeout) {
          @conn.create_channel
        }
      end

      def eventbus_exchange
        ENV['EVENTBUS_EXCHANGE'] || 'entity_events'
      end
  end
end