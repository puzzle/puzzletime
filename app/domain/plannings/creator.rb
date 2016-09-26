# encoding: utf-8

module Plannings
  class Creator

    attr_reader :params, :errors, :plannings

    PERMITTED_ATTRIBUTES = [:id, :employee_id, :work_item_id, :date, :percent, :definitive]
    ITEM_FIELDS = [:employee_id, :work_item_id, :date]

    # params:
    # { planning: { percent: 50, definitive: true, repeat_until: '2016 42' },
    #   items: [
    #       { employee_id: 2, work_item_id: 3, date: '2016-03-01' }
    #   ] }
    def initialize(params)
      @params = params
    end

    def create_or_update
      Planning.transaction do
        return false unless form_valid?
        @plannings = update.concat(create)
        @errors.blank?
      end
    end

    def form_valid?
      @errors = []
      p = params[:planning]
      validate_present(p)
      if p.present?
        validate_create(p)
        validate_percent(p)
        validate_repeat(p)
      end
      @errors.blank?
    end

    def repeat_only?
      p = params[:planning]
      p[:repeat_until].present? && p[:percent].blank? &&
        p[:definitive].blank? && p[:definitive] != false
    end

    private

    def validate_create(p)
      if create? && !repeat_only?
        if p[:percent].blank?
          @errors << 'Prozent müssen angegeben werden, um neue Planungen zu erstellen'
        end
        if p[:definitive].blank? && p[:definitive] != false
          @errors << 'Status muss angegeben werden, um neue Planungen zu erstellen'
        end
      end
    end

    def validate_percent(p)
      if p[:percent].present? && p[:percent].to_i <= 0
        @errors << 'Prozent müssen grösser als 0 sein'
      end
    end

    def validate_repeat(p)
      if p[:repeat_until].present?
        week = Week.from_string(p[:repeat_until])
        unless week.valid?
          @errors << 'Wiederholungsdatum ist ungültig'
        end
      end
    end

    def validate_present(p)
      if p.blank? || (p[:percent].blank? &&
                      p[:definitive].blank? && p[:definitive] != false &&
                      p[:repeat_until].blank?)
        @errors << 'Bitte füllen Sie das Formular aus'
      end
    end

    def create?
      new_items_hashes.present?
    end

    def create
      return [] unless create?

      plannings = new_items_hashes.collect do |item|
        params = ActionController::Parameters.new(item).permit(PERMITTED_ATTRIBUTES)
        Planning.create(planning_params.merge(params))
      end

      handle_save_errors(plannings)

      plannings
    end

    def update
      existing_items.update_all(planning_params)
      existing_items.reload
    end

    def planning_params
      p = params[:planning].delete_if { |_k, v| v.blank? && v != false }
      ActionController::Parameters.new(p).permit(PERMITTED_ATTRIBUTES)
    end

    def handle_save_errors(plannings)
      save_errors = plannings.map { |p| p.errors.full_messages }.flatten.compact
      if save_errors.present?
        # should not happen after form validations
        @errors << 'Eintrag konnte nicht erstellt werden: ' + save_errors.uniq.join(', ')
        fail ActiveRecord::Rollback
      end
    end

    def new_items_hashes
      return [] unless params[:items].present?
      @new_items_hashes ||= params[:items].values - existing_items_hashes
    end

    def existing_items_hashes
      @existing_items_hashes ||= existing_items.pluck(*ITEM_FIELDS).map do |values|
        { 'employee_id'  => values.first.to_s,
          'work_item_id' => values.second.to_s,
          'date'         => values.third.strftime('%Y-%m-%d') }
      end
    end

    def existing_items
      return Planning.none unless params[:items].present?
      @existing_items ||= Planning.where(existing_items_condition(params[:items].values))
    end

    def existing_items_condition(items)
      table = Planning.arel_table
      items.collect do |item|
        ITEM_FIELDS.collect { |attr| table[attr].eq(item[attr]) }.reduce(:and)
      end.reduce(:or)
    end

  end
end
