module Plannings
  class Creator

    attr_reader :params, :errors, :plannings

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

      # TODO @plannings =
      true
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
      p[:repeat_until].present? && p[:percent].blank? && p[:definitive].nil?
    end

    private

    def validate_create(p)
      if params[:create].present? && !repeat_only?
        if p[:percent].blank?
          @errors << 'Prozent müssen angegeben werden, um neue Planungen zu erstellen'
        end
        if p[:definitive].nil?
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
      if p.blank? || (p[:percent].blank? && p[:definitive].nil? && p[:repeat_until].blank?)
        @errors << 'Bitte füllen Sie das Formular aus'
      end
    end

  end
end