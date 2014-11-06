class CronJob < BaseJob

  class_attribute :cron_expression

  # Enqueue delayed job if it is not enqueued already
  def schedule
    enqueue!(cron: cron_expression) unless scheduled?
  end

  # Is this job enqueued in delayed job?
  def scheduled?
    delayed_jobs.present?
  end

end