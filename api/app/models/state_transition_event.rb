class StateTransitionEvent
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :entity_type, type: String
  field :entity_id, type: BSON::ObjectId
  field :entity_attributes, type: Hash
  field :event, type: String
  field :from, type: String
  field :to, type: String
end