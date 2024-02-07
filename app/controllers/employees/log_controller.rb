# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Employees
  class LogController < ApplicationController
    before_action :authorize_action

    def index
      @presenter = Presenters::LogPresenter.new(employee, params)
    end

    private

    def employee
      @employee ||= Employee.find(params[:id])
    end

    def authorize_action
      authorize!(:log, employee)
    end
  end
end
