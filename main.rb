require 'pry'
require 'date'
require 'json'
load 'helpers.rb'

Dir["Classes/*.rb"].each { |file| load file }

# will update to get user input later
def engine_params
    result = {}
    result["rebalance_frequency"] = 'annual'
    result["market_cap_floor"] = 100
    result["market_cap_ceiling"] = 200
    result["start_date"] = '1993-12-31'
    result["initial_balance"] = 1000000
    result["position_count"] = 20
    result
  end

if ARGV.include?('output_only')
  ReportPrinter.new(JSON.parse(File.read('result.txt'))).generate
else
  data_table = PriceTable.new
  results = Engine.new(data_table, engine_params).perform
  File.open("result.txt", "w") { |file| file.write(results.to_json) }
  puts 'Results saved to RESULT.TXT!'
end
