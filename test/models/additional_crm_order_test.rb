# frozen_string_literal: true

# == Schema Information
#
# Table name: additional_crm_orders
#
#  id       :bigint(8)        not null, primary key
#  order_id :bigint(8)        not null
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
