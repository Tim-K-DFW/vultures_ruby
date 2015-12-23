require 'axlsx'

class ReportPrinter
  attr_reader :results

  def initialize(results)
    @results = results
  end

  def generate
    binding.pry
    Axlsx::Package.new do |p|
      wb = p.workbook


      generate_summary(wb)
      generate_positions(wb)

      p.serialize('test.xlsx')
    end
  end

  def generate_summary(wb)
    wb.add_worksheet(name: 'performance') do |s|
      regular_style = s.styles.add_style()
      italicized = s.styles.add_style(i: true, num_fmt: 8)
      table_title = s.styles.add_style(fg_color: '000000', bg_color: 'BDD4E8',
        b: true, alignment: { horizontal: :center, vertical: :center, wrap_text: true} )
      currency = s.styles.add_style(num_fmt: 8)
      percentage = s.styles.add_style(num_fmt: 10)

      s.sheet_view.show_grid_lines = false
      s.add_row []
      s.add_row ['','Strategy Performance'], sz: 18
      s.add_row []
      s.add_row ['','Parameters'], sz: 14
      s.add_row ['','Rebalance frequency', results['parameters']['rebalance_frequency']]
      s.add_row ['','# of positions in portfolio', results['parameters']['position_count']]
      s.add_row ['','Market cap floor, $mm', results['parameters']['market_cap_floor']]
      s.add_row ['','Market cap ceiling, $mm', results['parameters']['market_cap_ceiling']]
      s.add_row []
      s.add_row ['','By period'], sz: 14
      s.add_row ['','Period ending', 'Market value at period end', 'by period', '', 'by period, annualized', '', 'cumulative CY', '', 'rolling 12 months', ''], style: [nil, Array.new(10, table_title)].flatten
      s.add_row ['', '', '', Array.new(4, ['tested strategy', 'S&P 500'])].flatten, style: [nil, Array.new(10, table_title)].flatten
      s.add_row ['','Initial balance', results['parameters']['initial_balance']], style: italicized
      s.merge_cells('b11:b12')
      s.merge_cells('c11:c12')
      s.merge_cells('d11:e11')
      s.merge_cells('f11:g11')
      s.merge_cells('h11:i11')
      s.merge_cells('j11:k11')
      results['performance'].each do |period|
        s.add_row ['', period['date'], period['balance'],
          period['by_period']['return'],
          period['by_period']['sp500_return'],
          period['annualized']['return'],
          period['annualized']['sp500_return'],
          period['cumulative_cy']['return'],
          period['cumulative_cy']['sp500_return'],
          period['rolling_12_months']['return'],
          period['rolling_12_months']['sp500_return']],
          style: [nil, nil, currency, Array.new(8, percentage)].flatten
      end
      s.add_row []
      s.add_row ['','Aggregated'], sz: 14
      s.add_row ['',"For the period between #{results['aggregated']['start_date']} and #{results['aggregated']['end_date']} "]
      s.add_row ['', '', 'tested strategy', 'S&P 500'], style: [nil, Array.new(3, table_title)].flatten
      results['aggregated']['table'].keys[0..4].each do |line|
        this_line = results['aggregated']['table'][line]
        s.add_row ['', this_line['description'], this_line['portfolio'], this_line['sp500']], style: percentage
      end
      this_line = results['aggregated']['table']['f_sharpe']
      s.add_row ['', 'Sharpe ratio', this_line['portfolio'], this_line['sp500']]
      s.column_widths 3, 36, 15, 11, 11, 11, 11, 11, 11, 11, 11
    end
  end

  def generate_positions(wb)
    wb.add_worksheet(name: 'positions') do |s|
      italicized = s.styles.add_style(i: true, num_fmt: 8)
      table_title = s.styles.add_style(fg_color: '000000', bg_color: 'BDD4E8',
        b: true, alignment: { horizontal: :center, vertical: :center, wrap_text: true} )
      currency = s.styles.add_style(num_fmt: 8)
      percentage = s.styles.add_style(num_fmt: 10)

      s.sheet_view.show_grid_lines = false
      
      s.column_widths 3, 36, 15, 11, 11, 11, 11, 11, 11, 11, 11
    end
  end
end
