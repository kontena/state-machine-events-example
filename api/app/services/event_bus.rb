class EventBus
  class << self
    def publish_event(event)
      routing_key = "#{event.entity_type.downcase}.#{event.event}"
      eventbus_exchange = ENV['EVENTBUS_EXCHANGE'] || 'entity_events'

      data = event.attributes
      data['id'] = data.delete('_id').to_s
      data['entity_id'] = data['entity_id'].to_s
      payload = data.to_json

      channel_pool.with do |channel|
        channel.
          topic(eventbus_exchange, durable: true).
          publish(payload, routing_key: routing_key)
      end
    end

    def replay_events
      StateTransitionEvent.order(created_at: 1).all.each do |e|
        puts e.attributes
        publish_event(e)
      end

      true
    end

    private

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
  end
end