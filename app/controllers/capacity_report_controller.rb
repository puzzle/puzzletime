# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class CapacityReportController < ApplicationController
  include CsvExportable

  before_action :authorize_class
  before_action :set_period

  def index
    if @period
      report = Reports::ExtendedCapacityReport.new(@period)
      send_csv(report.to_csv, report.filename)
    else
      flash[:alert] = 'Bitte wählen Sie eine Zeitspanne für die Auslastung.'
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def authorize_class
    authorize!(:capacity_report, Evaluations::Evaluation)
  end
end
