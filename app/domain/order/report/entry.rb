class Order::Report::Entry < SimpleDelegator

  # TODO make modifiable
  INTERNAL_RATE = 100

  attr_reader :order, :accounting_posts, :hours, :invoices

  def initialize(order, accounting_posts, hours, invoices)
    super(order)
    @order = order
    @accounting_posts = accounting_posts
    @hours = hours
    @invoices = invoices
  end

  def offered_amount
    @offered ||= accounting_posts.inject(0) { |sum, p| sum + (p.offered_total || 0) }
  end

  def supplied_amount
    @supplied ||=
      accounting_posts.sum do |post|
        post.offered_rate ? post.offered_rate * hours[post.id].values.sum.to_d : 0
      end
  end

  def supplied_hours
    @supplied_hours ||= accounting_posts.sum { |post| hours[post.id].values.sum.to_d  }
  end

  def billable_amount
    @billable ||=
      accounting_posts.sum do |post|
        post.offered_rate ? post.offered_rate * hours[post.id][true].to_d : 0
      end
  end

  def billable_hours
    @billable_hours ||= accounting_posts.sum { |post| hours[post.id][true] }
  end

  def billed_amount
    invoices[:total_amount].to_d
  end

  def billed_hours
    invoices[:total_hours].to_d
  end

  def billability
    @billability ||= supplied_hours > 0 ? (billable_hours / supplied_hours * 100).round : nil
  end

  def billed_rate
    @billed_rate ||= billed_hours > 0 ? billed_amount / billed_hours : nil
  end

  def average_rate
    @average_rate ||= supplied_hours > 0 ? billed_amount / supplied_hours : nil
  end

  def profit_margin
    @profit_margen ||= billed_rate ? billed_rate - INTERNAL_RATE : nil

  end

end
