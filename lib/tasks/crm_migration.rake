# frozen_string_literal: true

require 'csv'

namespace :crm_migration do
  desc <<~DESC
    create a mock mapping between crm_keys

    convenience task which creates a MOCK mapping between all the crm_keys
    found in the models Client Employee Contact AdditionalCrmOrder Order.

    Creates a .csv containing this mapping (default name: ids_map.csv).

    Needs an ENV-Var MAPPINGS_FOLDER to store the csv in.
  DESC
  task create_mock_data_mapping: :environment do
    # Folder, where all the mapping .csv reside
    mappings_folder = ENV.fetch('MAPPINGS_FOLDER', nil)
    abort 'Error: ENV Var MAPPINGS_FOLDER cannot be empty' if mappings_folder.nil?

    mkdir_p(mappings_folder)

    models = %w[Client Employee Contact AdditionalCrmOrder Order]

    models.each do |model_name|
      model = model_name.constantize
      ids = model.where.not(crm_key: nil).pluck(:crm_key).uniq

      # writes the generated mapping of (old_crm_key, new_crm_key) as a new line into the csv
      CSV.open(File.join(mappings_folder, "#{model_name.underscore}.csv"), 'w') do |csv|
        ids.each_with_index do |old_id, new_id|
          csv << [old_id, new_id] # Write each tuple as a row
        end
      end
      puts "Created folder with mock mappings at #{mappings_folder}"
    end
  end

  desc <<~DESC
    apply mappings to CRM-keys in DB

    given some .csv files mapping old crm_keys to new ones, apply this mapping
    to all crm_keys in the db.

    Needs an ENV-Var MAPPINGS_FOLDER to read the mapping from.

    Optionally accepts SKIP_MODELS/ONLY_MODEL to select which models to process.
  DESC
  task substitute_crm_tokens: :environment do
    # Folder, where all the mapping .csv reside
    mappings_folder = ENV.fetch('MAPPINGS_FOLDER', nil)
    abort 'Error: ENV Var MAPPINGS_FOLDER cannot be empty' if mappings_folder.nil?

    mkdir_p(mappings_folder)

    models =
      if (only_model = ENV.fetch('ONLY_MODEL', nil)&.strip&.classify)
        [only_model]
      else
        all_models = %w[Client Employee Contact AdditionalCrmOrder Order]
        skip_models = ENV.fetch('SKIP_MODELS', '').split(',').map { _1.strip.classify }

        puts "All Models: #{all_models.join(', ')}"
        puts "Models to skip: #{skip_models.join(', ')}"

        all_models - skip_models
      end

    puts "Models to migrate: #{models.join(', ')}"

    models.each do |model_name|
      file_path = File.join(mappings_folder, "#{model_name.underscore}.csv")
      model = model_name.constantize

      # Step 1: Build the mapping from the CSV
      mapping = CrmMigrationHelper.build_mapping(file_path)

      # Step 2: For every model, make dry run
      # (Verify that for every old crm_key there is a new crm_key, else abort)
      CrmMigrationHelper.perform_dry_run(model, mapping)
      puts "Completed dry run for Model #{model}. Everything OK. Commencing database update..."

      # Step 3: For every model, execute database updates
      # (Update entries based on the mapping)
      CrmMigrationHelper.perform_db_update(model, mapping)
      puts "Completed database updates for model #{model}"
    end
    puts 'All database updates complete.'
  end

  desc <<~DESC
    backup crm_keys to folder

    Needs an ENV-Var BACKUP_FOLDER to write the backups to.

    Optionally accepts SKIP_MODELS/ONLY_MODEL to select which models to process.
  DESC
  task backup_crm_keys: :environment do
    # Folder, where all the backup .csv reside
    backup_folder = ENV.fetch('BACKUP_FOLDER', nil)
    abort 'Error: ENV Var BACKUP_FOLDER cannot be empty' if backup_folder.nil?

    mkdir_p(backup_folder)

    models =
      if (only_model = ENV.fetch('ONLY_MODEL', nil)&.strip&.classify)
        [only_model]
      else
        all_models = %w[Client Employee Contact AdditionalCrmOrder Order]
        skip_models = ENV.fetch('SKIP_MODELS', '').split(',').map { _1.strip.classify }

        puts "All Models: #{all_models.join(', ')}"
        puts "Models to skip: #{skip_models.join(', ')}"

        all_models - skip_models
      end

    puts "Models to backup: #{models.join(', ')}"

    models.each do |model_name|
      # writes the generated mapping of (old_crm_key, new_crm_key) as a new line into the csv
      CSV.open(File.join(backup_folder, "#{model_name.underscore}.csv"), 'w') do |csv|
        csv << %w[id crm_key]
        model_name
          .constantize
          .pluck(:id, :crm_key)
          .uniq
          .each { csv << _1 }
      end
      puts "Created '#{model_name.underscore}.csv' with crm_key backups at #{backup_folder}"
    end
    puts 'All backups complete.'
  end

  desc <<~DESC
    restore backup crm_keys from folder

    Needs an ENV-Var BACKUP_FOLDER to read the backups from.

    Optionally accepts SKIP_MODELS/ONLY_MODEL to select which models to process.
  DESC
  task restore_crm_keys: :environment do
    # Folder, where all the backup .csv reside
    backup_folder = ENV.fetch('BACKUP_FOLDER', nil)
    abort 'Error: ENV Var BACKUP_FOLDER cannot be empty' if backup_folder.nil?
    backup_folder = Pathname.new(backup_folder)

    mkdir_p(backup_folder)

    models =
      if (only_model = ENV.fetch('ONLY_MODEL', nil)&.strip&.classify)
        [only_model]
      else
        all_models = %w[Client Employee Contact AdditionalCrmOrder Order]
        skip_models = ENV.fetch('SKIP_MODELS', '').split(',').map { _1.strip.classify }

        puts "All Models: #{all_models.join(', ')}"
        puts "Models to skip: #{skip_models.join(', ')}"

        all_models - skip_models
      end

    puts "Models to restore: #{models.join(', ')}"

    models.each do |model_name|
      # reads the crm_key mapping of (id, crm_key) from the csv

      path = backup_folder.join("#{model_name.underscore}.csv")
      CSV.read(path)[1..].each do |(id, crm_key)|
        model_name.constantize.find(id).update!(crm_key: crm_key)
        print '.'
      end
      puts
      puts "Restored crm_key backups for #{model_name} from #{backup_folder}"
    end

    puts 'All backups complete.'
  end
end

module CrmMigrationHelper
  module_function

  # Helper method which builds a hash table containing the mapping of (old_crm_key, new_crm_key) according to the specified .csv
  # arguments: [file_path] the file path to the .csv containing the mapping of (old_crm_key, new_crm_key)
  # returns: the hash table
  def build_mapping(file_path)
    mapping = {}
    CSV.foreach(file_path, headers: false) do |row|
      old_key = row[0]
      new_key = row[1]

      if old_key.nil? || new_key.nil? || old_key == ''
        puts "Skipping invalid row: #{row.inspect}"
        next
      end

      mapping[old_key.to_s] = new_key.to_s
    end

    mapping
  end

  # Helper method: Perform a dry run of the replacements of all crm_keys in a given model. If for one record none of the following apply
  #   - the crm_key in this record is NOT specified in the provided mapping
  #   - the old_crm_key in the provided mapping is nil or the empty string ''
  # then the crm_key of the current record is saved and the dry_run exits after iterating over all records in the current model
  # arguments: [model] the model object, for which the dry run should be executed
  #            [mapping] the hash table containing the mappings (old_crm_key, new_crm_key)
  # returns: -
  def perform_dry_run(model, mapping)
    missing_ids = []
    model.find_each do |entry|
      old_key = entry.crm_key.to_s
      missing_ids << entry.crm_key unless mapping.key?(old_key.to_i.to_s) || old_key.blank?
    end

    if missing_ids.any?
      abort "[#{model}] Dry-run detected the following missing crm_keys in the provided mapping (.csv):" + missing_ids.join(', ')
    else
      puts "[#{model}] Dry-run successful. All necessary mappings are present."
    end
  end

  # Helper method to perform the actual database update on a model according to a provided mapping. If a crm_key is '' or nil, this record is skipped and no changes are made to the crm_key.
  # Aborts with exit status 1 if it encounters a crm_key, which the mapping contains mapping for.
  # arguments: [model] the model object, for which the dry run should be executed
  #            [mapping] the hash table containing the mappings (old_crm_key, new_crm_key)
  # returns: -
  def perform_db_update(model, mapping)
    model.find_each do |entry|
      old_key = entry.crm_key.to_s
      if old_key.nil? || old_key == ''
        puts "[#{model}] skipping empty crm_key"
        next
      end

      if mapping.key?(old_key.to_i.to_s)
        new_id = mapping[entry.crm_key.to_i.to_s]
        entry.update!(crm_key: new_id)
        puts "[#{model}] Updated CRM KEY #{old_key} to #{new_id}"
      else
        pp entry
        abort "[#{model}] ERROR: #{old_key} not found in the mapping provided in the .csv! Aborting..."
      end
    end
  end
end
