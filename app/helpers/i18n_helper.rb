# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Translation helpers extending the Rails +translate+ helper to support
# translation inheritance over the controller class hierarchy.
module I18nHelper
  # Translates the passed key by looking it up over the controller hierarchy.
  # The key is searched in the following order:
  #  - {controller}.{current_partial}.{key}
  #  - {controller}.{current_action}.{key}
  #  - {controller}.global.{key}
  #  - {parent_controller}.{current_partial}.{key}
  #  - {parent_controller}.{current_action}.{key}
  #  - {parent_controller}.global.{key}
  #  - ...
  #  - global.{key}
  def translate_inheritable(key, variables = {})
    partial = defined?(@virtual_path) ? @virtual_path.gsub(%r{.*/_?}, '') : nil
    defaults = inheritable_translation_defaults(key, partial)
    variables[:default] ||= defaults
    t(defaults.shift, **variables)
  end

  alias ti translate_inheritable

  # Translates the passed key for an active record association. This helper is
  # used for rendering association dependent keys in forms like :no_entry,
  # :none_available or :please_select.
  # The key is looked up in the following order:
  #  - activerecord.associations.models.{model_name}.{association_name}.{key}
  #  - activerecord.associations.{association_model_name}.{key}
  #  - global.associations.{key}
  def translate_association(key, assoc = nil, variables = {})
    if assoc && assoc.options[:polymorphic].nil?
      variables[:default] ||= [association_klass_key(assoc, key).to_sym,
                               :"global.associations.#{key}"]
      t(association_owner_key(assoc, key), **variables)
    else
      t("global.associations.#{key}", **variables)
    end
  end

  alias ta translate_association

  private

  # General translation key based on the klass of the association.
  def association_klass_key(assoc, key)
    model_name = assoc.klass.model_name.singular
    "activerecord.associations.#{model_name}.#{key}"
  end

  # Specific translation key based on the owner model and the name
  # of the association.
  def association_owner_key(assoc, key)
    model_name = assoc.active_record.model_name.singular
    "activerecord.associations.models.#{model_name}.#{assoc.name}.#{key}"
  end

  def inheritable_translation_defaults(key, partial)
    defaults = []
    current = controller.class
    while current < ActionController::Base
      folder = current.controller_path
      append_controller_translation_keys(defaults, folder, partial, key) if folder.present?
      current = current.superclass
    end
    defaults << :"global.#{key}"
  end

  def append_controller_translation_keys(defaults, folder, partial, key)
    defaults << :"#{folder}.#{partial}.#{key}" if partial
    defaults << :"#{folder}.#{action_name}.#{key}"
    defaults << :"#{folder}.global.#{key}"
  end
end
