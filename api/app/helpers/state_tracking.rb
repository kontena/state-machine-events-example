class StateTracking < AASM::Base
  def enable_tracking!
    klass.instance_eval do
      include StateTracking::WriteStateWithTracking
    end

    klass.class_eval do
      aasm :with_klass => StateTracking do
        after_all_transitions Proc.new {|*args|
          @aasm_events ||= []
          @aasm_events << {
            from: aasm.from_state,
            to: aasm.to_state,
            event: aasm.current_event.to_s.chomp('!')
          }
        }
      end
    end
  end

  module WriteStateWithTracking
    def aasm_write_state(state, name=:default)
      success = super(state, name)

      if success
        @aasm_events.each do |e|
          entity_attributes = self.attributes.keys.reduce({}) { |result, key|
            if !['_id', 'id', self.class.aasm.attribute_name.to_s].include?(key)
              result[key] = self.attributes[key]
            end

            result
          }

          EventBus.publish_event(
            StateTransitionEvent.create(
              entity_type: self.class,
              entity_id: self.id,
              entity_attributes: entity_attributes,
              event: e[:event],
              from: e[:from],
              to: e[:to]
            )
          )
        end
      end

      @aasm_events.clear

      success
    end
  end
end