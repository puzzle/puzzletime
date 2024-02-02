# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Defines forms to edit models. The helper methods come in different
# granularities:
# * #plain_form - A form using Crud::FormBuilder.
# * #standard_form - A #plain_form for a given object and attributes with error
#   messages and save and cancel buttons.
# * #crud_form - A #standard_form for the current +entry+, with the given
#   attributes or default.
module FormHelper
  # Renders a form using Crud::FormBuilder.
  def plain_form(object, options = {}, &)
    options[:html] ||= {}
    add_css_class(options[:html], 'form-horizontal')
    options[:html][:role] ||= 'form'
    options[:builder] ||= DryCrud::Form::Builder
    options[:cancel_url] ||= default_cancel_url(object) unless options[:cancel_url] == false
    if request.format.js?
      options[:data] ||= {}
      options[:data][:remote] = true
    end

    form_for(object, options, &)
  end

  # Renders a standard form for the given entry and attributes.
  # The form is rendered with a basic save and cancel button.
  # If a block is given, custom input fields may be rendered and attrs is
  # ignored. Before the input fields, the error messages are rendered,
  # if present. An options hash may be given as the last argument.
  def standard_form(object, *attrs, &block)
    plain_form(object, attrs.extract_options!) do |form|
      content = form.error_messages

      content << if block
                   capture(form, &block)
                 else
                   form.labeled_input_fields(*attrs)
                 end

      content << form.standard_actions
      content.html_safe
    end
  end

  # Renders a crud form for the current entry with default_crud_attrs or the
  # given attribute array. An options hash may be given as the last argument.
  # If a block is given, a custom form may be rendered and attrs is ignored.
  def crud_form(*attrs, &)
    options = attrs.extract_options!
    attrs = default_crud_attrs - %i[created_at updated_at] if attrs.blank?
    attrs << options
    standard_form(path_args(entry), *attrs, &)
  end

  def spinner
    image_tag('ajax-loader.gif', size: '16x16', class: 'spinner', alt: 'Lädt...', style: 'display: none;')
  end

  private

  def default_cancel_url(object)
    url_object = Array(object).clone
    url_object[-1] = url_object[-1].class if url_object[-1].is_a?(ActiveRecord::Base)
    polymorphic_url(url_object, returning: true)
  end
end
