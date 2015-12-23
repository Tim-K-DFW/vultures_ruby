require 'pry'
require 'date'
load 'helpers.rb'

Dir["Classes/*.rb"].each { |file| load file }

# will update to get user input later
def engine_params
  result = {}
  result["rebalance_frequency"] = 'annual'
  result["market_cap_floor"] = 50
  result["market_cap_ceiling"] = 50000
  result["start_date"] = '1993-12-31'
  result["initial_balance"] = 1000000
  result["position_count"] = 30
  result
end

data_table = PriceTable.new
results = Engine.new(data_table, engine_params).perform

binding.pry