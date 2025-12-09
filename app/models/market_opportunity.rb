# frozen_string_literal: true

#  Copyright (c) 2006-2024, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

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

class MarketOpportunity < ApplicationRecord
  has_many :accounting_posts, dependent: :nullify

  scope :list, -> { order(:name) }

  protect_if :accounting_posts, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Marktopportunitäten zugeordnet sind'

  validates_by_schema
  validates :name, uniqueness: true

  def to_s
    name
  end
end
