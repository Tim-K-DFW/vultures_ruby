require 'pry'
require 'date'
require 'json'
load 'helpers.rb'

Dir["Classes/*.rb"].each { |file| load file }

if ARGV.include?('output_only')
  ReportPrinter.new(JSON.parse(File.read('result.txt'))).generate
else
  data_table = PriceTable.new
  begin
    results = Engine.new(data_table, engine_params).perform
    File.open("result.txt", "w") { |file| file.write(results.to_json) }
    puts 'JSON results saved to result.txt.'
    filename = ReportPrinter.new(results).generate
    puts "Full report saved to #{filename}."
    puts '--------------------------------------------------------'
  end until !another_run?
end
