# frozen_string_literal: true

# Return a string to customize the text in the <option> tag, `value` attribute will remain unchanged
CountrySelect::FORMATS[:with_alpha2] = lambda do |country|
  return nil if country.blank?

  "#{country.translations[I18n.locale.to_s] || country.name} (#{country.alpha2})"
end
