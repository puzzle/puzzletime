//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


class ClearInput {

  clear(cross) {
    console.log('click');
    this._input(cross).val('').trigger('change');
    return this._input(cross).parents('form').submit();
  }

  toggleHide(input) {
    const group = input.parents('.has-clear');
    if (input.val() === '') {
      return group.addClass('has-empty-value');
    } else {
      return group.removeClass('has-empty-value');
    }
  }

  _input(cross) {
    return cross.parents('.has-clear').find('input[type=search]');
  }

  bind() {
    const self = this;
    $(document).on('click', '[data-clear]', function() { return self.clear($(this)); });
    return $(document).on('change', '.has-clear input[type=search]', function() { return self.toggleHide($(this)); });
  }
}


new ClearInput().bind();

$(document).on('turbolinks:load', () => $('.has-clear input[type=search]').each((i, e) => new ClearInput().toggleHide($(e))));
