#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module DryCrud::Form
  # A form builder that automatically selects the corresponding input field
  # for ActiveRecord column types. Convenience methods for each column type
  # allow one to customize the different fields.
  #
  # All field methods may be prefixed with +labeled_+ in order to render
  # a standard label, required mark and an optional help block with them.
  #
  # Use #labeled_input_field or #input_field to render a input field
  # corresponding to the given attribute.
  #
  # See the Control class for how to customize the html rendered for a
  # single input field.
  class Builder < ActionView::Helpers::FormBuilder
    class_attribute :control_class
    self.control_class = Control

    attr_reader :template

    delegate :association, :column_type, :column_property, :captionize,
             :ti, :ta, :link_to, :content_tag, :safe_join, :capture,
             :add_css_class, :assoc_and_id_attr, :icon,
             to: :template

    ### INPUT FIELDS

    # Render multiple input controls together with a label for the given
    # attributes.
    def labeled_input_fields(*attrs)
      options = attrs.extract_options!
      safe_join(attrs) { |a| labeled_input_field(a, options.dup) }
    end

    # Render a corresponding input control and label for the given attribute.
    # The input field is chosen based on the ActiveRecord column type.
    #
    # The following options may be passed:
    # * <tt>:addon</tt> - Addon content displayd just after the input field.
    # * <tt>:help</tt> - A help text displayd below the input field.
    # * <tt>:span</tt> - Number of columns the input field should span.
    # * <tt>:caption</tt> - Different caption for the label.
    # * <tt>:field_method</tt> - Different method to create the input field.
    #
    # Use additional html_options for the input element.
    def labeled_input_field(attr, html_options = {})
      control_class.new(self, attr, html_options).render_labeled
    end

    # Render a corresponding input control for the given attribute.
    # The input field is chosen based on the ActiveRecord column type.
    #
    # The following options may be passed:
    # * <tt>:addon</tt> - Addon content displayd just after the input field.
    # * <tt>:help</tt> - A help text displayd below the input field.
    # * <tt>:span</tt> - Number of columns the input field should span.
    # * <tt>:field_method</tt> - Different method to create the input field.
    #
    # Use additional html_options for the input element.
    def input_field(attr, html_options = {})
      control_class.new(self, attr, html_options).render_content
    end

    # Render a standard string field with column contraints.
    def string_field(attr, html_options = {})
      html_options[:maxlength] ||= column_property(@object, attr, :limit)
      html_options[:size] ||= 30
      text_field(attr, html_options)
    end

    def text_field(attr, html_options = {})
      add_css_class(html_options, 'form-control')
      super(attr, html_options)
    end

    def email_field(attr, html_options = {})
      add_css_class(html_options, 'form-control')
      super(attr, html_options)
    end

    # Render a boolean field.
    def boolean_field(attr, html_options = {})
      content_tag(:div, class: 'checkbox') do
        content_tag(:label) do
          detail = html_options.delete(:detail) || '&nbsp;'.html_safe
          safe_join([check_box(attr, html_options), ' ', detail])
        end
      end
    end

    # Customize the standard text area to have 5 rows by default.
    def text_area(attr, html_options = {})
      html_options[:rows] ||= 5
      html_options[:cols] ||= 50
      add_css_class(html_options, 'form-control')
      super
    end

    # Render a field to select a date.
    def date_field(attr, html_options = {})
      format = html_options[:data] && html_options[:data][:format]
      date = date_value(attr, format)
      html_options[:size] = 15
      html_options[:value] = date
      add_css_class(html_options, 'date')
      with_addon(text_field(attr, html_options), icon(:calendar))
    end

    def date_value(attr, format)
      raw = nil
      raw = @object._timeliness_raw_value_for(attr.to_s) if @object.respond_to?(:_timeliness_raw_value_for)
      if raw.is_a?(String)
        raw
      else
        val = @object.send(attr)
        val.is_a?(Date) ? template.l(val, format:) : val
      end
    end

    def number_field(attr, html_options = {})
      html_options[:size] ||= 15
      html_options[:type] ||= 'number'
      html_options[:step] ||= 'any'
      html_options[:lang] ||= 'de-CH'
      text_field(attr, html_options)
    end

    alias integer_field number_field
    alias float_field number_field
    alias decimal_field number_field

    def enum_field(attr, html_options = {})
      add_css_class(html_options, 'form-control')
      attr_s = attr.to_s
      list = object.class.defined_enums[attr_s].map do |key, _value|
        [key,
         object.class.human_attribute_name([attr_s.pluralize, key].join('.'))]
      end
      collection_select(attr, list, :first, :second,
                        select_options(attr, html_options),
                        html_options)
    end

    # Render a select element for a :belongs_to association defined by attr.
    # Use additional html_options for the select element.
    # To pass a custom element list, specify the list with the :list key or
    # define an instance variable with the pluralized name of the association.
    def belongs_to_field(attr, html_options = {})
      list = association_entries(attr, html_options).to_a
      if list.present?
        add_css_class(html_options, 'form-control')
        collection_select(attr, list, :id, :to_s,
                          select_options(attr, html_options),
                          html_options)
      else
        static_text(ta(:none_available, association(@object, attr)).html_safe)
      end
    end

    # Render a multi select element for a :has_many or :has_and_belongs_to_many
    # association defined by attr.
    # Use additional html_options for the select element.
    # To pass a custom element list, specify the list with the :list key or
    # define an instance variable with the pluralized name of the association.
    def has_many_field(attr, html_options = {})
      html_options[:multiple] = true
      add_css_class(html_options, 'multiselect')
      belongs_to_field(attr, html_options)
    end

    ### VARIOUS FORM ELEMENTS

    # Render the error messages for the current form.
    def error_messages
      @template.render('shared/error_messages',
                       errors: @object.errors,
                       object: @object)
    end

    # Renders the given content with an addon.
    def with_addon(content, addon)
      content_tag(:div, class: 'input-group') do
        content + content_tag(:span, addon, class: 'input-group-addon')
      end
    end

    def static_field(attr, html_options = {})
      static_text(@template.format_attr(@object, attr), html_options)
    end

    # Renders a static text where otherwise form inputs appear.
    def static_text(text, html_options = {})
      add_css_class(html_options, 'form-control-static')
      content_tag(:p, text, html_options)
    end

    # Generates a help block for fields
    def help_block(text)
      content_tag(:p, text, class: 'help-block col-md-5')
    end

    # Render a submit button and a cancel link for this form.
    def standard_actions(submit_label = ti('button.save'), cancel_url = nil)
      content_tag(:div, class: 'form-group') do
        content_tag(:div, class: 'col-md-offset-2 col-md-8') do
          safe_join([submit_button(submit_label), cancel_link(cancel_url)], ' ')
        end
      end
    end

    # Render only a submit button for this form.
    def submit_action(submit_label = ti('button.save'))
      content_tag(:div, class: 'form-group') do
        content_tag(:div, class: 'col-md-offset-2 col-md-8') do
          submit_button(submit_label)
        end
      end
    end

    # Render a standard submit button with the given label.
    def submit_button(label = ti('button.save'))
      button(label, class: 'btn btn-primary', data: { disable_with: label })
    end

    # Render a cancel link pointing to the given url.
    def cancel_link(url = nil)
      url ||= cancel_url
      link_to(ti('button.cancel'), url, class: 'cancel') unless url == false
    end

    # Depending if the given attribute must be present, return
    # only an initial selection prompt or a blank option, respectively.
    def select_options(attr, options = {})
      prompt = options.delete(:prompt)
      blank = options.delete(:include_blank)
      if options[:multiple]
        {}
      elsif prompt
        { prompt: }
      elsif blank
        { include_blank: blank }
      else
        assoc = association(@object, attr)
        if required?(attr)
          { prompt: ta(:please_select, assoc) }
        else
          { include_blank: ta(:no_entry, assoc) }
        end
      end
    end

    # Returns true if the given attribute must be present.
    def required?(attr)
      attr, attr_id = assoc_and_id_attr(attr)
      validators = @object.class.validators_on(attr) +
                   @object.class.validators_on(attr_id)
      validators.any? do |v|
        v.kind == :presence &&
          !v.options.key?(:if) &&
          !v.options.key?(:unless)
      end
    end

    # Returns true if any errors are found on the passed attribute or its
    # association.
    def errors?(attr)
      attr_plain, attr_id = assoc_and_id_attr(attr)
      # errors aint a Hash
      @object.errors.key?(attr_plain.to_sym) ||
        @object.errors.key?(attr_id.to_sym)
    end

    # Render a label for the given attribute with the passed content.
    # The content may be given as an argument or as a block:
    #   labeled(:attr) { #content }
    #   labeled(:attr, content)
    #
    # The following options may be passed:
    # * <tt>:span</tt> - Number of columns the content should span.
    # * <tt>:caption</tt> - Different caption for the label.
    def labeled(attr, content = {}, options = {}, &)
      if block_given?
        options = content
        content = capture(&)
      end
      control = control_class.new(self, attr, options)
      control.render_labeled(content)
    end

    # Dispatch methods starting with 'labeled_' to render a label and the
    # corresponding input field.
    # E.g. labeled_boolean_field(:checked, class: 'bold')
    # To add an additional help text, use the help option.
    # E.g. labeled_boolean_field(:checked, help: 'Some Help')
    def method_missing(name, *)
      field_method = labeled_field_method?(name)
      if field_method
        build_labeled_field(field_method, *)
      else
        super(name, *)
      end
    end

    # Overriden to fullfill contract with method_missing 'labeled_' methods.
    def respond_to?(name, include_all = false)
      labeled_field_method?(name).present? || super(name, include_all)
    end

    private

    # Checks if the passed name corresponds to a field method with a
    # 'labeled_' prefix.
    def labeled_field_method?(name)
      prefix = 'labeled_'
      return unless name.to_s.start_with?(prefix)

      field_method = name.to_s[prefix.size..-1]
      field_method if respond_to?(field_method)
    end

    # Renders the corresponding field together with a label, required mark and
    # an optional help block.
    def build_labeled_field(field_method, *args)
      options = args.extract_options!
      options[:field_method] = field_method
      control_class.new(self, *(args << options)).render_labeled
    end

    # Returns the list of association entries, either from options[:list] or
    # the instance variable with the pluralized association name.
    # Otherwise, if the association defines a #options_list or #list scope,
    # this is used to load the entries.
    # As a last resort, all entries from the association class are returned.
    def association_entries(attr, options)
      list = options.delete(:list)
      unless list
        assoc = association(@object, attr)
        list = @template.send(:instance_variable_get,
                              :"@#{assoc.name.to_s.pluralize}")
        list ||= load_association_entries(assoc)
      end
      list
    end

    # Automatically load the entries for the given association.
    def load_association_entries(assoc)
      klass = assoc.klass
      list = klass.all
      list = list.merge(assoc.scope) if assoc.scope
      # Use special scopes if they are defined
      if klass.respond_to?(:options_list)
        list.options_list
      elsif klass.respond_to?(:list)
        list.list
      else
        list
      end
    end

    # Get the cancel url for the given object considering options:
    # 1. Use :cancel_url_new or :cancel_url_edit option, if present
    # 2. Use :cancel_url option, if present
    def cancel_url
      url = if @object.new_record?
              options[:cancel_url_new]
            else
              options[:cancel_url_edit]
            end
      url || options[:cancel_url]
    end
  end
end
