class Order::Cockpit
  class Row < Struct.new(:label)

    attr_reader :cells

  end
end
