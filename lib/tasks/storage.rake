require_relative '../storage_reupload'

namespace :storage do
  task reupload: :environment do
    StorageReupload.all
  end
end
