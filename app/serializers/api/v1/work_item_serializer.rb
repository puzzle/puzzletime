# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class WorkItemSerializer < ApiSerializer
      attributes :name,
                 :shortname,
                 :description,
                 :path_ids,
                 :path_shortnames,
                 :path_names,
                 :leaf,
                 :closed

      annotate_attributes :name,
                          :shortname,
                          :description,
                          :path_ids,
                          :path_shortnames,
                          :path_names,
                          :leaf,
                          :closed

      belongs_to :parent, record_type: :work_item, serializer: :work_item

      has_many :children, record_type: :work_item, serializer: :work_item
      has_many :plannings
      has_many :worktimes

      has_one :accounting_post
      has_one :client
      has_one :order
    end
  end
end
