//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});
if (!app.plannings) { app.plannings = {}; }

app.plannings.panel = new ((function() {
  let default_repeat_offset = undefined;
  let panel = undefined;
  let container = undefined;
  let positioning = undefined;
  let focusPercentOnShow = undefined;
  const Cls = class {
    constructor() {
      this.cancel = this.cancel.bind(this);
      this.submit = this.submit.bind(this);
      this.deleteSelected = this.deleteSelected.bind(this);
      this.definitiveChange = this.definitiveChange.bind(this);
      this.repetitionChange = this.repetitionChange.bind(this);
      this.position = this.position.bind(this);
    }

    static initClass() {
      default_repeat_offset = 7; // days
      panel = '.planning-panel';
      container = '.planning-calendar';
      positioning = false;
      focusPercentOnShow = false;
    }

    init() {
      if (this.panel().length === 0) { return; }
      return this.bindListeners();
    }

    destroy() {
      return this.bindListeners(true);
    }

    bindListeners(unbind) {
      const func = unbind ? 'off' : 'on';

      $('main')[func]('scroll', this.position);

      this.panel('.planning-definitive-group button')[func]('click', this.definitiveChange);
      this.panel('#repetition')[func]('click', this.repetitionChange);
      this.panel('.planning-cancel')[func]('click', this.cancel);
      this.panel('form')[func]('submit', this.submit);
      return this.panel('.planning-delete')[func]('click', this.deleteSelected);
    }

    show(selectedElements) {
      this.position();

      this.hideErrors();
      this.initPercent();
      this.initDefinitive();
      this.initRepetition();

      const hasExisting = app.plannings.selectable.selectionHasExistingPlannings();
      return this.panel('.planning-delete').css('visibility', hasExisting ? 'visible' : 'hidden');
    }

    hide() {
      return $(panel).hide();
    }

    cancel(event) {
      $(event.target).blur();
      return app.plannings.selectable.clear();
    }

    showErrors(errors) {
      const alerts = this.panel('.alerts').empty();
      if (errors != null ? errors.length : undefined) {
        let alert = '<div class="alert alert-danger">';
        if (errors.length > 1) {
          alert += '<ul>';
          errors.forEach(error => alert += `<li>${error}</li>`);
          alert += '</ul>';
        } else {
          alert += errors[0];
        }
        alert += '</div>';
        alerts.append($(alert));
      } else {
        alerts.append($('<div class="alert alert-danger">Ein Fehler ist aufgetreten</div>'));
      }
      alerts.show();
      return this.position();
    }

    hideErrors() {
      return this.panel('.alert').hide();
    }

    submit(event) {
      event.preventDefault();
      this.hideErrors();
      const data = $(event.target).serializeArray()
        .reduce((function(prev, curr) { prev[curr.name] = curr.value; return prev; }), {});
      return this.disableButtons(app.plannings.service.updateSelected(this.getFormAction(), data));
    }

    deleteSelected(event) {
      if (confirm('Bist du sicher, dass du die selektierte Planung löschen willst?')) {
        event.preventDefault();
        return this.disableButtons(app.plannings.service.delete(
          this.getFormAction(),
          app.plannings.selectable.getSelectedPlanningIds()
        ));
      }
    }

    getFormAction() {
      return this.panel('form').prop('action');
    }

    setPercent(percent, indefinite) {
      return this.panel('#percent')
        .val(percent)
        .prop('placeholder', indefinite ? '?' : '');
    }

    initPercent() {
      const values = app.plannings.selectable.getSelectedPercentValues();
      const percent = values.length === 1 ? values[0] : '';
      this.setPercent(percent, values.length > 1);
      return focusPercentOnShow = values.length === 1;
    }

    setDefinitive(definitive) {
      this.panel('.planning-definitive').toggleClass('active', definitive === true);
      this.panel('.planning-provisional').toggleClass('active', definitive === false);

      const value = (definitive != null) ? definitive.toString() : '';
      return this.panel('#definitive').val(value);
    }

    initDefinitive() {
      const values = app.plannings.selectable.getSelectedDefinitiveValues();
      if (values.length === 1) {
        return this.setDefinitive(values[0] === null ? false : values[0]);
      } else {
        return this.setDefinitive(null);
      }
    }

    definitiveChange(event) {
      const source = $(event.target).hasClass('planning-definitive');
      const current = this.panel('#definitive').val();
      return this.setDefinitive(source.toString() === current ? null : source);
    }

    initDatepickerValue() {
      let [{ date }] = Array.from(app.plannings.selectable.getSelectedDays());
      date = new Date(date);
      date.setDate(date.getDate() + default_repeat_offset);
      return this.panel('#repeat_until')
        .datepicker('option', 'defaultDate', date)
        .val(app.datepicker.formatWeek(date));
    }

    initRepetition() {
      this.panel('#repetition').prop('checked', false);
      this.panel('.planning-repetition-group').hide();
      this.panel('#repeat_until').prop('disabled', true);
      return this.initDatepickerValue();
    }

    repetitionChange(event) {
      const enabled = $(event.target).prop('checked');
      this.panel('#repeat_until').prop('disabled', !enabled);
      this.panel('.planning-repetition-group')[enabled ? 'show' : 'hide']();
      return this.initDatepickerValue();
    }

    position(e) {
      const hasSelection = () => $(container).find('.ui-selected').length;
      if ((this.panel().length === 0) ||
        (((e != null ? e.type : undefined) === 'scroll') && this.panel().is(':hidden')) ||
        !hasSelection()) { return; }

      if (!positioning) {
        requestAnimationFrame(() => {
          if (!hasSelection()) {
            positioning = false;
            return;
          }

          const wasHidden = this.panel().is(':hidden');

          this.panel().show().position({
            my: 'right top',
            at: 'right bottom',
            of: $(container).find('.ui-selected').last(),
            within: 'body',
            collision: 'flipfit flipfit'
          });
          positioning = false;

          if (wasHidden) {
            if (focusPercentOnShow) {
              return this.panel('#percent').focus().select();
            } else {
              return this.panel('#percent').blur();
            }
          }
        });
      }
      return positioning = true;
    }

    disableButtons(promise) {
      const buttons = this.panel('.panel-footer .btn');
      buttons.prop('disabled', true);
      return promise.always(() => buttons.prop('disabled', false));
    }

    panel(selector) {
      if (selector) {
        return $(selector, panel);
      } else {
        return $(panel);
      }
    }
  };
  Cls.initClass();
  return Cls;
})());

$(document).on('turbolinks:load', function() {
  app.plannings.panel.destroy();
  return app.plannings.panel.init();
});
