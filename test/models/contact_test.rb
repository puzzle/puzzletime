# frozen_string_literal: true

# {{{
# == Schema Information
#
# Table name: contacts
#
#  id            :integer          not null, primary key
#  crm_key       :string
#  email         :string
#  firstname     :string
#  function      :string
#  invoicing_key :string
#  lastname      :string
#  mobile        :string
#  phone         :string
#  created_at    :datetime
#  updated_at    :datetime
#  client_id     :integer          not null
#
# Indexes
#
#  index_contacts_on_client_id  (client_id)
#
# }}}

require 'test_helper'

class ContactTest < ActiveSupport::TestCase
  def contact(email:)
    Fabricate.build(:contact, email:, client: clients(:puzzle))
  end

  test 'email can be blank' do
    assert_predicate contact(email: nil), :valid?
    assert_predicate contact(email: ''), :valid?
  end

  test 'email must be valid' do
    assert_predicate contact(email: 'test.email+tag@example.com'), :valid?
    assert_not contact(email: 'test').valid?
    assert_not contact(email: 'example.com').valid?
    assert_not contact(email: '@example.com').valid?
    assert_not contact(email: 'test@email@example.com').valid?
    assert_not contact(email: 'andré@example.com').valid?
  end
end
