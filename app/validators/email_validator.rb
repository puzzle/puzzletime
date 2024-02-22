# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if EmailAddress.valid?(value, host_validation: :syntax)

    record.errors.add attribute, (options[:message] || I18n.t('error.message.invalid_email'))
  end
end
