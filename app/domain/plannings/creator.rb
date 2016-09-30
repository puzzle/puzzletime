# encoding: utf-8

module Plannings
  class Creator

    attr_reader :params, :errors, :plannings

    PERMITTED_ATTRIBUTES = [
      :id,
      :employee_id,
      :work_item_id,
      :date,
      :percent,
      :definitive,
      :translate_by
    ].freeze
    ITEM_FIELDS = [:employee_id, :work_item_id, :date].freeze

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

        @plannings = []
        unless repeat_only?
          @plannings.push(*create)
          @plannings.push(*update)
        end
        repeat if repeat_until_week
        @plannings.push(*repeat) if repeat_until_week
        @plannings.uniq!

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

    def validate_repeat(_p)
      if repeat_until_week && !repeat_until_week.valid?
        @errors << 'Wiederholungsdatum ist ungültig'
      end
    end

    def validate_present(p)
      if p.blank? ||
          (p[:percent].blank? &&
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
      if planning_params[:translate_by].present?
        existing_items.each do |item|
          item.update!(
            planning_params.merge(
              date: item.date + planning_params[:translate_by].days
            )
          )
        end
      else
        existing_items.update_all(planning_params)
      end

      existing_items.reload
    end

    def repeat
      dates = repetition_source.collect(&:date).sort
      interval = Period.new(dates.first.at_beginning_of_week, dates.last.at_end_of_week)
      end_date = repeat_until_week.to_date + 6.days
      if end_date > interval.end_date
        create_repetitions(interval, end_date)
      else
        []
      end
    end

    def create_repetitions(interval, end_date)
      repetitions = (end_date - interval.start_date).to_i / interval.length.to_i
      repetitions.times.map do |i|
        offset = ((i + 1) * interval.length).days
        repeat_plannings(offset, end_date)
      end.flatten
    end

    def repeat_plannings(offset, end_date)
      repetition_source.map do |planning|
        date = planning.date + offset
        next if date > end_date

        p = Planning.where(employee_id: planning.employee_id,
                           work_item_id: planning.work_item_id,
                           date: date).first_or_initialize
        p.percent = planning.percent
        p.definitive = planning.definitive
        p.save!
        p
      end
    end

    def repetition_source
      @plannings.presence || existing_items
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
      return [] unless items.present?
      @new_items_hashes ||= items - existing_items_hashes
    end

    def existing_items_hashes
      @existing_items_hashes ||= existing_items.pluck(*ITEM_FIELDS).map do |values|
        { 'employee_id'  => values.first.to_s,
          'work_item_id' => values.second.to_s,
          'date'         => values.third.strftime('%Y-%m-%d') }
      end
    end

    def existing_items
      return Planning.none unless items.present?
      @existing_items ||= Planning.where(existing_items_condition)
    end

    def existing_items_condition
      table = Planning.arel_table
      items.collect do |item|
        ITEM_FIELDS.collect { |attr| table[attr].eq(item[attr.to_s]) }.reduce(:and)
      end.reduce(:or)
    end

    def items
      @items ||= (params[:items] || []).collect(&:stringify_keys)
    end

    def repeat_until_week
      r = params[:planning][:repeat_until]
      @repeat_until_week ||= Week.from_string(r) if r.present?
    end

  end
end
