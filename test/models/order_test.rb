require 'test_helper'

class OrderTest < ActiveSupport::TestCase

  test 'order without client is not valid' do
    order = Fabricate(:order)
    item = order.build_work_item(name: 'New Order', shortname: 'NEOR')
    assert !order.valid?
  end

  test 'order with client is valid' do
    order = Fabricate(:order)
    item = order.build_work_item(name: 'New Order', shortname: 'NEOR', parent_id: work_items(:puzzle).id)
    assert order.valid?, order.errors.full_messages.join(', ')
  end

end
