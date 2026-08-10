//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});
if (!app.plannings) { app.plannings = {}; }

app.plannings.service = new (class {
  updateSelected(url, planning) {
    planning.utf8 = undefined;
    const token = planning.authenticity_token;
    planning.authenticity_token = undefined;

    return this.update(url, {
      planning,
      items: app.plannings.selectable.getSelectedDays(),
      authenticity_token: token
    }
    ).fail(res => console.log('update error', res.status, res.statusText));
  }

  update(url, data) {
    return $.ajax({
      type: 'PATCH',
      url,
      data: this._buildParams(data)
    });
  }

  delete(url, ids) {
    return $.ajax({
      type: 'DELETE',
      url,
      data: this._buildParams({planning_ids: ids})
    });
  }

  addPlanningRow(employee_id, work_item_id) {
    return $.ajax({
      url: `${window.location.origin}${window.location.pathname}/new`,
      data: this._buildParams({
        employee_id,
        work_item_id
      })
    });
  }

  _buildParams(params) {
    return $.extend({utf8: '✓'}, params);
  }
});
