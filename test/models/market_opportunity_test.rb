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
  # test "the truth" do
  #   assert true
  # end
end
