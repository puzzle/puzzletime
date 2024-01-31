#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: order_contacts
#
#  false      :integer          not null, primary key
#  contact_id :integer          not null
#  order_id   :integer          not null
#  comment    :string
#

require 'test_helper'

class OrderContactTest < ActiveSupport::TestCase
  teardown :reset_crm

  test 'list scope is ordered by contact' do
    order = Fabricate(:order)
    m = OrderContact.create!(order:, contact: Fabricate(:contact, lastname: 'Miller', client: order.client))
    a = OrderContact.create!(order:, contact: Fabricate(:contact, lastname: 'Aber', client: order.client))

    expected = [a, m].map(&:attributes)
    received = order.order_contacts.list.map(&:attributes)

    assert_equal expected, received
  end

  test 'crm ids are replaced' do
    Crm.instance = Crm::Highrise.new
    Crm.instance.expects(:find_person).returns(lastname: 'Miller', firstname: 'Fred', crm_key: '123')
    c = OrderContact.new(order: Fabricate(:order), contact_id_or_crm: 'crm_123')
    assert_difference('OrderContact.count') do
      assert_difference('Contact.count') do
        assert c.save
      end
    end
  end

  private

  def reset_crm
    Crm.instance = nil
  end
end
