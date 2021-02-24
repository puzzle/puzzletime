#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module BI
  class InfluxExporter
    # @param settings `Settings.influxdb`
    def initialize(settings)
      @client = make_client(settings)
      @org = settings.org
      @use_ssl = settings.use_ssl
    end

    def ensure_buckets(buckets)
      ensurer = InfluxEnsureBucket.new(@client, @org)
      buckets.each { |bucket| ensurer.bucket(bucket) }
    end

    def export(data, bucket)
      return if data.empty?

      sanitize_fields!(data)

      api = @client.create_write_api
      api.write(data: data, bucket: bucket)
    end

    private

    def sanitize_fields!(data)
      # If we write a field with type int first and then try to write a floating point
      # value afterwards, we get
      # `failure writing points to database: partial write: field type conflict [...]`
      data.each do |e|
        e[:fields].transform_values! { |v| v.is_a?(Numeric) ? v.to_f : v }
      end
    end

    def make_client(settings)
      scheme = @use_ssl ? 'https' : 'http'
      url = "#{scheme}://#{settings.host}:#{settings.port}"
      InfluxDB2::Client.new(
        url,
        settings.token,
        org: settings.org,
        precision: InfluxDB2::WritePrecision::SECOND,
        bucket: 'PtimeDefault',
        use_ssl: settings.use_ssl
      )
    end
  end
end
