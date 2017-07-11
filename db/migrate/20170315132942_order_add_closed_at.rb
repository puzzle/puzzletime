class OrderAddClosedAt < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :closed_at, :date

    date = Date.new(2015, 1, 1).end_of_month + 6.months

    status_to_migrate = [
      ['Abgeschlossen Q4 GJ 2014/2015', date],
      ['Abgeschlossen Q1 GJ 2015/2016', date = next_quarter(date)],
      ['Abgeschlossen Q2 GJ 2015/2016', date = next_quarter(date)],
      ['Abgeschlossen Q3 GJ 2015/2016', date = next_quarter(date)],
      ['Abgeschlossen Q4 GJ 2015/2016', date = next_quarter(date)],
      ['Abgeschlossen Q1 GJ 2016/2017', date = next_quarter(date)],
      ['Abgeschlossen Q2 GJ 2016/2017', date = next_quarter(date)],
      ['Abgeschlossen Q3 GJ 2016/2017', date = next_quarter(date)],
      ['Abgeschlossen Q4 GJ 2016/2017', next_quarter(date)]
    ]

    order_status_closed = OrderStatus.find_by(name: 'Abgeschlossen')

    return unless order_status_closed

    status_to_migrate.each do |(name, closed_at)|
      order_status = OrderStatus.find_by(name: name)

      next unless order_status

      Order.where(status_id: order_status.id)
           .update_all(status_id: order_status_closed.id,
                       closed_at: closed_at)
      order_status.destroy!
    end
  end

  private

  def next_quarter(date)
    (date + 3.months).end_of_month
  end
end
