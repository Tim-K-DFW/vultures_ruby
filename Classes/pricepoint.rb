class PricePoint
  attr_accessor :cid, :period, :market_cap, :net_ppe, :nwc, :ltm_ebit, :ev, :earnings_yield, :roc, :price, :delisted, :delisting_date

  def initialize(args)
    @cid = args[:cid]
    @period = args[:period]
    @market_cap = args[:market_cap]
    @net_ppe = args[:net_ppe]
    @nwc = args[:nwc]
    @ltm_ebit = args[:ltm_ebit]
    @ev = args[:ev]
    @earnings_yield = args[:earnings_yield]
    @roc = args[:roc]
    @price = args[:price]
    @delisted = args[:delisted]
    @delisting_date = args[:delisting_date] || ''
  end

  # def self.all_periods(args)
  #   # select(:period).map(&:period).uniq
  #   if args[:single_period] == '1'
  #     start_date = Date.strptime(args[:start_date], '%Y-%m-%d')
  #     [start_date.to_s, (start_date+1.year).to_s]
  #   else
  #     range = args[:development] == true ? (1993..2001).to_a : (1993..2014).to_a
  #     result = []
  #     range.each { |year| result << "#{year}-12-31" }
  #     result
  #   end
  # end
end