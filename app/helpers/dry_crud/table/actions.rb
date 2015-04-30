# encoding: UTF-8

module DryCrud::Table
  # Adds action columns to the table builder.
  # Predefined actions are available for show, edit and destroy.
  # Additionally, a special col type to define cells linked to the show page
  # of the row entry is provided.
  module Actions
    extend ActiveSupport::Concern

    included do
      delegate :link_to, :link_to_if, :path_args, :polymorphic_path, :edit_polymorphic_path,
               :ti, :picon, :can?,
               to: :template
    end

    # Renders the passed attr with a link to the show action for
    # the current entry.
    # A block may be given to define the link path for the row entry.
    def attr_with_show_link(attr, &block)
      sortable_attr(attr) do |e|
        path = path_args(e)
        if can?(:edit, e)
          link_to(format_attr(e, attr), edit_polymorphic_path(path))
        elsif can?(:show, e)
          link_to(format_attr(e, attr), polymorphic_path(path))
        else
          format_attr(e, attr)
        end
      end
    end

    # Action column to show the row entry.
    # A block may be given to define the link path for the row entry.
    # If the block returns nil, no link is rendered.
    def show_action_col(html_options = {}, &block)
      action_col do |e|
        link_to_if(can?(:show, e), 'Anzeigen', path_args(e), html_options.clone)
      end
    end

    # Action column to edit the row entry.
    # A block may be given to define the link path for the row entry.
    # If the block returns nil, no link is rendered.
    def edit_action_col(html_options = {}, &block)
      html_options = html_options.merge(title: 'Bearbeiten')
      action_col do |e|
        path = path_args(e)
        if can?(:edit, e)
          table_action_link('edit', edit_polymorphic_path(path), html_options)
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
        table_action_link('delete', path_args(e), html_options) if can?(:destroy, e)
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

  end
end
