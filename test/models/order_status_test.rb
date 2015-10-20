# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  name     :string(255)      not null
#  style    :string(255)
#  closed   :boolean          default(FALSE), not null
#  position :integer          not null
#

require 'test_helper'

class OrderStatusTest < ActiveSupport::TestCase
  test 'closed is propagated to all order work items' do
    status = order_statuses(:bearbeitung)
    status.update!(closed: true)
    assert work_items(:hitobito_demo_app).closed
    assert work_items(:hitobito_demo_site).closed
    assert work_items(:puzzletime).closed
  end

  test 'opened is propagated to all order work items' do
    status = order_statuses(:abgeschlossen)
    status.update!(closed: false)
    assert !work_items(:allgemein).closed
  end
end
