# encoding: utf-8

module Plannings
  class Creator

    attr_reader :params, :errors, :plannings

    PERMITTED_ATTRIBUTES = [:id, :employee_id, :work_item_id, :date, :percent, :definitive]

    # params:
    # { planning: { percent: 50, definitive: true, repeat_until: '2016 42' },
    #   update: [ 1, 3, 4 ],
    #   create: [
    #       { employee_id: 2, work_item_id: 3, date: '2016-03-01' }
    #   ] }
    def initialize(params)
      @params = params
    end

    def create_or_update
      return false unless form_valid?

      Planning.transaction do
        begin
          @plannings = create.concat(update)
        rescue ActiveRecord::RecordNotFound
          # @errors << 'Eintrag existiert nicht'
          raise ActiveRecord::Rollback
        end

        # TODO: append errors to @errors
        @plannings.all?(&:valid?)
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
      if params[:create].present? && !repeat_only?
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
        if !week.valid?
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

    def create
      return [] unless params[:create].present?

      params[:create].values.collect do |day|
        day_params = ActionController::Parameters.new(day).permit(PERMITTED_ATTRIBUTES)
        Planning.create(planning_params.merge(day_params))
      end
    end

    def update
      return [] unless params[:update].present?

      params[:update].collect { |id| Planning.update(id, planning_params) }
      # TODO: use update_all (and skip validations!) to have only one query?
    end

    def planning_params
      params[:planning].delete_if { |k, v| v.blank? && v != false }.permit(PERMITTED_ATTRIBUTES)
    end

  end
end
