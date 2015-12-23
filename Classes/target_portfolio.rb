class TargetPortfolio
  attr_accessor :positions

  def initialize(args)
    @current_portfolio_balance = args[:current_portfolio_balance]
    @position_count = args[:position_count]
    @market_data = args[:current_market_data]
    @parameters = args[:parameters]
    @positions = {}
  end

  def build
    build_initial_positions
    spend_balance
  end

  def cost
    positions.values.to_a.inject(0) { |total, element| total + element[:cost] }.round(2)
  end

  def cash_balance
    @current_portfolio_balance - cost
  end

  def hold_list
    positions.keys
  end

  # private

  def build_initial_positions
    max_allocation_per_position = @current_portfolio_balance / @position_count
    @market_data.sort_by! {|h| h['total_score'] }
    @position_count.times do |i|
      begin
        positions[@market_data[i]['cid'].to_sym] = this_position = {}
      rescue
        binding.pry
      end
      this_position[:price] = @market_data[i]['price']
      this_position[:total_score] = @market_data[i]['total_score']
      this_position[:share_count] = (max_allocation_per_position / this_position[:price]).floor
      this_position[:cost] = (this_position[:share_count] * this_position[:price]).round(2)
    end
  end

  def spend_balance
    positions.each do |cid, position|
      if cash_balance > position[:price]
        additional_shares = (cash_balance / position[:price]).floor
        position[:share_count] += additional_shares
        position[:cost] = (position[:cost] + additional_shares * position[:price]).round(2)
      end
    end
  end # spend_balance
end
