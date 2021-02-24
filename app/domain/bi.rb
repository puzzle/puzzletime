#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module BI
  class ConfigurationError < StandardError; end

  def self.init
    if Settings.influxdb&.export
      check_config!

      BIExportJob.schedule if Delayed::Job.table_exists?
    end
  end

  private

  def self.check_config!
    settings = Settings.influxdb

    missing = %i[host port org token use_ssl].select do |setting|
      settings.send(setting).nil?
    end

    return if missing.empty?

    raise ConfigurationError, "Settings influxdb.{#{missing.join(', ')}} missing"
  end
end
