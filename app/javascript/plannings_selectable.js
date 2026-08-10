//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});
if (!app.plannings) { app.plannings = {}; }

app.plannings.selectable = new ((function() {
  let selectable = undefined;
  let selectee = undefined;
  let isSelecting = undefined;
  let copyCell = undefined;
  const Cls = class {
    constructor() {
      this.clear = this.clear.bind(this);
      this.preventClear = this.preventClear.bind(this);
      this.clearOnEscape = this.clearOnEscape.bind(this);
      this.start = this.start.bind(this);
      this.startTranslate = this.startTranslate.bind(this);
    }

    static initClass() {
      selectable = '.planning-calendar-inner.editable';
      selectee = '.planning-calendar-days > .day';
      isSelecting = false;
  
      copyCell = function(to, from) {
        to.innerHTML = from.innerHTML;
        to.className = from.className;
        return to;
      };
    }

    init() {
      if (this.selectable().length === 0) { return; }

      this.bindListeners();
      return this.selectable().selectable({
        filter: selectee,
        cancel: [
          'a',
          '.actions',
          '.legend'
        ].join(','),
        classes: {
          'ui-selected': '-selected',
          'ui-selecting': '-selected'
        },
        start: this.start,
        stop: this.stop
      });
    }

    destroy() {
      this.bindListeners(true);
      if (this.selectable().selectable('instance')) { return this.selectable().selectable('destroy'); }
    }

    bindListeners(unbind) {
      const func = unbind ? 'off' : 'on';

      $(document)[func]('click', this.clear);
      $(document)[func]('keyup', this.clearOnEscape);

      this.selectable()[func]('click', this.stopPropagation);
      return this.selectable()[func]('mousedown', '.ui-selected', this.startTranslate);
    }

    clear(e) {
      if (!this.preventClear(e)) {
        let selected = this.selectable('.ui-selected');
        if ((e != null ? e.type : undefined) === 'selectablestart') {
          // clear selections on other boards
          selected = this.selectable().not(e.target).find('.ui-selected');
        }

        selected.removeClass('ui-selected -selected');
        return app.plannings.panel.hide();
      }
    }

    preventClear(e) {
      const ignoredContainers = '.panel, .ui-datepicker';
      return e && (($(e.target).closest(ignoredContainers).length || $(e.target).is(':hidden')) // ignore clicks on detached nodes (i.e. datepicker previous/next)
      );
    }

    clearOnEscape(event) {
      if (event.key === 'Escape') {
        return this.clear();
      }
    }

    stopPropagation(event) { return event.stopPropagation(); }

    getSelectedDays(elements = this.selectable('.ui-selected')) {
      return elements
        .toArray()
        .map(element => {
          const row = $(element).parent();
          const [ _match, employee_id, work_item_id ] = Array.from(row.prop('id')
            .match(/planning_row_employee_(\d+)_work_item_(\d+)/));
          const date = this.selectable('.planning-calendar-days-header .dayheader')
            .eq(row.children('.day').index(element)).data('date');

          return { employee_id, work_item_id, date };
        });
    }

    getSelectedPlanningIds() {
      return this.selectable('.ui-selected')
        .toArray()
        .map(el => el.dataset.id)
        .filter(id => id);
    }

    getSelectedPercentValues() {
      return this.selectable('.ui-selected')
        .toArray()
        .map(element => $(element).text().trim())
        .filter((value, index, self) => self.indexOf(value) === index);
    }

    getSelectedDefinitiveValues() {
      return this.selectable('.ui-selected')
        .toArray()
        .map(function(element) {
          if ($(element).hasClass('-definitive')) {
            return true;
          } else if ($(element).hasClass('-provisional')) {
            return false;
          } else {
            return null;
          }
        })
        .filter((value, index, self) => self.indexOf(value) === index);
    }

    selectionHasExistingPlannings() {
      return this.selectable('.ui-selected.-definitive,.ui-selected.-provisional').length > 0;
    }

    start(event, ui) {
      isSelecting = true;
      this.clear(event);
      return setTimeout((() => isSelecting && app.plannings.panel.hide()), 100); // avoid flickering
    }

    stop(event, ui) {
      isSelecting = false;
      const selectedElements = $(event.target).find('.ui-selected');
      selectedElements.addClass('-selected');

      if (selectedElements.length > 0) {
        return app.plannings.panel.show(selectedElements);
      }
    }

    selectable(selector) {
      if (selector) {
        return $(selector, selectable);
      } else {
        return $(selectable);
      }
    }

    startTranslate(e) {
      if (!e.target.matches('.-definitive,.-provisional')) { return; }
      e.stopPropagation();

      const currentlySelected = this.selectable('.ui-selected');
      const daysToUpdate = this.getSelectedDays(
        currentlySelected.filter('.-definitive,.-provisional')
      );
      const {
        children
      } = e.target.parentNode;
      const startNodeIndex = $(children).index(e.target);
      const selectedIndexes = Array.from(currentlySelected, el => $(el.parentNode.children).index(el));
      const minTranslateBy = -selectedIndexes.reduce((a, b) => Math.min(a, b));
      const maxSelectedIndex = selectedIndexes.reduce((a, b) => Math.max(a, b));
      const maxTranslateBy = children.length - maxSelectedIndex;
      let translateBy = 0;
      const getRows = elements => $.unique(elements.map(function() { return this.parentNode; }));
      const originalRows = getRows(currentlySelected).clone();

      this.selectable().on('mousemove', e => {
        e.stopPropagation();

        if (e.target.matches('.day')) {
          app.plannings.panel.hide();

          const currentNodeIndex = $(e.target.parentNode.children).index(e.target);
          const currentTranslateBy = currentNodeIndex - startNodeIndex;

          translateBy = Math.max(
            minTranslateBy + 1,
            Math.min(maxTranslateBy - 1, currentTranslateBy)
          );

          this.resetCellsOfRows(
            getRows(this.selectable('.ui-selected')),
            originalRows,
            translateBy
          );
          return this.translateDays(currentlySelected, translateBy);
        }
      });

      return this.selectable().on('mouseup', e => {
        this.selectable().off('mousemove mouseup');
        if (translateBy) { return this.updateDayTranslation(daysToUpdate, translateBy); }
      });
    }

    resetCellsOfRows(rows, originalRows, unselect) {
      return Array.from(rows, (row, i) => Array.from(row.children, function(cell, j) {
        copyCell(cell, originalRows[i].children[j]);
        if (unselect) { cell.classList.remove('ui-selected', '-selected'); }
        return cell;
      }));
    }

    translateDays(days, translateBy) {
      if (!translateBy) { return; }

      const cells = Array
        .from(days, el => [
          $(el.parentNode.children).index(el),
          el.parentNode
        ])
        .map(([ i, parentNode ]) => [
          parentNode.children[i],
          parentNode.children[i + translateBy]
        ]);

      // Shifting right has to start from the far end, or each cell overwrites
      // the one the next iteration still needs to read.
      if (translateBy > 0) { cells.reverse(); }

      return cells.forEach(([ from, to ]) => {
        copyCell(to, from);
        to.classList.add('ui-selected', '-selected');
        from.className = 'day';
        from.innerHTML = '';
      });
    }

    updateDayTranslation(items, translateBy) {
      return app.plannings.service.update(
        `${window.location.origin}${window.location.pathname}`, {
        items,
        planning: {
          translate_by: translateBy
        }
      }
      );
    }
  };
  Cls.initClass();
  return Cls;
})());

$(document).on('turbolinks:load', function() {
  app.plannings.selectable.destroy();
  return app.plannings.selectable.init();
});
