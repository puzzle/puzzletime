# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class VacationsController < ApplicationController
  before_action :authorize_action
  before_action :set_period

  def show
    @graph = Graphs::VacationGraph.new(@period)
  end

  private

  def authorize_action
    authorize!(:show_vacations, Absencetime)
  end
end
