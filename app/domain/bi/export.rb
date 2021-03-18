#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module BI
  class Export
    def run
      stats = [
        [Reports::Revenue::BI.new.stats, 'Revenue'],
        [Reports::BIWorkload.new.stats, 'Workload'],
        [Order::Report::BI.new.stats, 'Orders'],
        [role_distribution, 'RoleDistribution']
      ]
      stats << [Crm::HighriseStats.new.stats, 'Highrise'] if highrise_enabled?

      export(stats)
    end

    private

    def highrise_enabled?
      Crm.instance.is_a?(Crm::Highrise)
    end

    def role_distribution
      # RoleDistributionReport ...
      []
    end

    def export(stats)
      exporter = InfluxExporter.new(Settings.influxdb)

      exporter.ensure_buckets(stats.map { |_s, bucket| bucket })
      stats.each { |data, bucket| exporter.export(data, bucket) }
    end
  end
end
