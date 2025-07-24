# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: order_uncertainties
#
#  id          :integer          not null, primary key
#  impact      :integer          default("none"), not null
#  measure     :text
#  name        :string           not null
#  probability :integer          default("improbable"), not null
#  type        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  order_id    :integer          not null
#
# Indexes
#
#  index_order_uncertainties_on_order_id  (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#
# }}}

class OrderRisk < OrderUncertainty
  private

  def update_major_order_value
    order.update!(major_risk_value: major_order_value)
  end

  def major_order_value
    order.order_risks
         .pick(Arel.sql('MAX(probability * impact)'))
  end
end
