# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Risks of an order; see WritableUncertaintyResource.
class OrderRiskResource < WritableUncertaintyResource
  self.type = :order_risks
  primary_endpoint '/order_risks'
  model OrderRisk
end
