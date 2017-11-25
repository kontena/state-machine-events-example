module Products
  class Delete < Mutations::Command
    required do
      model :product
    end

    def execute
      product.discontinue! if product.may_discontinue?
      product
    end
  end
end
