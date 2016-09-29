module CustomListsHelper

  def format_custom_list_item_type(list)
    t("activerecord.models.#{list.item_type.underscore}.other")
  end

end