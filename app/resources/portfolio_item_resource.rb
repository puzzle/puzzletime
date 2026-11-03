# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Portfolio items of accounting posts. Only those who may read the model by `Ability` see rows.
class PortfolioItemResource < ApplicationResource
  include AbilityScoped

  model PortfolioItem

  attribute :name, :string
  attribute :active, :boolean
end
