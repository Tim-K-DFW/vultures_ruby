require 'pry'
require 'date'

Dir["Classes/*.rb"].each { |file| load file }

table = PriceTable.new
