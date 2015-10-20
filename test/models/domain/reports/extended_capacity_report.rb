require 'test_helper'

class ExtendedCapacityReportTest < ActiveSupport::TestCase
  test 'does not crash' do
    employees(:mark).employments.create(start_date: Date.parse('2006-12-07'), percent: 100)
    period = Period.month_for(Date.parse('2006-12-03'))
    ExtendedCapacityReport.new(period).to_csv
    # File.open('/tmp/csvtest', 'w'){|f| f << ExtendedCapacityReport.new(period).to_csv }
  end

  test 'business' # TODO: implement business tests
end
