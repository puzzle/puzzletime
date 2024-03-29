# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require 'support/crud_test_model'

# Test DryCrud::Form::Builder
module DryCrud
  module Form
    class BuilderTest < ActionView::TestCase
      include FormatHelper
      include I18nHelper
      include CrudTestHelper

      # set dummy helper class for ActionView::TestCase
      self.helper_class = UtilityHelper

      attr_reader :form, :entry

      setup :reset_db, :setup_db, :create_test_data, :create_form
      teardown :reset_db

      def create_form
        @entry = CrudTestModel.first
        @form = if Rails.version < '4.0'
                  DryCrud::Form::Builder.new(:entry, @entry, self, {},
                                             ->(form) { form })
                else
                  DryCrud::Form::Builder.new(:entry, @entry, self, {})
                end
      end

      test 'input_field dispatches string attr to string_field' do
        assert_equal form.string_field(:name, required: 'required'),
                     form.input_field(:name)
        assert_predicate form.string_field(:name), :html_safe?
      end

      test 'input_field dispatches password attr to password_field' do
        assert_equal form.password_field(:password),
                     form.input_field(:password)
        assert_predicate form.password_field(:name), :html_safe?
      end

      test 'input_field dispatches email attr to email_field' do
        assert_equal form.email_field(:email),
                     form.input_field(:email)
        assert_predicate form.email_field(:name), :html_safe?
      end

      test 'input_field dispatches text attr to text_area' do
        assert_equal form.text_area(:remarks),
                     form.input_field(:remarks)
        assert_predicate form.text_area(:remarks), :html_safe?
      end

      test 'input_field dispatches integer attr to integer_field' do
        assert_equal form.integer_field(:children),
                     form.input_field(:children)
        assert_predicate form.integer_field(:children), :html_safe?
      end

      test 'input_field dispatches boolean attr to boolean_field' do
        assert_equal form.boolean_field(:human),
                     form.input_field(:human)
        assert_predicate form.boolean_field(:human), :html_safe?
      end

      test 'input_field dispatches date attr to date_field' do
        assert_equal form.date_field(:birthdate),
                     form.input_field(:birthdate)
        assert_predicate form.date_field(:birthdate), :html_safe?
      end

      test 'input_field dispatches belongs_to attr to select field' do
        assert_equal form.belongs_to_field(:companion_id),
                     form.input_field(:companion_id)
        assert_predicate form.belongs_to_field(:companion_id), :html_safe?
      end

      test 'input_field dispatches has_and_belongs_to_many attr to select field' do
        assert_equal form.has_many_field(:other_ids),
                     form.input_field(:other_ids)
        assert_predicate form.has_many_field(:other_ids), :html_safe?
      end

      test 'input_field dispatches has_many attr to select field' do
        assert_equal form.has_many_field(:more_ids),
                     form.input_field(:more_ids)
        assert_predicate form.has_many_field(:more_ids), :html_safe?
      end

      test 'input_fields concats multiple fields' do
        result = form.labeled_input_fields(:name, :remarks, :children)

        assert_predicate result, :html_safe?
        assert_includes result, form.input_field(:name, required: 'required')
        assert_includes result, form.input_field(:remarks)
        assert_includes result, form.input_field(:children)
      end

      if false
        test 'labeld_input_field adds required mark' do
          result = form.labeled_input_field(:name)

          assert_includes result, 'input-group-addon'
          result = form.labeled_input_field(:remarks)

          assert_not result.include?('input-group-addon')
        end
      end

      if false
        test 'labeld_input_field adds help text' do
          result = form.labeled_input_field(:name, help: 'Some Help')

          assert_includes result, form.help_block('Some Help')
          assert_includes result, 'input-group-addon'
        end
      end

      test 'belongs_to_field has all options by default' do
        f = form.belongs_to_field(:companion_id)

        assert_equal 7, f.scan('</option>').size
      end

      test 'belongs_to_field with :list option' do
        list = CrudTestModel.all
        f = form.belongs_to_field(:companion_id,
                                  list: [list.first, list.second])

        assert_equal 3, f.scan('</option>').size
      end

      test 'belongs_to_field with instance variable' do
        list = CrudTestModel.all
        @companions = [list.first, list.second]
        f = form.belongs_to_field(:companion_id)

        assert_equal 3, f.scan('</option>').size
      end

      test 'belongs_to_field with empty list' do
        @companions = []
        f = form.belongs_to_field(:companion_id)

        assert_match t('global.associations.none_available'), f
        assert_equal 0, f.scan('</option>').size
      end

      test 'has_and_belongs_to_many_field has all options by default' do
        f = form.has_many_field(:other_ids)

        assert_equal 6, f.scan('</option>').size
      end

      test 'has_and_belongs_to_many_field with :list option' do
        list = OtherCrudTestModel.all
        f = form.has_many_field(:other_ids, list: [list.first, list.second])

        assert_equal 2, f.scan('</option>').size
      end

      test 'has_and_belongs_to_many_field with instance variable' do
        list = OtherCrudTestModel.all
        @others = [list.first, list.second]
        f = form.has_many_field(:other_ids)

        assert_equal 2, f.scan('</option>').size
      end

      test 'has_and_belongs_to_many_field with empty list' do
        @others = []
        f = form.has_many_field(:other_ids)

        assert_match t('global.associations.none_available'), f
        assert_equal 0, f.scan('</option>').size
      end

      test 'has_many_field has all options by default' do
        f = form.has_many_field(:more_ids)

        assert_equal 6, f.scan('</option>').size
      end

      test 'has_many_field with :list option' do
        list = OtherCrudTestModel.all
        f = form.has_many_field(:more_ids, list: [list.first, list.second])

        assert_equal 2, f.scan('</option>').size
      end

      test 'has_many_field with instance variable' do
        list = OtherCrudTestModel.all
        @mores = [list.first, list.second]
        f = form.has_many_field(:more_ids)

        assert_equal 2, f.scan('</option>').size
      end

      test 'has_many_field with empty list' do
        @mores = []
        f = form.has_many_field(:more_ids)

        assert_match t('global.associations.none_available'), f
        assert_equal 0, f.scan('</option>').size
      end

      test 'string_field sets maxlength attribute if limit' do
        assert_match(/maxlength="50"/, form.string_field(:name))
      end

      test 'label creates captionized label' do
        assert_match(/label [^>]*for.+Gugus dada/, form.label(:gugus_dada))
        assert_predicate form.label(:gugus_dada), :html_safe?
      end

      test 'classic label still works' do
        assert_match(/label [^>]*for.+hoho/, form.label(:gugus_dada, 'hoho'))
        assert_predicate form.label(:gugus_dada, 'hoho'), :html_safe?
      end

      test 'labeled_text_field create label' do
        assert_match(/label [^>]*for.+input/m, form.labeled_string_field(:name))
        assert_predicate form.labeled_string_field(:name), :html_safe?
      end

      test 'labeled field creates label' do
        result = form.labeled('gugus',
                              "<input type='text' name='gugus' />".html_safe)

        assert_predicate result, :html_safe?
        assert_match(/label [^>]*for.+<input/m, result)
      end

      test 'labeled field creates label and block' do
        result = form.labeled('gugus') do
          "<input type='text' name='gugus' />".html_safe
        end

        assert_predicate result, :html_safe?
        assert_match(/label [^>]*for.+<input/m, result)
      end

      test 'labeled field creates label with caption' do
        result = form.labeled('gugus',
                              "<input type='text' name='gugus' />".html_safe,
                              caption: 'Caption')

        assert_predicate result, :html_safe?
        assert_match(%r{label [^>]*for.+>Caption</label>.*<input}m, result)
      end

      test 'labeled field creates label with caption and block' do
        result = form.labeled('gugus', caption: 'Caption') do
          "<input type='text' name='gugus' />".html_safe
        end

        assert_predicate result, :html_safe?
        assert_match(%r{label [^>]*for.+>Caption</label>.*<input}m, result)
      end

      test 'method missing still works' do
        assert_raise(NoMethodError) do
          form.blabla
        end
      end

      test 'respond to still works' do
        assert_not form.respond_to?(:blalba)
        assert_respond_to form, :text_field
        assert_respond_to form, :labeled_text_field
      end
    end
  end
end
