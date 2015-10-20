# encoding: utf-8

class HalfDayAbstract < HalfDay
  attr_reader :label, :abstract_amount

  def initialize(label, abstract_amount)
    super(label)
    @abstract_amount = abstract_amount
  end
end
