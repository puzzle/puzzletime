//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});
if (!app.plannings) { app.plannings = {}; }

app.plannings = new ((function() {
  let board = undefined;
  let addRowSelect = undefined;
  let addRowSelectize = undefined;
  let addRowOptions = undefined;
  let waypoints = undefined;
  let positioningHeaders = undefined;
  const Cls = class {
    constructor() {
      this.add = this.add.bind(this);
      this.onAddSelect = this.onAddSelect.bind(this);
      this.positionHeaders = this.positionHeaders.bind(this);
    }

    static initClass() {
      board = '.planning-calendar';
      addRowSelect = null;
      addRowSelectize = null;
      addRowOptions = [];
      waypoints = [];
      positioningHeaders = false;
    }

    init() {
      this.bindListeners();
      this.dateFilterChanged();
      this.initSelectize();
      this.initGroupheaders();
      this.initWaypoints();
      return this.positionHeaders();
    }

    destroy() {
      this.bindListeners(true);
      return this.destroyWaypoints();
    }

    reloadAll() {
      return [this, app.plannings.selectable, app.plannings.panel].forEach(p => {
        p.destroy();
        return p.init();
      });
    }

    dateFilterChanged() {
      return $('#planning_filter_form').find('#start_date,#end_date').closest('.form-group')
        .css('visibility', !$('#period_shortcut').val() ? 'visible' : 'hidden');
    }

    add(event) {
      return this.showSelect(event);
    }

    showSelect(event) {
      const actionData = $(event.target).closest('.actions').data();
      addRowSelectize.setValue(null);
      addRowSelectize.clearOptions();
      addRowOptions
        .filter(option => option != null ? option.value : undefined)
        .forEach(option => {
          actionData[`${actionData.type}Id`] = option.value;

          if (this.board().has(`#planning_row_employee_${actionData.employeeId}_work_item_${actionData.workItemId}`).length) { return; }

          return addRowSelectize.addOption(option);
        });

      $(event.target)
        .closest('.buttons')
        .prepend(addRowSelect);

      this.board('.add').show();
      $(event.target).hide();
      addRowSelect.show();
      return requestAnimationFrame(() => addRowSelectize.refreshOptions());
    }

    addRow(employeeId, workItemId) {
      return app.plannings.service
        .addPlanningRow(employeeId, workItemId)
        .then(() => {
          addRowSelect.hide();

          this.board('.add').show();
          return this.initWaypoints();
        });
    }

    onAddSelect(value) {
      if (value) {
        let employeeId, workItemId;
        if (addRowSelect.is('#add_employee_id')) {
          employeeId = value;
          workItemId = addRowSelect
            .closest('.actions')
            .data('work-item-id');
        } else if (addRowSelect.is('#add_work_item_id')) {
          workItemId = value;
          employeeId = addRowSelect
            .closest('.actions')
            .data('employee-id');
        } else {
          throw new Error('Unknown select!');
        }

        return this.addRow(employeeId, workItemId);
      }
    }

    bindListeners(unbind) {
      const func = unbind ? 'off' : 'on';

      this.board('.actions .add')[func]('click', this.add);
      return $('main')[func]('scroll', this.positionHeaders);
    }

    initSelectize() {
      addRowSelect = $('#add_employee_id,#add_work_item_id');
      addRowSelectize = __guard__(addRowSelect
        .children('select')
        .selectize({
          selectOnTab: true,
          dropdownParent: 'body',
          onItemAdd: this.onAddSelect
        })
        .get(0), x => x.selectize);

      if (!addRowSelectize) { return; }

      return addRowOptions = [
        undefined,
        ...Array.from(Object.keys(addRowSelectize.options)
          .map(key => addRowSelectize.options[key]))
      ];
    }

    initGroupheaders() {
      $('.groupheader').click(function(e) {
        if ($(e.target).hasClass('day')) { return; }

        const collapsed = $(this).hasClass('collapsed');

        $(this)
          .toggleClass('collapsed', !collapsed)
          .find('.glyphicon')
            .toggleClass('glyphicon-chevron-left', !collapsed)
            .toggleClass('glyphicon-chevron-down', collapsed)
          .end()
          .nextUntil('.groupheader')
          .toggle(collapsed);

        app.plannings.positionHeaders();

        if (collapsed) {
          $(this).children().removeClass('has-planning');

          if ($(this).next('.actions').length) {
            return $(this).next('.actions').find('.add').click();
          }
        } else {
          const children = $(this).children();

          return $(this)
            .nextUntil('.actions,.groupheader')
            .find('.day')
            .filter('.-definitive,.-provisional')
            .map(function() { return children.get($(this.parentNode.children).index(this)); })
            .addClass('has-planning');
        }
      });


      $('.groupheader')
        .filter(function() { return !$(this).nextUntil('.groupheader').length; })
        .find('.glyphicon')
        .remove();

      return $('.groupheader')
        .filter(function() {
          return $(this).next('.actions,.groupheader').length ||
          $(this).is(':last-child');}).click();
    }

    initWaypoints() {
      if (Modernizr.csspositionsticky) { return; }
      waypoints = [];

      this.destroyWaypoints();
      this.initTopCalendarHeaderWaypoints();
      return this.initLeftCalendarHeaderWaypoints();
    }

    initTopCalendarHeaderWaypoints() {
      return $('.planning-calendar')
        .toArray()
        .map(el => [
        $(el).find('.planning-calendar-weeks'),
        $(el).find('.planning-calendar-days-header')
      ])
        .forEach(function(...args) {
          const [ weeks, daysHeader ] = Array.from(args[0]);
          waypoints.push(new Waypoint.Sticky({
            element: weeks,
            context: $('main')
          }));
          return waypoints.push(new Waypoint.Sticky({
            element: daysHeader,
            context: $('main')
          }));
      });
    }

    initLeftCalendarHeaderWaypoints() {
      return this.getLeftCalendarHeaderElements().each((_i, element) => waypoints.push(new Waypoint.Sticky({
        element,
        context: $('main'),
        horizontal: true
      })));
    }

    positionHeaders() {
      if (!positioningHeaders) {
        requestAnimationFrame(() => {
          this.positionBoardHeader();

          if (!Modernizr.csspositionsticky) {
            $('.planning-calendar-weeks,.planning-calendar-days-header').each((_i, element) => {
              return this.positionTopCalendarHeader(element);
          });
            this.getLeftCalendarHeaderElements().each((_i, element) => {
              return this.positionLeftCalendarHeader(element);
          });
          }

          return positioningHeaders = false;
        });
      }
      return positioningHeaders = true;
    }

    positionBoardHeader() {
      return $('.planning-board-header').css('left', $(document).scrollLeft() + 'px');
    }

    positionTopCalendarHeader(element) {
      if ($(element).hasClass('stuck')) {
        const leftHeaderWidth = parseInt($('.legend').first().css('width'), 10);
        const firstDay = $(element)
          .closest('.planning-calendar-inner')
          .find('.day:first');
        const offset = (firstDay[0] != null ? firstDay[0].getBoundingClientRect().left : undefined) - leftHeaderWidth;
        return $(element).css('left', offset + 'px');
      } else {
        return $(element).css('left', 'auto');
      }
    }

    positionLeftCalendarHeader(element) {
      if ($(element).hasClass('stuck')) {
        const offset = $(element)
          .closest('.sticky-wrapper')[0]
          .getBoundingClientRect().top;
        return $(element).css('top', offset + 'px');
      } else {
        return $(element).css('top', 'auto');
      }
    }

    getLeftCalendarHeaderElements() {
      return $(['.planning-calendar-inner > .groupheader .legend',
         '.planning-calendar-inner > .actions .buttons',
         '.planning-calendar-days .legend',
         '.planning-board-header',
         '.planning-legend'
        ].join(','));
    }

    destroyWaypoints() {
      waypoints.forEach(waypoint => waypoint.destroy());
      waypoints = [];

      $('.stuck').removeClass('stuck');
      return $('.sticky-wrapper').replaceWith(function() { return this.children; });
    }

    board(selector) {
      if (selector) {
        return $(selector, board);
      } else {
        return $(board);
      }
    }
  };
  Cls.initClass();
  return Cls;
})());

$(document).on('turbolinks:load', function() {
  app.plannings.destroy();
  return app.plannings.init();
});
function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}