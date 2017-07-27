#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class OrderCommentsController < CrudController
  self.nesting = Order
  self.permitted_attrs = :text

  def create
    super do |format, success|
      format.html { render :index } unless success
    end
  end

  private

  def assign_attributes
    entry.attributes = model_params
    entry.updater = current_user
    entry.creator ||= current_user
  end

  def parent_scope
    parent.send(:comments)
  end
end
