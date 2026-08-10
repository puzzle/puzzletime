//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

// Initializes date pickers on inputs with class .date,
// works as week picker if data-format="week"
app.datepicker = new ((function() {
  let i18n = undefined;
  let formatWeek = undefined;
  let onSelect = undefined;
  let options = undefined;
  let unavailableDates = undefined;
  const Cls = class {
    static initClass() {
      i18n = () => $.datepicker.regional[$('html').attr('lang')];
  
      formatWeek = function(date) {
        const week = $.datepicker.iso8601Week(date);
        if (((date.getMonth() + 1) === 12) && (Number(week) === 1)) {
          return `${date.getFullYear() + 1} ${week}`;
        } else {
          return `${date.getFullYear()} ${week}`;
        }
      };
  
      onSelect = (dateString, instance) => {
        if (instance.input.data('format') === 'week') {
          const date = $.datepicker.parseDate(i18n().dateFormat, dateString);
          instance.input.val(formatWeek(date));
        }
        return instance.input.trigger('change');
      };
  
      options = $.extend({ onSelect, showWeek: true }, i18n());
  
      unavailableDates = $input => (function(date) {
        if ($input.hasClass('only-mondays')) {
          return [date.getDay() === 1, '', 'Bitte wähle einen Montag aus'];
        }
        if ($input.hasClass('only-fridays')) {
          return [date.getDay() === 5, '', 'Bitte wähle einen Freitag aus'];
        }
        return [true, '', ''];
      });
  
      this.prototype.formatWeek = formatWeek;
        // allow all dates by default
    }


    init() {
      $('input.date').each((_i, elem) => $(elem).datepicker($.extend({}, options, {
        changeYear: $(elem).data('changeyear'),
        changeMonth: $(elem).data('changemonth'),
        beforeShowDay: unavailableDates($(elem)),
        dateFormat: 'dd.mm.yy',
        setDate: $(elem).val()
      })));
      return this.bindListeners();
    }

    bindListeners(unbind) {
      const func = unbind ? 'off' : 'on';

      return $(document)[func]('click', 'input.date + .input-group-addon', this.show);
    }

    show(event) {
      let field = $(event.target);
      if (!field.is('input.date')) {
        field = field.closest('.input-group').find('.date');
      }
      return field.datepicker('show');
    }
  };
  Cls.initClass();
  return Cls;
})());


document.addEventListener("turbolinks:before-cache", function() {
  $.datepicker.dpDiv.remove();

  // decaffeinate --loose turned CoffeeScript's trailing `for element in ...`
  // into .map(), which a NodeList does not have. The result was never used.
  return document.querySelectorAll("input.hasDatepicker").forEach((element) =>
    $(element).datepicker("destroy"));
});

document.addEventListener("turbolinks:before-render", event => $.datepicker.dpDiv.appendTo(event.data.newBody));

$(document).on('turbolinks:load', () => app.datepicker.init());
