# encoding: utf-8

# TODO: check if still required
class DateFormatter

  def initialize(*date_fields)
    @date_fields = date_fields.collect { |f| f.to_s }
  end

  def before_validation(model)
    @date_fields.each do |field|
      field_before_type_cast = model.send(field + '_before_type_cast')
      if field_before_type_cast.kind_of? String
        begin
          model.send(field + '=',
                     Date.strptime(field_before_type_cast, I18n.t('date.formats.default')))
        rescue ArgumentError
          # invalid string, date will remain unaffected, i.e., nil
        end
      end
    end
  end

end
