# frozen_string_literals: true
# rubocop:disable Rails/Output

# Task helper for the reuploading of ActiveRecord Attachments
class StorageReupload
  def initialize(from:, to: nil)
    @from_service = load_storage_service(from.to_sym)
    @to_service = load_storage_service(to&.to_sym)
  end

  def all
    print_header

    models.each do |model|
      reupload_model(model)
    end

    print_footer
  end

  private

  def reupload_model(model)
    attachment_types_for(model).each do |type|
      reupload_type(model, type)
    end

    print_model_footer(model)
  end

  def reupload_type(model, type)
    collection = model.send("with_attached_#{type}")

    print_type_header(model, type, collection.count)

    collection.find_each do |item|
      reupload(item)
    end

    print_type_footer(model, type)
  end

  def reupload(item)
    attachment = item.send(type)
    blob = attachment.blob

    Tempfile.create(binmode: true) do |temp|
      content = @from_service.download(blob.key)
      temp.write(content)
      attachment.attach(io: temp, filename: blob.filename)
    end

    print '.'
  end

  def models
    ActiveRecord::Base
      .descendants
      .reject { |model| blob_model?(model) }
      .select { |model| attachment?(model) }
  end

  def print_header
    puts "Reuploading #{models.count} models"
    models.each { |model| puts "  #{model}" }
    puts "\n\n"
  end

  def print_footer
    puts "\n\n"
    puts 'All Reuploads completed!'
  end

  # This method smells of :reek:DuplicateMethodCall
  def print_type_header(model, type, count)
    divider = '=' * 20
    puts divider
    puts "Reupload for #{model}/#{type}"
    puts divider
    print "  #{count} attachments to process: "
  end

  def print_type_footer(model, type)
    puts "\n  Reupload for #{model}/#{type} completed!\n\n"
  end

  def print_model_footer(model)
    puts "\nReupload for #{model}completed!\n"
  end

  class << self
    private

    def load_storage_service(service)
      service ||= Rails.configuration.active_storage.service

      erb = ERB.new(Rails.root.join('config/storage.yml').read).result
      yaml = YAML.safe_load(erb)
      configs = ActiveStorage::Service::Configurator.new(yaml).configurations

      ActiveStorage::Service.configure(service, configs)
    end

    def attachment_types_for(model)
      model
        .methods
        .collect { |method| method.to_s.match(/^with_attached_(\w+)$/)&.captures&.first }
        .compact
    end

    def blob_model?(model)
      model.model_name.element == 'blob'
    end

    def attachment?(model)
      model.reflect_on_all_associations.any? do |assoc|
        assoc.class_name == 'ActiveStorage::Attachment'
      end
    end
  end
end

# rubocop:enable Rails/Output
