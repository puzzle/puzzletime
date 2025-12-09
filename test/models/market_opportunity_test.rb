# frozen_string_literal: true

# {{{
# == Schema Information
#
# Table name: market_opportunities
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE), not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_market_opportunities_on_name  (name) UNIQUE
#
# }}}
require 'test_helper'

class MarketOpportunityTest < ActiveSupport::TestCase
  test 'Being used prevents deletion of a market opportunity' do
    MarketOpportunity.create!(name: 'Testopportunity', active: true)

    duplicate = MarketOpportunity.create(name: 'Testopportunity', active: false)

    assert_not duplicate.valid?
  end
end
