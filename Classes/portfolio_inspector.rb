class PortfolioInspector
  attr_reader :portfolio, :report_date

  def initialize(portfolio, report_date)
    @portfolio = portfolio
    @report_date = report_date
    binding.pry if report_date == nil
  end

  def snapshot
    result = {}
    result[:delisted_positions] = delisted_positions
    result[:positions] = portfolio.periods[report_date][:positions].dup
    result[:positions].delete_if{|k,v| result[:delisted_positions].keys.include?(k)}
    result[:cash_ex_delisting_proceeds] = portfolio.periods[report_date][:cash]
    result[:cash_from_delisting] = delisting_proceeds(result[:delisted_positions])
    result[:cash_total] = result[:cash_ex_delisting_proceeds] + result[:cash_from_delisting]
    result[:market_value_of_positions] = positions_value(result[:positions])
    result[:total_market_value] = (result[:market_value_of_positions] + result[:cash_total]).round(2)
    result
  end

  def delisted_positions
    begin
      portfolio.periods[report_date][:positions].select{ |k, v| v.delisted? }
    rescue
      binding.pry
    end
  end

  def delisting_proceeds(delisted_positions)
    (delisted_positions.inject(0) {|total, position| total + position[1].market_value }).round(2)
  end

  def positions_value(survived_positions)
    (survived_positions.inject(0) {|total, position| total + position[1].market_value }).round(2)
  end
end
