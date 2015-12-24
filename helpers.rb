def time_back(ending_period, increment)
  if increment == :year
    ending_period.gsub(/^\d{4}/, (ending_period[0..3].to_i - 1).to_s)
  else
    raise Exception.new('This increment not implemented yet.')
  end
end

def standard_deviation(arg)
  mean = arg.inject{|sum,x| sum + x } / arg.size.to_f
  (arg.inject(0){|sum,x| sum + ((x-mean) ** 2) } / arg.size) ** 0.5
end

def another_run?
  $stdout.sync = true
  print 'Another run? ("y" for yes) => '
  gets.chomp == 'y'
end

def engine_params
  $stdout.sync = true
  result = {}

  print 'Market cap FLOOR in $mm (minimum 50, default 100) => '
  input = gets.chomp
  result['market_cap_floor'] = input == '' ? 100 : input.to_i

  print 'Market cap CEILING in $mm (minimum 50, default 200) => '
  input = gets.chomp
  result['market_cap_ceiling'] = input == '' ? 200 : input.to_i

  print 'Number of stocks in portfolio (default 20) => '
  input = gets.chomp
  result['position_count'] = input == '' ? 20 : input.to_i

  print 'Initial balance in $ (default 1,000,000, no commas) => '
  input = gets.chomp
  result['initial_balance'] = input == '' ? 1000000 : input.to_i

  result['rebalance_frequency'] = 'annual'
  result['start_date'] = '1993-12-31'
  result
end