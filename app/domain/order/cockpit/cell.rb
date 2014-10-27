class Order::Cockpit
  class Cell < Struct.new(:hours, :amount)

    def days
      hours / Settings.must_hours_per_day if hours
    end

  end
end