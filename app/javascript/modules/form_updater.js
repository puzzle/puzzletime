//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.

const app = window.App || (window.App = {})

app.FormUpdaterTrigger = class FormUpdaterTrigger {
  constructor (event, ...watchSelectors) {
    this.event = event
    this.watchedElements = watchSelectors.join(', ')
  }
}

app.FormUpdaterAction = class FormUpdaterAction {
  constructor (url, formSelector) {
    this.url = url
    this.form = $(formSelector)
  }
}

// Update Form by running AJAX request when event fires on watched elements
app.FormUpdater = class FormUpdater {
  constructor (trigger, ...actions) {
    this.trigger = trigger
    this.actions = actions

    this._bind()
  }

  _bind () {
    // unbind action before binding, as else we might
    // run into problems with turbolinks caching
    $(document).off(this.trigger.event, this.trigger.watchedElements)

    // use a promise chain to sequentially execute actions. jqXHR is thenable,
    // so it sequences them on its own; the catch is required because an
    // uncaught rejection reaches the browser as an uncaught error whose value
    // is the jqXHR — "Ferrum::JavaScriptError: Object" in tests. A request
    // aborted by navigation is the normal case, not a fault.
    return $(document).on(this.trigger.event, this.trigger.watchedElements, event => {
      return this.actions
        .reduce((promise, action) => promise.then(() => $.getScript(`${action.url}?${action.form.serialize()}`)),
          Promise.resolve())
        .catch(xhr => {
          if (xhr && xhr.statusText !== 'abort') { console.warn('form update failed', xhr && xhr.status) }
        })
    })
  }
}
