# frozen_string_literal: true

module Apidocs
  class TagsSetup
    def initialize(swagger_doc = nil)
      @swagger_doc = swagger_doc
    end

    def run
      setup_tags
    end

    def self.path_tag(path)
      new.get_tag_by_path(path)
    end

    def get_tag_by_path(path)
      tags.each do |tag|
        next if tag['include'].blank?

        tag['include'].each do |inc|
          return tag['name'] if path =~ /#{inc}/i
        end
      end
    end

    private

    def setup_tags
      tags.each do |tag|
        @swagger_doc.tags tag.slice('name', 'description', 'externalDocs')
      end
    end

    def tags
      @tags ||= load_tags['tags']
    end

    def load_tags
      require 'yaml'
      YAML.load_file(Rails.root.join('config', 'swagger-tags.yml')) # TODO: what is this for? fill yml with sensible values
    end
  end
end
