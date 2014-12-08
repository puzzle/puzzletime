class Order::Cockpit
  class Cell < Struct.new(:hours, :amount)

    def days
      hours / WorkingCondition.value_at(Date.today, :must_hours_per_day) if hours
    end

  end
end