# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: clients
#
#  id                  :integer          not null, primary key
#  allow_local         :boolean          default(FALSE), not null
#  crm_key             :string
#  e_bill_account_key  :string
#  invoicing_key       :string
#  last_invoice_number :integer          default(0)
#  sector_id           :integer
#  work_item_id        :integer          not null
#
# Indexes
#
#  index_clients_on_sector_id     (sector_id)
#  index_clients_on_work_item_id  (work_item_id)
#
# }}}

require 'test_helper'

class ClientTest < ActiveSupport::TestCase
  test 'client with worktimes may not be destroyed' do
    assert_no_difference('WorkItem.count') do
      assert_no_difference('Client.count') do
        clients(:puzzle).destroy
      end
    end
  end

  test 'client without worktimes is destroyed with entire structure' do
    Worktime.destroy_all
    Invoice.destroy_all
    assert_difference('WorkItem.count', -2) do
      assert_difference('Client.count', -1) do
        clients(:swisstopo).destroy
      end
    end
  end

  test 'work item is destroyed with client' do
    client = Fabricate(:client)
    assert_difference('WorkItem.count', -1) do
      assert_difference('Client.count', -1) do
        client.destroy
      end
    end
  end

  test 'e bill account key has 17 digits' do
    client = Client.new
    client.valid?

    assert_predicate client.errors[:e_bill_account_key], :blank?

    client.e_bill_account_key = '41105678901234567'
    client.valid?

    assert_predicate client.errors[:e_bill_account_key], :blank?

    client.e_bill_account_key = '411056789012345678'
    client.valid?

    assert_predicate client.errors[:e_bill_account_key], :present?

    client.e_bill_account_key = '4110567890123456'
    client.valid?

    assert_predicate client.errors[:e_bill_account_key], :present?

    client.e_bill_account_key = '12345678901234567'
    client.valid?

    assert_predicate client.errors[:e_bill_account_key], :present?
  end
end
