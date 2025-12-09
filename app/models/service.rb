# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: services
#
#  id     :integer          not null, primary key
#  active :boolean          default(TRUE), not null
#  name   :string           not null
#
# }}}

class Service < ApplicationRecord
  has_many :accounting_posts

  scope :list, -> { order(:name) }

  protect_if :accounting_posts, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Budgetpositionen zugeordnet sind'

  validates_by_schema
  validates :name, uniqueness: true

  def to_s
    name
  end
end
