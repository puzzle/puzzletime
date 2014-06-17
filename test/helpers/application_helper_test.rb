require 'test_helper'

# Test UtilityHelper
class ApplicationHelperTest < ActionView::TestCase

  test 'format hour' do
    assert_equal "0:00", format_hour(nil)
    assert_equal "0:00", format_hour(0.0001)
    assert_equal "0:30", format_hour(0.5)
    assert_equal "8:20", format_hour(8.33333)
    assert_equal "1&#39;234:34", format_hour(1234.56)
  end
  
  test 'format day' do
    assert_equal "Mo 16.6.", format_day(Date.new(2014, 6, 16))
    assert_equal "Mi 18.6.", format_day(Date.new(2014, 6, 18))
    assert_equal "Do 18.6.", format_day(Date.new(2099, 6, 18))
  end

end
