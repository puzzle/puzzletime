//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

app.SelectionWatcherTrigger = class SelectionWatcherTrigger {
  constructor(event, ...rest) {
    const adjustedLength = Math.max(rest.length, 1), watchSelectors = rest.slice(0, adjustedLength - 1), observedClass = rest[adjustedLength - 1];
    this.event = event;
    this.watchedElements = watchSelectors.join(', ');
    this.observedClass = observedClass;
  }
};

app.SelectionWatcherAction = class SelectionWatcherAction {
  constructor(url) {
    this.url = url;
  }
};

// Update Form by running AJAX request when event fires on watched elements
app.SelectionWatcher = class SelectionWatcher {
  constructor(trigger, ...actions) {
    this.trigger = trigger;
    this.actions = actions;
    
    this._bind();    
  }

  _bindClassObserver() {
    const observer = new MutationObserver(mutationsList => {
      for (var mutation of mutationsList) {
        if ((mutation.type !== 'attributes') || (mutation.attributeName !== 'class')) { return; }

        var el = mutation.target;
        if ($(el).is(this.trigger.watchedElements)) {
          console.log('fire action (class change)');
          this._runActionsWithSerializedClass();
          break;
        }
      }
    });  // avoid firing multiple times per batch

    return observer.observe(document.body, {
      attributes: true,
      subtree: true,
      attributeFilter: ['class']
    });
  }

  _bind() {
    if (['classChange'].includes(this.trigger.event)) {
      return this._bindClassObserver();
    } else {
      // unbind action before binding, as else we might
      // run into problems with turbolinks caching
      $(document).off(this.trigger.event, this.trigger.watchedElements);

      // use a promise chain to sequentially execute actions
      return $(document).on(this.trigger.event, this.trigger.watchedElements, event => {
        console.log('fire action');
        return this._runActionsWithSerializedClass();
      });
    }
  }
  
  _runActionsWithSerializedClass() {
    const query = this._serializeClassMatches();
    return this.actions.reduce((promise, action) => promise.then(() => new Promise((resolve, reject) => $.getScript(`${action.url}?${query}`)
      .done(resolve)
      .fail(reject)))
    , Promise.resolve());
  }

  _serializeClassMatches() {
    const classSelector = `.${this.trigger.observedClass}`;
    const matching = $(this.trigger.watchedElements).filter(classSelector);

    let cellIds = matching.map((i, el) => $(el).data('id'));
    cellIds = $.makeArray(cellIds).filter(id => id != null);

    return $.param({ 'cell_ids[]': cellIds });
  }
};