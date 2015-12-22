class ReportGenerator
  attr_reader :portfolio, :parameters
  attr_accessor :resuts, :pusher_channel

  def initialize(portfolio, parameters)
    @portfolio = portfolio
    @parameters = parameters
    @results = {}
  end

  def generate(pusher_channel)
    @pusher_channel = pusher_channel
    @results['parameters'] = parameters
    @results['performance'] = generate_performance
    @results['aggregated'] = aggregated_performance(@results['performance'])
    @results['positions'] = generate_positions
    @results
  end

  def generate_performance
    result = []
    portfolio.periods.each do |end_date, state|
      Pusher.trigger(pusher_channel, 'update', { message: "Building reports - Performance for the period of #{end_date}" })
      next if end_date == portfolio.periods.first[0]
      this_period = {}
      this_period['date'] = end_date
      this_period['balance'] = portfolio.as_of(end_date)[:total_market_value]
      this_period['sp500_value'] = PricePoint.where(cid: 'sp500', period: end_date).first.price
      this_period['by_period'] = relative_return(single_period_start(end_date), end_date)
      this_period['annualized'] = annualized_return(this_period['by_period'])
      this_period['cumulative_cy'] = relative_return(cumulative_cy_start(end_date), end_date)
      this_period['rolling_12_months'] = relative_return(rolling_12_months_start(end_date), end_date)
      result << this_period
    end
    result
  end

  def aggregated_performance(by_period_results)
    Pusher.trigger(pusher_channel, 'update', { message: 'Building reports - Aggregated performance' })
    result = {}
    start_date = result['start_date'] = portfolio.periods.first[0]
    end_date = result['end_date'] = portfolio.periods.keys.last
    result['table'] = {}
    result['table']['a_geometric'] = geometric_average(start_date, end_date)
    result['table']['b_rithmetic'] = arithmetic_average(start_date, end_date, by_period_results)
    result['table']['c_st_deviation_by_period'] = st_deviation_by_period(start_date, end_date, by_period_results)
    result['table']['d_st_deviation_annualized'] = st_deviation_annualized(start_date, end_date, by_period_results)
    result['table']['e_sharpe'] = sharpe(result['table'])
    result['table']['f_max_drawdown'] = max_drawdown_hash(parameters["initial_balance"], by_period_results)
    result
  end

  def generate_positions
    result = []
    portfolio.periods.each do |date, data|
      Pusher.trigger(pusher_channel, 'update', { message: "Building reports - Positions as of #{date}" })
      this_period = {}
      this_period['start_date'] = date
      end_date = this_period['end_date'] = portfolio.periods.keys[portfolio.periods.keys.index(date) + 1] || ''
      this_period['positions'] = []

      data[:positions].each do |cid, position|
        this_position = {}
        this_position['cid'] = cid.to_s
        this_position['company_name'] = Company.where(cid: cid).first.name || 'Temporary Name Inc.'
        this_position['market_cap'] = PricePoint.where(cid: cid, period: date).first.market_cap.round(1)
        this_position['ltm_ebit'] = PricePoint.where(cid: cid, period: date).first.ltm_ebit.round(1)
        this_position['ev'] = PricePoint.where(cid: cid, period: date).first.ev.round(1)
        this_position['capital'] = (PricePoint.where(cid: cid, period: date).first.nwc + PricePoint.where(cid: cid, period: date).first.net_ppe).round(1)
        this_position['earnings_yield'] = PricePoint.where(cid: cid, period: date).first.earnings_yield.round(4)
        this_position['roc'] = PricePoint.where(cid: cid, period: date).first.roc.round(4)
        this_position['share_count'] = position.share_count
        this_position['beginning_price'] = (PricePoint.where(cid: cid, period: date).first.price).round(2)
        this_position['beginning_value'] = (this_position['share_count'] * this_position['beginning_price']).round(2)
        end_period_price_point = end_date == '' ? nil : PricePoint.where(cid: cid, period: end_date).first

        this_position['ending_price'] = end_date == '' ? 'n/a' : (end_period_price_point.price).round(2)
        this_position['ending_value'] = end_date == '' ? 'n/a' : (this_position['share_count'] * this_position['ending_price']).round(2)
        this_position['profit'] = end_date == '' ? 'n/a' : (this_position['ending_value'] - this_position['beginning_value']).round(2)
        
        if end_period_price_point && end_period_price_point.delisted
          this_position['notes'] = "delisted on #{end_period_price_point.delisting_date}"
        else
          this_position['notes'] = ''
        end        
        this_period['positions'] << this_position
      end

      this_period['cash'] = data[:cash]
      this_period['total_value_beginning'] = (this_period['positions'].inject(0) {|total, el| total + el['beginning_value']} + this_period['cash']).round(2)
      this_period['total_value_ending'] = end_date == '' ? 'n/a' : (this_period['positions'].inject(0) {|total, el| total + el['ending_value']} + this_period['cash']).round(2)
      this_period['total_profit'] = end_date == '' ? 'n/a' : (this_period['total_value_ending'] - this_period['total_value_beginning']).round(2)

      result << this_period
    end
    result
  end

  def relative_return(beginning, ending)
    result = {}
    current_balance = portfolio.as_of(ending)[:total_market_value]
    previous_period_balance = portfolio.as_of(beginning)[:total_market_value]
    result['return'] = (current_balance / previous_period_balance - 1).round(4)
    result['sp500_return'] = (sp500_return(beginning, ending)).round(4)
    result
  end

  def annualized_return(by_period_results)
    result = {}
    compounding = case parameters["rebalance_frequency"]
    when 'annual'
      1
    when 'semi-annual'
      2
    when 'quarterly'
      4
    when 'monthly'
      12
    end
    result['return'] = (((by_period_results['return'] + 1) ** compounding) - 1).round(4)
    result['sp500_return'] = (((by_period_results['sp500_return'] + 1) ** compounding) - 1).round(4)
    result
  end

  def sp500_return(beginning, ending)
    beginning_value = PricePoint.where(cid: 'sp500', period: beginning).first.price
    ending_value = PricePoint.where(cid: 'sp500', period: ending).first.price
    (ending_value / beginning_value - 1).round(4)
  end

  def single_period_start(ending_date)
    case parameters["rebalance_frequency"]
    when 'annual'
      (Date.strptime(ending_date, '%Y-%m-%d') - 1.year).to_s
    end
  end

  def cumulative_cy_start(ending_date)
    case parameters["rebalance_frequency"]
    when 'annual'
      (Date.strptime(ending_date, '%Y-%m-%d') - 1.year).to_s
    end
  end

  def rolling_12_months_start(ending_date)
    case parameters["rebalance_frequency"]
    when 'annual'
      (Date.strptime(ending_date, '%Y-%m-%d') - 1.year).to_s
    end
  end

  def geometric_average(start_date, end_date)
    result = {}
    result['description'] = 'Geometric average return'

    beginning_balance = portfolio.as_of(start_date)[:total_market_value]
    ending_balance = portfolio.as_of(end_date)[:total_market_value]
    result['portfolio'] = ((ending_balance / beginning_balance) ** (1.0 / portfolio.periods.count) - 1).round(4)

    sp500_beginning_balance = PricePoint.where(cid: 'sp500', period: start_date).first.price
    sp500_ending_balance = PricePoint.where(cid: 'sp500', period: end_date).first.price
    result['sp500'] = ((sp500_ending_balance / sp500_beginning_balance) ** (1.0 / portfolio.periods.count) - 1).round(4)
    result
  end

  def arithmetic_average(start_date, end_date, by_period_results)
    result = {}
    result['description'] = 'Arithmetic average return'

    returns = by_period_results.map{|v| v['by_period']}.map{|v| v['return']}
    result['portfolio'] = (returns.inject{ |sum, el| sum + el }.to_f / returns.size).round(4)

    returns = by_period_results.map{|v| v['by_period']}.map{|v| v['sp500_return']}
    result['sp500'] = (returns.inject{ |sum, el| sum + el }.to_f / returns.size).round(4)

    result
  end

  def st_deviation_by_period(start_date, end_date, by_period_results)
    result = {}
    result['description'] = 'Standard deviation of returns, by period'
    result['portfolio'] = by_period_results.map{|v| v['by_period']}.map{|v| v['return']}.extend(DescriptiveStatistics).standard_deviation.round(4)
    result['sp500'] = by_period_results.map{|v| v['by_period']}.map{|v| v['sp500_return']}.extend(DescriptiveStatistics).standard_deviation.round(4)
    result
  end

   def st_deviation_annualized(start_date, end_date, by_period_results)
    result = {}
    result['description'] = 'Standard deviation of returns, annualized'
    result['portfolio'] = by_period_results.map{|v| v['annualized']}.map{|v| v['return']}.extend(DescriptiveStatistics).standard_deviation.round(4)
    result['sp500'] = by_period_results.map{|v| v['annualized']}.map{|v| v['sp500_return']}.extend(DescriptiveStatistics).standard_deviation.round(4)
    result
  end

  def sharpe(inputs)
    result = {}
    result['description'] = 'Sharpe ratio (based on geometric average and rf = 4%)'
    result['portfolio'] = ((inputs['a_geometric']['portfolio'] - 0.04) / inputs['d_st_deviation_annualized']['portfolio']).round(3)
    result['sp500'] = ((inputs['a_geometric']['sp500'] - 0.04) / inputs['d_st_deviation_annualized']['sp500']).round(3)
    result
  end

  def max_drawdown_hash(initial_balance, by_period_results)
    result = {}
    result['description'] = 'Maximum drawdown'
    result['portfolio'] = max_drawdown(([initial_balance] << by_period_results.map{|k| k['balance']}).flatten)

    sp500_starting_value = PricePoint.where(cid: 'sp500', period: parameters["start_date"]).first.price
    result['sp500'] = max_drawdown(([sp500_starting_value] << by_period_results.map{|k| k['sp500_value']}).flatten)

    result
  end

  def max_drawdown(price_points)
    max_price = price_points[0]
    max_drawdown = [(price_points[1].to_f - max_price.to_f) / max_price.to_f, 0].min
    price_points.each_with_index do |current_price, index|
      next if index == 0
      potential_drawdown = [(current_price.to_f - max_price.to_f) / max_price.to_f, 0].min
      max_drawdown = [max_drawdown, potential_drawdown].min
      max_price  = [max_price, current_price].max
    end
    max_drawdown.round(4)
  end
end
