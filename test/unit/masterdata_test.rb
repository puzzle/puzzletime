require File.dirname(__FILE__) + '/../test_helper'

class MasterdataTest < Test::Unit::TestCase
  fixtures :masterdatas

  # Replace this with your real tests.
  def test_singleton
    assert Masterdata.instance.musthours_day == 8
    assert Masterdata.instance.vacations_year == 20
  end
end
