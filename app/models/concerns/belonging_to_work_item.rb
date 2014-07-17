module BelongingToWorkItem

  extend ActiveSupport::Concern

  included do
    belongs_to :work_item
  end


  module ClassMethods
    def has_one_through_work_item(name)
      # TODO check if correct
      table = name.to_s.classify.constantize.table_name
      has_one name,
              ->(entry) do
                joins(:work_item).
                where("#{table}.work_item_id = ANY (work_items.path_ids)")
              end
    end

    def has_many_through_work_item(name)
      # TODO check if correct
      table = name.to_s.classify.constantize.table_name
      has_many name,
               ->(entry) do
                 joins(:work_item).
                 unscope(where: :work_item_id).
                 where("#{table}.work_item_id = work_items.id AND "\
                       "? = ANY (work_items.path_ids)", entry.work_item_id)
               end
      end

  end


end