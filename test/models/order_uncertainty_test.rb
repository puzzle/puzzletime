#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: order_uncertainties
#
#  id          :integer          not null, primary key
#  order_id    :integer          not null
#  type        :string           not null
#  name        :string           not null
#  probability :integer          default("improbable"), not null
#  impact      :integer          default("none"), not null
#  measure     :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class OrderRiskTest < ActiveSupport::TestCase

  test '#risk_value is probability times impact' do
    r1 = OrderRisk.new(name: 'Earthquake', probability: :low, impact: :medium)
    assert_equal 6, r1.risk_value

    r2 = OrderRisk.new(name: 'Atomic desaster', probability: :improbable, impact: :high)
    assert_equal 4, r2.risk_value
  end

  test '#risk' do
    assert_equal :low, OrderRisk.new(probability: :improbable, impact: :none).risk
    assert_equal :low, OrderRisk.new(probability: :improbable, impact: :low).risk
    assert_equal :medium, OrderRisk.new(probability: :improbable, impact: :medium).risk
    assert_equal :medium, OrderRisk.new(probability: :improbable, impact: :high).risk

    assert_equal :low, OrderRisk.new(probability: :low, impact: :none).risk
    assert_equal :medium, OrderRisk.new(probability: :low, impact: :low).risk
    assert_equal :medium, OrderRisk.new(probability: :low, impact: :medium).risk
    assert_equal :high, OrderRisk.new(probability: :low, impact: :high).risk

    assert_equal :medium, OrderRisk.new(probability: :medium, impact: :none).risk
    assert_equal :medium, OrderRisk.new(probability: :medium, impact: :low).risk
    assert_equal :high, OrderRisk.new(probability: :medium, impact: :medium).risk
    assert_equal :high, OrderRisk.new(probability: :medium, impact: :high).risk

    assert_equal :medium, OrderRisk.new(probability: :high, impact: :none).risk
    assert_equal :high, OrderRisk.new(probability: :high, impact: :low).risk
    assert_equal :high, OrderRisk.new(probability: :high, impact: :medium).risk
    assert_equal :high, OrderRisk.new(probability: :high, impact: :high).risk
  end

  test 'updates major order values' do
    assert_nil order.major_risk_value
    assert_nil order.major_chance_value

    order.order_risks.create!(name: 'Atomic desaster',
                              probability: :improbable,
                              impact: :high)

    order.reload
    assert_equal 4, order.major_risk_value
    assert_nil order.major_chance_value

    order.order_risks.create!(name: 'Earthquake',
                              probability: :low,
                              impact: :medium)

    order.reload
    assert_equal 6, order.major_risk_value
    assert_nil order.major_chance_value

    order.order_risks.create!(name: 'Trump tweets true facts',
                              probability: :improbable,
                              impact: :none)

    order.reload
    assert_equal 6, order.major_risk_value
    assert_nil order.major_chance_value


    r = order.order_chances.create!(name: 'World domination',
                                    probability: :low,
                                    impact: :high)

    order.reload
    assert_equal 6, order.major_risk_value
    assert_equal 8, order.major_chance_value

    r.update!(probability: :medium)

    order.reload
    assert_equal 6, order.major_risk_value
    assert_equal 12, order.major_chance_value

    order.order_risks.destroy_all

    order.reload
    assert_nil order.major_risk_value
    assert_equal 12, order.major_chance_value
  end

  private

  def order
    orders(:allgemein)
  end

end
