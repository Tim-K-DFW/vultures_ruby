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

  def attributes
    result = {}
    result["cid"] = cid
    result["period"] = period
    result["market_cap"] = market_cap
    result["net_ppe"] = net_ppe
    result["nwc"] = nwc
    result["ltm_ebit"] = ltm_ebit
    result["ev"] = ev
    result["earnings_yield"] = earnings_yield
    result["roc"] = roc
    result["price"] = price
    result
  end
end