class ScoreCalculator
  attr_accessor :stocks

  def initialize(args)
    array = PricePoint.where("period = ? AND market_cap >= ? AND market_cap <= ? AND price > 0 AND delisted = FALSE AND ltm_ebit > 0 AND roc > 0 AND earnings_yield > 0", args[:period], args[:market_cap_floor] || 50, args[:market_cap_ceiling] || 2000000)
    @stocks = []
    array.each { |element| @stocks << element.attributes }
  end

  def assign_scores
    assign_earnings_yield_scores
    assign_roc_scores
    assign_total_scores
  end

  private

  def assign_earnings_yield_scores
    @stocks.sort_by { |h| -h["earnings_yield"] }.each_with_index{ |v, i| v["ey_score"] = i + 1 }
  end

  def assign_roc_scores
    @stocks.sort_by { |h| -h["roc"] }.each_with_index{ |v, i| v["roc_score"] = i + 1 }
  end

  def assign_total_scores
    @stocks.each { |stock| stock["total_score"] = stock["roc_score"] + stock["ey_score"] }
    @stocks.sort_by! { |h| h["total_score"] }
  end
end
