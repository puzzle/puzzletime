#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class Order::Report::Csv

  attr_reader :report

  def initialize(report)
    @report = report
  end

  def generate
    report.entries
    CSV.generate do |csv|
      csv << header

      report.entries.each do |e|
        csv << row(e)
      end
    end
  end

  private

  def header
    ['Kunde', 'Kategorie', 'Auftrag', 'Status', 'Abgeschlossen am', 'Budget',
     'Geleistet', 'Verrechenbar', 'Verrechnet', 'Verrechenbarkeit',
     'Offerierter Stundensatz', 'Verrechnete Stundensatz',
     'Durchschnittlicher Stundensatz', *target_scopes.collect(&:name)]
  end

  def row(e)
    ratings = target_scopes.collect { |scope| e.target(scope.id).try(:rating) }

    [e.client, e.category, e.name, e.status.to_s, e.closed_at,
     e.offered_amount, e.supplied_amount, e.billable_amount, e.billed_amount,
     e.billability, e.offered_rate, e.billed_rate, e.average_rate, *ratings]
  end

  def target_scopes
    @target_scopes ||= TargetScope.list.to_a
  end

end
