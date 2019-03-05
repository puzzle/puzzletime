class RemoveClassicDelayedJobs < ActiveRecord::Migration[5.1]
  def change
    Delayed::Job
      .where('handler NOT LIKE ?', "%ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper%")
      .destroy_all
  end
end
