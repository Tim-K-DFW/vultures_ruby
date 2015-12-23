require 'csv'

class PriceTable
  attr_reader :main_table, :size

  def initialize
    @main_table = {}
    @size = 0
    load
  end

  def add(item)
    new_id = (item.cid + '$' + item.period.to_s).to_sym
    main_table[new_id] = item
    @size += 1
  end

  def subset(args)
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

  def where(args)
    main_table[(args[:cid] + '$' + args[:period]).to_sym]
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
  
  private

  def load
    start_time = Time.now

    periods = []
    (1993..2014).each { |year| periods << "12/31/#{year}" }

    company_table = CompanyTable.new

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
        new_entry = PricePoint.new(new_entry_fields)
        self.add(new_entry)
      end   # all PricePoints for this CID filled

      company_table.add(Company.new(name: row[0], cid: row[2], ticker: row[3]))
    end  # all PricePoints filled

    puts "Data loaded! Time spent: #{(Time.now - start_time).round(2)} seconds."
  end
end
