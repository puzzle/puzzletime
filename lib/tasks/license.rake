# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Licenser
  FORMATS = {
    rb: '#  ',
    rake: '#  ',
    yml: '#  ',
    haml: '-#  ',
    coffee: '#  ',
    scss: '//  '
  }.freeze

  EXCLUDES = %w[
    db/schema.rb
    config/boot.rb
    config/environment.rb
    config/settings/development.local.yml
    config/locales/devise.de.yml
    config/initializers/application_controller_renderer.rb
    config/initializers/assets.rb
    config/initializers/backtrace_silencers.rb
    config/initializers/cookies_serializer.rb
    config/initializers/filter_parameter_logging.rb
    config/initializers/inflections.rb
    config/initializers/mime_types.rb
    config/initializers/new_framework_defaults_5_1.rb
    config/initializers/session_store.rb
    config/initializers/wrap_parameters.rb
    vendor/
    tmp/
  ].freeze

  ENCODING_EXTENSIONS = %i[rb rake].freeze
  ENCODING_STRING     = '# encoding: utf-8'
  ENCODING_PATTERN    = /#\s*encoding: utf-8/i
  ENSURE_ENCODING     = false

  def initialize(project_name, copyright_holder, copyright_source)
    @project_name = project_name
    @copyright_holder = copyright_holder
    @copyright_source = copyright_source
  end

  def preamble_text
    @preamble_text ||= <<~END
      Copyright (c) 2006-#{Time.zone.today.year}, #{@copyright_holder}. This file is part of
      #{@project_name} and licensed under the Affero General Public License version 3
      or later. See the COPYING file at the top-level directory or at
      #{@copyright_source}.
    END
  end

  def insert
    each_file do |content, format|
      insert_preamble(content, format) unless format.preamble?(content)
    end
  end

  def update
    each_file do |content, format|
      remove_encoding(content, format) unless ENSURE_ENCODING
      content = remove_preamble(content, format) if format.preamble?(content)
      insert_preamble(content, format)
    end
  end

  def remove
    each_file do |content, format|
      remove_preamble(content, format) if format.preamble?(content)
    end
  end

  private

  def insert_preamble(content, format)
    remove_encoding(content, format)
    format.preamble + content
  end

  def remove_preamble(content, format)
    content.gsub!(/\A#{format.copyright_pattern}.*$/, '')
    content.gsub!(/\A\n#{format.comment}\s+.*$/, '') while content.start_with?("\n#{format.comment}")
    content.gsub!(/\A\s*\n/, '')
    content.gsub!(/\A\s*\n/, '')
    content = "#{ENCODING_STRING}\n\n#{content}" if format.file_with_encoding? && ENSURE_ENCODING
    content
  end

  def remove_encoding(content, format)
    return unless format.file_with_encoding? && content.strip =~ /\A#{ENCODING_PATTERN}/io

    content.gsub!(/\A#{ENCODING_PATTERN}\s*/mio, '')
  end

  def each_file
    FORMATS.each do |extension, prefix|
      format = Format.new(extension, prefix, preamble_text)

      Dir.glob("**/*.#{extension}")
         .reject { |file| EXCLUDES.any? { |path| file.start_with?(path) } }
         .each do |file|
           content = yield File.read(file), format
           if content
             puts file
             File.open(file, 'w') { |f| f.print content }
           end
         end
    end
  end

  class Format
    attr_reader :extension, :prefix, :copyright_pattern, :preamble

    def initialize(extension, prefix, preamble_text)
      @extension = extension
      @prefix = prefix
      @preamble = "#{preamble_text.each_line.collect { |l| prefix + l }.join}\n\n"
      @copyright_pattern = /#{prefix.strip}\s+Copyright/
      return unless file_with_encoding?

      @preamble = "#{ENCODING_STRING}\n\n" + @preamble if ENSURE_ENCODING
      @copyright_pattern = /(#{ENCODING_PATTERN}\n+)?#{@copyright_pattern}/
    end

    def file_with_encoding?
      ENCODING_EXTENSIONS.include?(extension)
    end

    def preamble?(content)
      content.strip =~ /\A#{copyright_pattern}/
    end

    def comment
      @comment ||= prefix.strip
    end
  end
end

namespace :license do
  task config: :environment do
    @licenser = Licenser.new('PuzzleTime',
                             'Puzzle ITC GmbH',
                             'https://github.com/puzzle/puzzletime')
  end

  desc 'Insert the license preamble in all source files'
  task insert: :config do
    @licenser.insert
  end

  desc 'Update or insert the license preamble in all source files'
  task update: :config do
    @licenser.update
  end

  desc 'Remove the license preamble from all source files'
  task remove: :config do
    @licenser.remove
  end
end
