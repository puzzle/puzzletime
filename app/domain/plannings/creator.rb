#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Plannings
  class Creator
    attr_reader :params, :errors, :plannings

    PERMITTED_ATTRIBUTES = %i[id employee_id work_item_id date percent definitive
                              translate_by].freeze
    ITEM_FIELDS = %i[employee_id work_item_id date].freeze

    # params:
    # { planning: { percent: 50, definitive: true, repeat_until: '2016 42', translate_by: -3 },
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
          @plannings = @plannings.concat(create)
          @plannings = @plannings.concat(update)
        end
        @plannings = @plannings.concat(repeat) if repeat_until_week
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
        validate_work_items(p)
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
      return unless create? && !repeat_only?

      @errors << 'Prozent müssen angegeben werden, um neue Planungen zu erstellen' if p[:percent].blank?
      return unless p[:definitive].blank? && p[:definitive] != false

      @errors << 'Status muss angegeben werden, um neue Planungen zu erstellen'
    end

    def validate_percent(p)
      return unless p[:percent].present? && p[:percent].to_i <= 0

      @errors << 'Prozent müssen grösser als 0 sein'
    end

    def validate_repeat(_p)
      return unless repeat_until_week && !repeat_until_week.valid?

      @errors << 'Wiederholungsdatum ist ungültig'
    end

    def validate_present(p)
      if p.blank? ||
         (p[:percent].blank? &&
          p[:definitive].blank? && p[:definitive] != false &&
          p[:repeat_until].blank? &&
          p[:translate_by].blank?)
        @errors << 'Bitte füllen Sie das Formular aus'
      end
    end

    def validate_work_items(_p)
      return unless create?

      work_item_ids = new_items_hashes.map { |item| item['work_item_id'] }.compact.uniq
      return if work_item_ids.blank?

      items = WorkItem.joins(:accounting_post).where(id: work_item_ids)
      return if work_item_ids.length == items.count

      @errors << 'Nur Positionen mit Buchungsposition sind möglich'
    end

    def create?
      new_items_hashes.present?
    end

    def create
      return [] unless create?

      plannings = new_items_hashes.collect do |item|
        params = convert_to_parameters(item).permit(PERMITTED_ATTRIBUTES)
        Planning.create(planning_params.merge(params))
      end

      handle_save_errors(plannings)

      plannings
    end

    def update
      if planning_params[:translate_by].present?
        translate_plannings
      else
        existing_items.update_all(planning_params.to_hash)
        existing_items.reload
      end
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

    def translate_plannings
      return [] if planning_params[:translate_by].to_i.zero?

      items = existing_items.collect(&:dup)
      existing_items.delete_all
      items.collect do |item|
        date = translate_date(item.date, planning_params[:translate_by].to_i)
        item.date = date
        Planning.where(
          employee_id: item.employee_id,
          work_item_id: item.work_item_id,
          date:
        ).delete_all
        item.save!
        item
      end
    end

    def translate_date(date, translate_by)
      translate_by = translate_by.to_i
      direction = translate_by < 0 ? -1 : 1
      translate_by.abs.times do
        date += direction.day
        date += direction.day if date.saturday? || date.sunday?
        date += direction.day if date.saturday? || date.sunday?
      end
      date
    end

    def create_repetitions(interval, end_date)
      repetitions = (end_date - interval.start_date).to_i / interval.length.to_i
      Array.new(repetitions) do |i|
        offset = ((i + 1) * interval.length).days
        repeat_plannings(offset, end_date).compact
      end.flatten
    end

    def repeat_plannings(offset, end_date)
      repetition_source.map do |planning|
        date = planning.date + offset
        next if date > end_date

        p = Planning.where(employee_id: planning.employee_id,
                           work_item_id: planning.work_item_id,
                           date:).first_or_initialize
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
      @planning_params ||= begin
        p = params[:planning].delete_if { |_k, v| v.blank? && v != false }
        convert_to_parameters(p).permit(PERMITTED_ATTRIBUTES)
      end
    end

    def convert_to_parameters(value)
      if value.is_a?(ActionController::Parameters)
        value
      else
        ActionController::Parameters.new(value)
      end
    end

    def handle_save_errors(plannings)
      save_errors = plannings.map { |p| p.errors.full_messages }.flatten.compact
      return unless save_errors.present?

      # should not happen after form validations
      @errors << ('Eintrag konnte nicht erstellt werden: ' + save_errors.uniq.join(', '))
      raise ActiveRecord::Rollback
    end

    def new_items_hashes
      return [] if items.blank?

      @new_items_hashes ||= items - existing_items_hashes
    end

    def existing_items_hashes
      @existing_items_hashes ||= existing_items.pluck(*ITEM_FIELDS).map do |values|
        { 'employee_id' => values.first.to_s,
          'work_item_id' => values.second.to_s,
          'date' => values.third.strftime('%Y-%m-%d') }
      end
    end

    def existing_items
      return Planning.none if items.blank?

      @existing_items ||= Planning.where(existing_items_condition)
    end

    def existing_items_condition
      table = Planning.arel_table
      items.collect do |item|
        ITEM_FIELDS.collect { |attr| table[attr].eq(item[attr.to_s]) }.reduce(:and)
      end.reduce(:or)
    end

    def items
      @items ||= (params[:items] || []).collect do |i|
        convert_to_parameters(i).permit(*ITEM_FIELDS).to_h
      end
    end

    def repeat_until_week
      r = params[:planning][:repeat_until]
      @repeat_until_week ||= Week.from_string(r) if r.present?
    end
  end
end
