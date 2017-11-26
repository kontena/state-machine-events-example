module Products
  class Update < Mutations::Command
    required do
      model :product
      integer :adjust_inventory
    end

    def validate
      if adjust_inventory == 0
        return add_error(:adjust_inventory, :invalid, 'Inventory adjustment factory cannot be zero')
      end

      if adjust_inventory < 0 && ( (product.inventory + adjust_inventory) < 0 )
        return add_error(:adjust_inventory, :invalid, 'Cannot set inventory below zero')
      end

      if product.discountinued?
        return add_error(:product, :discountinued, 'Product is discountinued')
      end
    end

    def execute
      product.inventory += adjust_inventory
      product.save

      if adjust_inventory > 0
        product.add_inventory!
      else
        product.reduce_inventory!
      end

      product
    end
  end
end
