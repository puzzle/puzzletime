# frozen_string_literal: true

unless Rails.env.test? || ENV['PROMETHEUS_EXPORTER_HOST'].blank?
  require 'prometheus_exporter/middleware'
  require 'prometheus_exporter/instrumentation'

  PrometheusExporter::Client.default = PrometheusExporter::Client.new(
    host: ENV.fetch('PROMETHEUS_EXPORTER_HOST', nil),
    port: ENV['PROMETHEUS_EXPORTER_PORT'] || PrometheusExporter::DEFAULT_PORT
  )

  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware

  # This reports basic process stats like RSS and GC info
  proc_type = $ARGV.to_s.include?('jobs:work') ? 'delayed_job' : 'puma_master'
  PrometheusExporter::Instrumentation::Process.start(
    type: proc_type,
    labels: { hostname: `hostname`.strip }
  )

  # This reports delayed job info
  PrometheusExporter::Instrumentation::DelayedJob.register_plugin

end
