class CompanyTable
  attr_accessor :main_table, :size

  def initialize
    @main_table = {}
    @size = 0
  end

  def add(item)
    main_table[(item.cid).to_sym] = item
    @size += 1
  end

  def where(args)
    main_table[args[:cid].to_sym]
  end
end
