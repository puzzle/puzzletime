class Order::Report::Entry < SimpleDelegator

  attr_reader :order, :accounting_posts, :hours, :invoices

  def initialize(order, accounting_posts, hours, invoices)
    super(order)
    @order = order
    @accounting_posts = accounting_posts
    @hours = hours
    @invoices = invoices
  end

  def offered_amount
    @offered ||= sum_accounting_posts { |id| post_value(id, :offered_total) }
  end

  def offered_rate
    @offered_rate ||=
      if offered_hours > 0
        (offered_amount / offered_hours).to_d
      else
        rates = sum_accounting_posts { |id| post_value(id, :offered_rate) }
        rates > 0 ? rates / accounting_posts.size : nil
      end
  end

  def offered_hours
    @offered_hours ||=
      sum_accounting_posts do |id|
        rate = post_value(id, :offered_rate)
        post_value(id, :offered_hours) ||
          (rate && (post_value(id, :offered_total) / rate.to_f)) ||
          0
      end
  end

  def supplied_amount
    @supplied ||= sum_accounting_posts { |id| post_value(id, :offered_rate) * post_hours(id) }
  end

  def supplied_hours
    @supplied_hours ||= sum_accounting_posts { |id| post_hours(id) }
  end

  def billable_amount
    @billable ||= sum_accounting_posts { |id| post_value(id, :offered_rate) * post_hours(id, true) }
  end

  def billable_hours
    @billable_hours ||= sum_accounting_posts { |id| post_hours(id, true) }
  end

  def billed_amount
    invoices[:total_amount].to_d
  end

  def billed_hours
    invoices[:total_hours].to_d
  end

  def billability
    @billability ||= supplied_hours > 0 ? (billed_hours / supplied_hours * 100).round : nil
  end

  def billed_rate
    @billed_rate ||= billed_hours > 0 ? billed_amount / billed_hours : nil
  end

  def average_rate
    @average_rate ||= supplied_hours > 0 ? billed_amount / supplied_hours : nil
  end

  private

  def sum_accounting_posts(&block)
    accounting_posts.keys.sum(&block)
  end

  def post_hours(id, billable = nil)
    h = hours[id]
    return 0.to_d unless h

    if billable.nil?
      h.values.sum.to_d
    else
      h[billable].to_d
    end
  end

  def post_value(id, key)
    accounting_posts[id][key] || 0
  end

end
