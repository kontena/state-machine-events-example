module Products
  class Create < Mutations::Command
    required do
      string :name
      integer :price
    end

    optional do
      integer :initial_inventory, default: 0
    end

    def validate
      if initial_inventory < 0
        add_error(:initial_inventory, :invalid, 'Initial inventory cannot be negative')
      end

      if Product.find_by(name: name)
        add_error(:product, :already_exists, 'A Product with this name already exists')
      end
    end

    def execute
      product = create_product
      return unless product

      product.create!
      product.add_inventory! unless initial_inventory == 0
      product
    end

    def create_product
      product = Product.create(
        name: name,
        price: price,
        inventory: initial_inventory
      )

      if product.errors.size > 0
        product.errors.each do |key, message|
          add_error(key, :invalid, message)
        end

        return
      end

      product
    end
  end
end
