# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class RoleDistributionReportController < ApplicationController

  include CsvExportable

  before_action :authorize_class

  def index
    respond_to do |format|
      format.html
      format.csv do
        if params[:date].present?
          report = RoleDistributionReport.new(Time.zone.parse(params[:date]))
          send_csv(report.to_csv, report.filename)
        else
          flash[:alert] = 'Bitte wählen Sie ein Stichdatum.'
          redirect_back(fallback_location: root_path)
        end
      end
    end
  end

  private

  def authorize_class
    authorize!(:role_distribution_report, Evaluation)
  end

end