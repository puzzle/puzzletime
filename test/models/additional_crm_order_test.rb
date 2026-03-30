# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: additional_crm_orders
#
#  id       :bigint           not null, primary key
#  order_id :bigint           not null
#  crm_key  :string           not null
#  name     :string
#

require 'test_helper'

class AdditionalCrmOrderTest < ActiveSupport::TestCase
  setup :setup_crm
  teardown :reset_crm

  test 'sync crm after crm key changed' do
    assert_difference('Delayed::Job.count', 1) do
      orders(:puzzletime).additional_crm_orders.create!(crm_key: 123)
    end
  end

  test 'do not sync if crm key was not changed' do
    add = orders(:puzzletime).additional_crm_orders.create!(crm_key: 123)
    assert_no_difference('Delayed::Job.count') do
      add.update!(name: 'foo')
    end
  end

  private

  def setup_crm
    Crm.instance = Crm::Highrise.new
  end

  def reset_crm
    Crm.instance = nil
  end
end
