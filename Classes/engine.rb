class Engine
  include ActiveModel::Model
  require 'date'

  attr_reader :parameters, :portfolio
  attr_accessor :rebalance_frequency, :market_cap_floor, :market_cap_ceiling, :initial_balance, :use_dual_momentum, :background, :test_run, :start_date, :single_period

  def initialize(parameters=nil)
    @parameters = parameters
  end

  def perform(parameters=nil, pusher_channel)
    @parameters = parameters

    @portfolio = Portfolio.new(
      position_count: parameters["position_count"],
      initial_balance: parameters["initial_balance"],
      start_date: parameters["start_date"],
      rebalance_frequency: parameters["rebalance_frequency"],
      pusher_channel: pusher_channel
    )

    PricePoint.all_periods(development: parameters['test_run'] == '1' ? true : false, single_period: parameters['single_period'], start_date: parameters['start_date']).each do |period|
      
      period = period.to_s
      Pusher.trigger(pusher_channel, 'update', { message: "Processing #{period} - ranking stocks" })
      
      current_market_data = ScoreCalculator.new(
        market_cap_floor: parameters["market_cap_floor"], 
        market_cap_ceiling: parameters["market_cap_ceiling"],
        period: period
      ).assign_scores

      Pusher.trigger(pusher_channel, 'update', { message: "Processing #{period} - building portfolio" })
      @portfolio.carry_forward(period) unless period == parameters["start_date"]
      target_portfolio = TargetPortfolio.new(
        current_portfolio_balance: @portfolio.as_of(period)[:total_market_value],
        position_count: @portfolio.position_count,
        current_market_data: current_market_data,
        parameters: parameters
        ).build(pusher_channel)
      @portfolio.rebalance(new_period: period, target: target_portfolio, parameters: parameters)
    end

    output = ReportGenerator.new(portfolio, parameters).generate(pusher_channel).to_json
    Result.all.destroy_all
    Result.create(result_string: output)
    Pusher.trigger(pusher_channel, 'update', { progress: 100, message: 'Done!' })
    self
  end
end
