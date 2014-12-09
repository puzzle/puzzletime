# encoding: UTF-8

module DryCrud::Table
  # Adds action columns to the table builder.
  # Predefined actions are available for show, edit and destroy.
  # Additionally, a special col type to define cells linked to the show page
  # of the row entry is provided.
  module Actions
    extend ActiveSupport::Concern

    included do
      delegate :link_to, :path_args, :edit_polymorphic_path, :ti, :picon,
               to: :template
    end

    # Renders the passed attr with a link to the show action for
    # the current entry.
    # A block may be given to define the link path for the row entry.
    def attr_with_show_link(attr, &block)
      sortable_attr(attr) do |e|
        path = action_path(e, &block)
        path = edit_polymorphic_path(path) unless path.is_a?(String)
        link_to(format_attr(e, attr), path)
      end
    end

    # Action column to show the row entry.
    # A block may be given to define the link path for the row entry.
    # If the block returns nil, no link is rendered.
    def show_action_col(html_options = {}, &block)
      action_col do |e|
        path = action_path(e, &block)
        link_to('Anzeigen', path, html_options.clone) if path
      end
    end

    # Action column to edit the row entry.
    # A block may be given to define the link path for the row entry.
    # If the block returns nil, no link is rendered.
    def edit_action_col(html_options = {}, &block)
      html_options = html_options.merge(title: 'Bearbeiten')
      action_col do |e|
        path = action_path(e, &block)
        if path
          path = path.is_a?(String) ? path : edit_polymorphic_path(path)
          table_action_link('edit', path, html_options)
        end
      end
    end

    # Action column to destroy the row entry.
    # A block may be given to define the link path for the row entry.
    # If the block returns nil, no link is rendered.
    def destroy_action_col(html_options = {}, &block)
      html_options = html_options.merge(title: 'Löschen',
                                        data: { confirm: ti(:confirm_delete),
                                                method: :delete })
      action_col do |e|
        path = action_path(e, &block)
        table_action_link('delete', path, html_options) if path
      end
    end

    # Action column inside a table. No header.
    # The cell content should be defined in the passed block.
    def action_col(&block)
      col('', class: 'action', &block)
    end

    # Generic action link inside a table.
    def table_action_link(icon, url, html_options = {})
      link_to(picon(icon), url, html_options)
    end

    private

    # If a block is given, call it to get the path for the current row entry.
    # Otherwise, return the standard path args.
    def action_path(e, &block)
      block_given? ? yield(e) : path_args(e)
    end
  end
end
