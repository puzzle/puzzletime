# encoding: UTF-8

module DryCrud::Table
  # Provides headers with sort links. Expects a method :sortable?(attr)
  # in the template/controller to tell if an attribute is sortable or not.
  # Extracted into an own module for convenience.
  module Sorting
    # Create a header with sort links and a mark for the current sort
    # direction.
    def sort_header(attr, label = nil)
      label ||= attr_header(attr)
      template.sort_link(attr, label)
    end

    # Same as :attrs, except that it renders a sort link in the header
    # if an attr is sortable.
    def sortable_attrs(*attrs)
      attrs.each { |a| sortable_attr(a) }
    end

    # Renders a sort link header, otherwise similar to :attr.
    def sortable_attr(a, header = nil, &block)
      if template.sortable?(a)
        attr(a, sort_header(a, header), &block)
      else
        attr(a, header, &block)
      end
    end
  end
end
