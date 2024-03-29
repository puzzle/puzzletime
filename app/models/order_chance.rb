# frozen_string_literal: true

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

class OrderChance < OrderUncertainty
  private

  def update_major_order_value
    order.update!(major_chance_value: major_order_value)
  end

  def major_order_value
    order.order_chances
         .where(type: OrderChance.sti_name)
         .pick(Arel.sql('MAX(probability * impact)'))
  end
end
