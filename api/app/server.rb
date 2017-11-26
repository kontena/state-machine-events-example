ENV['RACK_ENV'] ||= 'development'

require 'roda'
require 'json'
require 'aasm'
require 'bunny'
require 'mongoid'
require 'mutations'
require 'connection_pool'
require_relative './helpers/request_helper'
require_relative './helpers/state_tracking'
require_relative './models/product'
require_relative './models/state_transition_event'
require_relative './mutations/products/create'
require_relative './mutations/products/delete'
require_relative './mutations/products/update'
require_relative './services/event_bus'

Mongoid.load!("./mongoid.yml", ENV['RACK_ENV'])

class Server < Roda
  plugin :all_verbs
  plugin :json_parser
  plugin :indifferent_params
  plugin :params_capturing
  plugin :json

  include RequestHelper

  route do |r|
    r.on 'health' do
      { status: 'OK' }
    end

    r.on 'products' do
      r.get do
        r.is do
          handle_query do
            Product.all.map { |p| p }
          end
        end

        r.on(:id) do
          handle_query do
            Product.find(request.params[:id])
          end
        end
      end

      r.post do
        handle_command do
          Products::Create.run(
            name: request.params[:name],
            price: request.params[:price],
            initial_inventory: request.params[:initial_inventory]
          )
        end
      end

      r.put do
        r.on(:id) do
          handle_command do
            Products::Update.run(
              product: Product.find(request.params[:id]),
              adjust_inventory: request.params[:adjust_inventory]
            )
          end
        end
      end

      r.delete do
        r.on(:id) do
          handle_command do
            Products::Delete.run(
              product: Product.find(request.params[:id])
            )
          end
        end
      end
    end
  end
end