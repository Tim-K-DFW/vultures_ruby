class Engine
  require 'date'

  attr_reader :parameters, :portfolio, :table, :rebalance_frequency, :market_cap_floor, :market_cap_ceiling, :initial_balance, :start_date, :data_table

  def initialize(data_table, parameters=nil)
    @data_table = data_table
    @parameters = parameters
  end

  def perform
    puts '--------------------------------------------------------'
    puts 'Trading...'
    start_time = Time.now

    @portfolio = Portfolio.new(
      data_table, {
      position_count: parameters["position_count"],
      initial_balance: parameters["initial_balance"],
      start_date: parameters["start_date"],
      rebalance_frequency: parameters["rebalance_frequency"]
    })

    data_table.all_periods.each do |period|
      
      period = period.to_s
      puts "Processing #{period}..."
      # puts "Processing #{period} - ranking stocks"
      
      current_market_data = ScoreCalculator.new(
        data_table,
        { market_cap_floor: parameters["market_cap_floor"], 
        market_cap_ceiling: parameters["market_cap_ceiling"],
        period: period }
      ).assign_scores

      # puts "Processing #{period} - building portfolio"
      @portfolio.carry_forward(period) unless period == parameters["start_date"]
      target_portfolio = TargetPortfolio.new(
        current_portfolio_balance: @portfolio.as_of(period)[:total_market_value],
        position_count: @portfolio.position_count,
        current_market_data: current_market_data,
        parameters: parameters
        ).build
      @portfolio.rebalance(new_period: period, target: target_portfolio, parameters: parameters)
    end
    puts '--------------------------------------------------------'
    puts "Trading complete! Time spent: #{(Time.now - start_time).round(2)} seconds."
    puts '--------------------------------------------------------'

    ReportGenerator.new(data_table, portfolio, parameters).generate
  end
end
