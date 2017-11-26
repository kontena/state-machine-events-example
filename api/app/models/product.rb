class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  field :name, type: String
  field :state, type: String
  field :price, type: Integer
  field :inventory, type: Integer, default: 0

  index({ name: 1 }, { unique: true })

  aasm(column: :state, with_klass: StateTracking) do
    enable_tracking!

    state :initialized, intitial: true
    state :created
    state :in_stock
    state :out_of_stock
    state :discountinued

    event :create do
      transitions :from => :initialized,
                  :to => :created
    end

    event :add_inventory do
      transitions :from => [:created, :in_stock, :out_of_stock],
                  :to => :in_stock
    end

    event :reduce_inventory do
      transitions :from => :in_stock,
                  :to => :in_stock,
                  :guard => :has_inventory?

      transitions :from => :in_stock,
                  :to => :out_of_stock
    end

    event :discontinue do
      transitions :from => [:created, :in_stock, :out_of_stock],
                  :to => :discountinued
    end
  end

  def has_inventory?
    inventory > 0
  end
end
