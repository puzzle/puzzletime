# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# abstract class for evaluation with work item divisions
module Evaluations
  class WorkItemsEval < Evaluations::Evaluation
    self.division_method   = :work_items
    self.division_column   = Arel.sql('work_items.path_ids[1]')
    self.division_join     = :work_item
    self.label             = 'Positionen'
    self.sub_evaluation    = 'workitememployees'
    self.sub_work_items_eval = 'subworkitems'

    def account_id
      division&.id
    end
  end
end
