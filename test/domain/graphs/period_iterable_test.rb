require 'test_helper'
class PeriodIterableTest < ActiveSupport::TestCase
  def period_iterable_class(start_date, num_days)
    Class.new do
      include PeriodIterable
      attr_reader :period
      def initialize(start_date, end_date)
        @period = Period.new(start_date, end_date)
      end
    end.new(start_date, start_date + (num_days - 1).days)
  end

  test '#enumerate_weeks' do
    weeks = period_iterable_class(Time.zone.today, 1).enumerate_weeks.to_a
    assert_equal [Time.zone.today], weeks

    weeks = period_iterable_class(Time.zone.today, 7).enumerate_weeks.to_a
    assert_equal [Time.zone.today], weeks

    weeks = period_iterable_class(Time.zone.today, 8).enumerate_weeks.to_a
    assert_equal [Time.zone.today, 7.days.from_now.to_date], weeks
  end
end
