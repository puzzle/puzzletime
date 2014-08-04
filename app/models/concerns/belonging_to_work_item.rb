module BelongingToWorkItem

  extend ActiveSupport::Concern

  included do
    belongs_to :work_item, validate: true, autosave: true

    has_descendants_through_work_item :worktimes

    accepts_nested_attributes_for :work_item, update_only: true

    scope :list, -> do
      includes(:work_item).
      references(:work_item).
      order('work_items.path_names')
    end
  end

  def to_s
    work_item.to_s if work_item
  end

  module ClassMethods
    def has_ancestor_through_work_item(name)
      model = name.to_s.classify.constantize
      define_method(name) do
        model.joins('LEFT JOIN work_items ON ' \
                    "#{model.table_name}.work_item_id = ANY (work_items.path_ids)").
              where('work_items.id = ?', work_item_id).
              first
      end
    end

    def has_descendants_through_work_item(name)
      model = name.to_s.classify.constantize
      define_method(name) do
        model.joins(:work_item).
              where("? = ANY (work_items.path_ids)", work_item_id)
      end
    end
  end


end