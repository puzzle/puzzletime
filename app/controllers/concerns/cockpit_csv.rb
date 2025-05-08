# frozen_string_literal: true

#  Copyright (c) 2006-2024, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module CockpitCsv
  extend ActiveSupport::Concern

  include CsvExportable

  private

  def send_cockpit_csv(cockpit, filename)
    csv_data = cockpit_csv(cockpit)
    send_csv(csv_data, filename)
  end

  def cockpit_csv(cockpit)
    CSV.generate do |csv|
      csv << ['Position', 'Budget', 'Geleistete Stunden', 'Nicht verrechenbar', 'Offenes Budget', 'Geplantes Budget']
      cockpit.rows.each do |row|
        csv << [row.respond_to?(:shortnames) ? row.shortnames : 'Total',
                row.cells[:budget].hours,
                row.cells[:supplied_services].hours,
                row.cells[:not_billable].hours,
                row.cells[:open_budget].hours,
                row.cells[:planned_budget].hours]
      end
    end
  end
end
