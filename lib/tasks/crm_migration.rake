# frozen_string_literal: true

namespace :crm_migration do
  desc 'convenience task which creates a MOCK mapping between all the crm_keys found in the models Client Employee Contact AdditionalCrmOrder Order. Creates a .csv containing this mapping (default name: ids_map.csv)'
  task create_mock_data_mapping: :environment do
    models = %w[Client Employee Contact AdditionalCrmOrder Order]

    ids_map = []
    index = 0
    models.each do |model_name|
      model = model_name.constantize

      ids = model.where.not(crm_key: nil).pluck(:crm_key).uniq

      # Map each unique user_id to an index, starting from 0
      ids.each do |old_key|
        ids_map << [old_key, index]
        index += 1
      end
    end

    # writes the generated mapping of (old_crm_key, new_crm_key) as a new line into the csv
    CSV.open('ids_map.csv', 'w') do |csv|
      ids_map.each do |user_id, idx|
        csv << [user_id, idx] # Write each tuple as a row
      end
    end
  end

  desc 'given some .csv files mapping old crm_keys to new ones, apply this mapping to all crm_keys in the db'
  task substitute_crm_tokens: :environment do
    require 'csv'

    file_path = prompt_for_file_path

    # Step 1: Build the mapping from the CSV
    mapping = build_mapping(file_path)

    # Step 2: For every model, make dry run
    # (Verify that for every old crm_key there is a new crm_key, else abort)
    models = %w[Client Employee Contact AdditionalCrmOrder Order]
    models.each do |model_name|
      model = model_name.constantize
      perform_dry_run(model, mapping)
    end
    puts 'Completed all dry runs. Everything OK. Commencing database update...'

    # Step 3: For every model, execute database updates
    # (Update entries based on the mapping)
    models.each do |model_name|
      model = model_name.constantize
      perform_db_update(model, mapping)
      puts "Completed database updates for model #{model}"
    end
    puts 'All database update complete.'
  end

  # Helper method which prompts for the file path of the .csv which contains the mappings of (old_crm_key, new_crm_key)
  # arguments: -
  # returns: the file path that was provided by the user
  def prompt_for_file_path
    puts 'Enter the path to the CSV file (reading will NOT expect header line!):'
    file_path = $stdin.gets.chomp

    unless File.exist?(file_path)
      puts "File not found: #{file_path}"
      exit 1
    end

    file_path
  end

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
    model.find_each do |client|
      old_key = client.crm_key.to_s
      missing_ids << client.crm_key unless mapping.key?(old_key) || old_key.nil? || old_key == ''
    end

    if missing_ids.any?
      warn "[#{model}] Dry-run detected the following missing crm_keys in the provided mapping (.csv):" + missing_ids.join(', ')
      exit 1
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
    model.find_each do |client|
      old_key = client.crm_key.to_s
      if old_key.nil? || old_key == ''
        puts "[#{model}] skipping empty crm_key"
        next
      end

      if mapping.key?(old_key)
        new_id = mapping[client.crm_key.to_s]
        client.update!(crm_key: new_id)
        puts "[#{model}] Updated CRM KEY #{old_key} to #{new_id}"
      else
        warn "[#{model}] ERROR: #{old_key} not found in the mapping provided in the .csv! Aborting..."
        exit 1
      end
    end
  end
end
