module RequestHelper
  def handle_command(input: nil, &block)
    try_handle do
      outcome = yield

      if outcome.success?
        get_attributes(outcome.result)
      else
        response.status = 422
        outcome.errors.message
      end
    end
  end

  def handle_query(&block)
    try_handle do
      outcome = yield
      return get_attributes(outcome) if outcome

      not_found
    end
  end

  private

  def try_handle(&block)
    yield
  rescue AASM::InvalidTransition => ae
    puts "#{ae.class}:  #{ae.message}"
    puts ae.backtrace.join("\n\t")
    response.status = 422
    { :error => ae.message }
  rescue => e
    puts "#{e.class}:  #{e.message}"
    puts e.backtrace.join("\n\t")
    response.status = 500
    { :error => 'Server Error' }
  end

  def not_found
    response.status = 404
    { :error => 'Not Found'}
  end

  def get_attributes(result)
    if result.is_a?(Array)
      result.map { |x| get_attributes(x) }
    elsif result.is_a?(Mongoid::Document)
      attributes = result.attributes
      attributes['id'] = attributes.delete('_id').to_s
      attributes
    else
      result
    end
  end
end