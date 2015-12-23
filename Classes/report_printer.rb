class ReportPrinter
  attr_reader :results

  def initialize(results)
    @results = results
  end

  def generate
    binding.pry
    generate_summary
    generate_positions
  end

  def genereate_summary

  end

  def generate_positions

  end
end
