# active_record/errors.rb

#module ActiveRecord
#  class Errors
#    begin
#      @@default_error_messages.update( {
#        :inclusion => "ist nicht in Liste gültiger Optionen enthalten",
#        :exclusion => "ist reserviert",
#        :invalid => "ist ungültig",
#        :confirmation => "entspricht nicht der Bestätigung",
#        :accepted  => "muss akzeptiert werden",
#        :empty => "darf nicht leer sein",
#        :blank => "darf nicht leer sein",
#        :too_long => "ist zu lang (höchstens %d Zeichen)",
#        :too_short => "ist zu kurz (mindestens %d Zeichen)",
#        :wrong_length => "hat eine falsche Länge (es sollten %d Zeichen 
#sein)",
#        :taken => "ist schon vergeben",
#        :not_a_number => "ist keine Zahl",
#      })
#    end
#  end
#end

module ActionView #nodoc
  module Helpers
    module ActiveRecordHelper
      def error_messages_for(object_name, options = {})
        options = options.symbolize_keys
        object = instance_variable_get("@#{object_name}")
        if object && ! object.errors.empty?
          list = ''
          object.errors.each { |attr, msg| list += content_tag("li", "- " + msg) }
          content_tag("div",
            content_tag(
              options[:header_tag] || "h2",
              "#{object.errors.count} Fehler verhinderte#{object.errors.count > 1 ? 'n' : ''} das Speichern dieses Eintrags" 
            ) +
            content_tag("p", "Folgende Angaben sind fehlerhaft:") +
            content_tag("ul", list ),
            "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation" 
          )
        end
      end
    end
  end
end

# date.rb

require 'date'

class Date
  MONTHNAMES = [nil] + %w(Januar Februar März April Mai Juni Juli August September Oktober November Dezember)
  DAYNAMES = %w(Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag)
  ABBR_MONTHNAMES = [nil] + %w(Jan Feb Mär Apr Mai Jun Jul Aug Sep Okt Nov Dez)
  ABBR_DAYNAMES = %w(So Mo Di Mi Do Fr Sa)             
end


