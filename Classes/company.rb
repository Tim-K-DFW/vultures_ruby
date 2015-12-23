class Company
  attr_accessor :name, :cid, :ticker

  def initialize(args)
    @name = args[:name]
    @cid = args[:cid]
    @ticker = args[:ticker]
  end
end
