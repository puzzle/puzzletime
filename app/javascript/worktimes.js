//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

app.worktimes = new ((function() {
  let scrollSpeed = undefined;
  let activationEnabled = undefined;
  let worktimesWaypoint = undefined;
  let headerOffset = undefined;
  let toggle = undefined;
  let showMultiAbsence = undefined;
  let showRegularAbsence = undefined;
  let parseDate = undefined;
  const Cls = class {
    constructor() {
      this.activateNavDayWithDate = this.activateNavDayWithDate.bind(this);
    }

    static initClass() {
      scrollSpeed = 300;
      activationEnabled = true;
      worktimesWaypoint = null;
      headerOffset = 0;
  
      toggle = function(selector, disable) {
        $(selector).prop('disabled', disable);
        if (disable) { return $(selector).val(''); }
      };
  
      // show regular absence on load, toggle when clicking on multi absence link
      showMultiAbsence = function(e) {
        $('#absencetime_create_multi').val('true');
        $('#single').hide();
        $('#multi').show();
        if (e) { return e.preventDefault(); }
      };
  
      showRegularAbsence = function(e) {
        $('#absencetime_create_multi').val('');
        $('#single').show();
        $('#multi').hide();
        if (e) { return e.preventDefault(); }
      };
  
      parseDate = function(dateStr) {
        const [d, m, y] = Array.from(dateStr.split('.'));
        return new Date(`${y}-${m}-${d}`);
      };
    }

    init() {
      this.bind();
      this.initWaypoint();
      return this.initScroll();
    }

    container(selector) {
      if (selector) {
        return $(selector, '.worktimes-container');
      } else {
        return $('.worktimes-container');
      }
    }

    bind() {
      $('#new_ordertime_link').click(function(e) {
        e.preventDefault();
        return window.location.href = `${$(this).attr('href')}?work_date=${$('#week_date').val()}`;
      });

      $('#new_other_ordertime_link').click(function(e) {
        e.preventDefault();
        return window.location.href = `${$(this).attr('href')}&work_date=${$('#week_date').val()}`;
      });

      if (this.container().length) {
        $('#week_date').on('change', function(event) {
          const date = event.target.value;
          window.location = `/worktimes?week_date=${date}`;
        });
      }

      $('#ordertime_hours').blur(function() {
        toggle('#ordertime_from_start_time', this.value);
        return toggle('#ordertime_to_end_time', this.value);
      });
      $('#ordertime_from_start_time').blur(function() {
        return toggle('#ordertime_hours', this.value || $('#ordertime_to_end_time').val());
      });
      $('#ordertime_to_end_time').blur(function() {
        return toggle('#ordertime_hours', this.value || $('#ordertime_from_start_time').val());
      });
      $('#absencetime_hours').blur(function() {
        toggle('#absencetime_from_start_time', this.value);
        return toggle('#absencetime_to_end_time', this.value);
      });
      $('#absencetime_from_start_time').blur(function() {
        return toggle('#absencetime_hours', this.value || $('#absencetime_to_end_time').val());
      });
      $('#absencetime_to_end_time').blur(function() {
        return toggle('#absencetime_hours', this.value || $('#absencetime_from_start_time').val());
      });

      if ($('#absencetime_create_multi').val()) {
        showMultiAbsence(null);
      } else if ($('#new_absencetime').length) {
        showRegularAbsence(null);
      }

      if ($('#ordertime_repetitions').val()) {
        this.recalcMaxRepetitions();
      }

      $('#multi_absence_link').click(showMultiAbsence);
      $('#regular_absence_link').click(showRegularAbsence);
      return $('#ordertime_work_date').change(this.recalcMaxRepetitions);
    }

    initWaypoint() {
      if (worktimesWaypoint) {
        worktimesWaypoint.destroy();
        worktimesWaypoint = null;
      }

      headerOffset = ($(window).width() > 768 ? $('header').height() : 0); //set offset of header

      if (this.container().length) {
        this.container('.weekcontent .date-label')
          .waypoint({
            handler(direction) {
              if (direction === 'down') {
                return app.worktimes.activateNavDayWithDate($(this.element).data('date'));
              } else if ((direction === 'up') && $(this.element).prev().length) {
                return app.worktimes.activateNavDayWithDate($(this.element).prev().data('date'));
              }
            }
            ,
            offset() { return $('.weeknav').height() + headerOffset; }
          });

        this.container('.weeknav .day').on('click', e => {
          e.preventDefault();
          const date = new Date($(e.currentTarget).data('date'));
          $('#week_date').datepicker('setDate', date);
          return this.scrollToDayWithDate($(e.currentTarget).data('date'));
        });

        if (!Modernizr.csspositionsticky) {
          return setTimeout(() => {
            return worktimesWaypoint = new Waypoint.Sticky({
              element: this.container()[0]});
        });
        }
      }
    }

    initScroll() {
      if (this.container().length && !$('.alert:not(.alert-success)', 'main').length) {
        const selectedDate = this.container().data('selectedDate');
        if (!selectedDate) { return; }
        const day = this.container(`.weeknav .day[data-date=\"${selectedDate}\"]`);
        if (day.length) { return day.click(); }
      }
    }


    activate(selector) {
      if (!activationEnabled) {
        return;
      }

      return this.container('.weeknav .day')
        .removeClass('active')
        .filter(selector)
        .addClass('active');
    }

    activateNavDayWithDate(date) {
      return this.activate(`[data-date=\"${date}\"]`);
    }

    activateFirstNavDay() {
      return this.activate(':first-child');
    }

    activateLastNavDay() {
      return this.activate(':last-child');
    }

    scrollToDayWithDate(date) {
      const dateLabel = this.container(`.weekcontent .date-label[data-date=\"${date}\"]`);
      if (dateLabel.length === 0) {
        return;
      }

      const offset = dateLabel.offset().top - this.container('.weeknav').height() - 20 - headerOffset;
      return this.scrollTo(offset, this.activateNavDayWithDate, date);
    }

    scrollTo(offset, callback, date) {
      // temporarly disable setting of .active on weeknav days
      activationEnabled = false;

      return $('html, body').animate({ scrollTop: offset },
        scrollSpeed, undefined, () => {
          activationEnabled = true;
          callback(date);

          if (date) {
            // hightlight entries
            const entries = this.container(
              '.weekcontent .date-label[data-date="' + date + '"], ' +
              '.weekcontent .entry[data-date="' + date + '"]');
            entries.addClass('highlight');
            return setTimeout((() => entries.removeClass('highlight')), 400);
          }
        });
    }

    // Calculates max amount of ordertime repetitions based on weekday
    // Monday -> 5, Tuesday -> 4, ...
    recalcMaxRepetitions() {
      const repField = $('#ordertime_repetitions');
      const dateStr = $('#ordertime_work_date').val();

      const weekDay = parseDate(dateStr).getDay();
      const max = (() => { switch (weekDay) {
        case 0: case 6: return 1; // Sunday, Saturday
        default: return 6 - weekDay; // Weekdays
      } })();

      const currentVal = Number(repField.val());
      repField.attr('max', max);
      // Repetitions must not be higher than new max value
      return repField.val(Math.min(currentVal, max));
    }
  };
  Cls.initClass();
  return Cls;
})());


$(document).on('turbolinks:load', () => app.worktimes.init());
