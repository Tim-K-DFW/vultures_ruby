require 'pry'
require 'csv'
require 'date'

class IMPricePoint
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

class IMCompany
  attr_accessor :name, :cid, :ticker

  def initialize(args)
    @name = args[:name]
    @cid = args[:cid]
    @ticker = args[:ticker]
  end
end

class IMCompanyTable
  attr_accessor :main_table, :size

  def initialize
    @main_table = {}
    @size = 0
  end

  def add(item)
    main_table[(item.cid).to_sym] = item
    @size += 1
  end
end

class IMTable
  attr_accessor :main_table, :size

  def initialize
    @main_table = {}
    @size = 0
  end

  def add(item)
    new_id = (item.cid + '$' + item.period.to_s).to_sym
    main_table[new_id] = item
    @size += 1
  end

  def screening_subset(args)
    result = []
      main_table.each do |key, value|
        if (value.period == args[:period] &&
            value.market_cap >= args[:cap_floor] &&
            value.market_cap <= args[:cap_ceiling] &&
            value.price > 0 &&
            value.delisted == FALSE &&
            value.ltm_ebit > 0 &&
            value.roc > 0 &&
            value.earnings_yield > 0 &&
            value.roc < 10)
          result << value
        end
      end
    result
  end

  def where(arg)
    main_table[arg]
  end

  def keys
    main_table.keys
  end

  def first
    main_table[keys.first]
  end

  def last
    main_table[keys.last]
  end
end

start_time = Time.now
counter = 0

periods = []
(1993..2014).each { |year| periods << "12/31/#{year}" }

price_point_table = IMTable.new
company_table = IMCompanyTable.new

CSV.foreach("data - annual since 1993.csv", headers: true, encoding: 'ISO-8859-1') do |row|
  for i in 0..periods.size - 1
    ebit = row[i * 6 + 5].to_f.round(3)
    ev = row[i * 6 + 6].to_f.round(3)
    net_ppe = row[i * 6 + 7].to_f.round(3)
    nwc = row[i * 6 + 8].to_f.round(3)
    market_cap = row[i * 6 + 4].to_f.round(3)
    price = row[i * 6 + 9].to_f.round(2)
    new_entry_fields = { cid: row[2],
      period: (Date.strptime(periods[i], '%m/%d/%Y')).to_s,
      market_cap: market_cap,
      net_ppe: net_ppe,
      nwc: nwc,
      ltm_ebit: ebit,
      ev: ev,
      earnings_yield: ebit > 0 ? (ebit / ev).round(3) : 0,
      roc: ebit > 0 ? (ebit / (net_ppe + nwc)).round(3) : 0,
      price: price,
      delisted: false }
    
    delisted_check = /(\d+\/\d+\/\d+)/.match(row[i * 6 + 9])
    if delisted_check
      new_entry_fields[:delisted] = true
      new_entry_fields[:delisting_date] = (Date.strptime(delisted_check[1], '%m/%d/%Y')).to_s
    end
    new_entry = IMPricePoint.new(new_entry_fields)
    price_point_table.add(new_entry)
  end   # all PricePoints for this CID filled

  new_company = IMCompany.new(name: row[0], cid: row[2], ticker: row[3])
  company_table.add(new_company)
  
  counter += 1
  # printf "%-80s %-25s %-22s\n", "Added #{row[0]}", "#{counter} companies total", "#{(Time.now - start_time).round(2)} seconds spent."
end  # all PricePoints filled
puts "Time to fill all data points and companies: #{(Time.now - start_time).round(2)} seconds."

puts 'Now measuring WHERE time...'
start_time = Time.now
test_array = price_point_table.screening_subset(period: '1993-12-31', cap_floor: 50, cap_ceiling: 200)
puts "Time to do a typical SELECT: #{(Time.now - start_time).round(2)} seconds."
binding.pry


# PricePoint.where(cid: 'sp500').each { |item| item.update(delisted: true) }
# puts 'All SP500 entries set to DELISTED.'

# 0 company
# 1 exchange no need
# 2 id
# 3 ticker

# 4 market cap
# 5 EBIT
# 6 EV
# 7 net PPE
# 8 NWC
# 9 price (including delisting info, if any)
