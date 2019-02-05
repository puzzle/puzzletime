# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Employees
  class LogController < ApplicationController

    before_action :authorize_action

    def index
      @versions = log.versions
    end

    private

    def log
      @log ||= LogPresenter.new(entry, params, view_context)
    end

    def entry
      @employee ||= Employee.find(params[:id])
    end

    def authorize_action
      authorize!(:log, entry)
    end

    def employee_log
      PaperTrail::Version.where(
        item_id: entry.id,
        item_type: Employee.sti_name
      )
    end

    def employment_log
      PaperTrail::Version.where(id:
        PaperTrail::Version.where(
          item_type: Employment.sti_name
        ).map do |employment|
          if employment.changeset['employee_id'].include?(entry.id)
            employment.id
          end
        end
      )
    end

  end
end
