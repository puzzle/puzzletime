module Invoicing
  class Position
    
    attr_reader :accounting_post, :total_hours, :name

    def initialize(accounting_post, hours = 0, name = nil)
      @accounting_post = accounting_post
      @total_hours = hours
      @name = name || accounting_post.name
    end

    def total_amount
      total_hours * (accounting_post.offered_rate || 0)
    end

  end
end
