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
