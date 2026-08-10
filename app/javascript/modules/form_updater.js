//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

app.FormUpdaterTrigger = class FormUpdaterTrigger {
  constructor(event, ...watchSelectors) {
    this.event = event;
    this.watchedElements = watchSelectors.join(', ');
  }
};

app.FormUpdaterAction = class FormUpdaterAction {
  constructor(url, formSelector) {
    this.url = url;
    this.form = $(formSelector);
  }
};

// Update Form by running AJAX request when event fires on watched elements
app.FormUpdater = class FormUpdater {
  constructor(trigger, ...actions) {
    this.trigger = trigger;
    this.actions = actions;
    
    this._bind();    
  }

  _bind() {
    // unbind action before binding, as else we might
    // run into problems with turbolinks caching
    $(document).off(this.trigger.event, this.trigger.watchedElements);

    // use a promise chain to sequentially execute actions
    return $(document).on(this.trigger.event, this.trigger.watchedElements, event => {
      return this.actions.reduce((promise, action) => promise.then(() => new Promise((resolve, reject) => $.getScript(`${action.url}?${action.form.serialize()}`)
        .done(resolve)
        .fail(reject)))
      , Promise.resolve());
    });  // Start with a resolved promise to begin the chain
  }
};