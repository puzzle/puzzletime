require 'test_helper'

class MultiEditWorktimes < ActionDispatch::IntegrationTest

  test 'click multi edit link' do
    login_as :mark
    visit order_order_services_path(order_id: orders(:puzzletime))
    find(:css, "#worktime_ids_[value='2']").set(true)
    find(:css, "#worktime_ids_[value='10']").set(true)
    click_link("Auswahl bearbeiten")
    assert page.has_text?('2 Zeiten bearbeiten')
    assert_equal all('#worktime_ids_', visible: false).map {|c| c.value}, ["2", "10"]
  end

end