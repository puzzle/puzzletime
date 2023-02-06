(function() {
  debugger;
  var app;

  app = window.App || (window.App = {});

  if (typeof String.prototype.endsWith !== 'function') {
    String.prototype.endsWith = function(suffix) {
      return this.indexOf(suffix, this.length - suffix.length) !== -1;
    };
  }

  Object.defineProperty(Object.prototype, 'do', {
    value: function(callback) {
      callback.call(this, this);
      return this;
    }
  });

  if (typeof Object.assign !== 'function') {
    Object.assign = function(target) {
      'use strict';
      var index, nextKey, output, source;
      if (target == null) {
        throw new TypeError('Cannot convert undefined or null to object');
      }
      output = Object(target);
      index = 1;
      while (index < arguments.length) {
        source = arguments[index];
        if (source !== void 0 && source !== null) {
          for (nextKey in source) {
            if (source.hasOwnProperty(nextKey)) {
              output[nextKey] = source[nextKey];
            }
          }
        }
        index++;
      }
      return output;
    };
  }

  Selectize.define('required-fix', function(options) {
    return this.refreshValidityState = (function(_this) {
      return function() {
        var invalid;
        if (!_this.isRequired) {
          return false;
        }
        invalid = !_this.items.length;
        _this.isInvalid = invalid;
        if (invalid) {
          _this.$control_input.attr('required', '');
          return _this.$input.removeAttr('required');
        } else {
          _this.$control_input.removeAttr('required');
          return _this.$input.attr('required');
        }
      };
    })(this);
  });

  $(document).on('click', '[data-toggle]', function(event) {
    var id;
    id = $(this).data('toggle');
    if (id !== 'tooltip') {
      $('#' + id).slideToggle(200);
      return event.preventDefault();
    }
  });

  $(document).on('change', '[data-submit]', function(event) {
    return $(this).closest('form').submit();
  });

  $(document).tooltip({
    selector: '[data-toggle=tooltip]',
    container: 'body',
    placement: 'top',
    html: true
  });

  $(document).on("fields_added.nested_form_fields", function(event, param) {
    return $('select.searchable').selectize();
  });

  $(document).on('ajax:error', function(event, xhr, status, error) {
    return alert('Sorry, something went wrong\n(' + error + ')');
  });

  $(document).on('turbolinks:load', function() {
    $('select.searchable:not([multiple])').selectize({
      selectOnTab: true
    });
    $('select[multiple].searchable').selectize({
      plugins: ['remove_button'],
      selectOnTab: true
    });
    $('[data-toggle=buttons]').button();
    $('body').on('click', 'a.disabled', function(event) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return event.stopPropagation();
    });
    $('.initial-focus, .initial-focus input').focus();
    return setTimeout(function() {
      return $('.initial-focus.selectized').next('.selectize-control').find('input').focus();
    });
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.Autocomplete = (function() {
    function Autocomplete() {}

    Autocomplete.prototype.bind = function(input) {
      return $(input).selectize({
        plugins: ['required-fix'],
        valueField: 'id',
        searchField: this.searchFields(),
        selectOnTab: true,
        openOnFocus: false,
        render: {
          option: this.renderOption.bind(this),
          item: this.renderItem
        },
        load: this.loadOptions(input),
        onItemAdd: this.onItemAdd
      });
    };

    Autocomplete.prototype.searchFields = function() {
      return ['name', 'path_shortnames', 'path_names'];
    };

    Autocomplete.prototype.onItemAdd = function() {};

    Autocomplete.prototype.renderOption = function(item, escape) {
      return "<div class='selectize-option'>" + ("<div class='shortname'>" + (escape(item.path_shortnames)) + "</div>") + ("<div class='name'>" + (escape(this.limitText(item.name, 70))) + "</div>") + "</div>";
    };

    Autocomplete.prototype.renderItem = function(item, escape) {
      return "<div>" + (escape(item.path_shortnames)) + ": " + (escape(item.name)) + "</div>";
    };

    Autocomplete.prototype.loadOptions = function(input) {
      return function(query, callback) {
        if (query.length) {
          return $.ajax({
            url: Autocomplete.prototype.buildUrl(input, query),
            type: 'GET',
            error: function() {
              return callback();
            },
            success: function(res) {
              return callback(res);
            }
          });
        } else {
          return callback();
        }
      };
    };

    Autocomplete.prototype.buildUrl = function(input, query) {
      var param, param_char, url;
      url = $(input).data('url');
      param = encodeURIComponent(query);
      param_char = url.indexOf('?') >= 0 ? '&' : '?';
      return "" + url + param_char + "q=" + param;
    };

    Autocomplete.prototype.limitText = function(string, max) {
      if (!string) {
        return '';
      } else if (string.length > max) {
        return string.substr(0, max) + '…';
      } else {
        return string;
      }
    };

    return Autocomplete;

  })();

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.checkbox || (app.checkbox = {});

  app.checkbox.Toggler = (function() {
    function Toggler(data, action) {
      this.data = data;
      this.action = action;
      this.toggleChecked = function(checkbox) {
        var checked, selector;
        selector = $(checkbox).data(this.data);
        checked = $(checkbox).prop('checked');
        return new this.action(selector).toggle(checked);
      };
    }

    Toggler.prototype.bind = function() {
      var selector, self;
      self = this;
      selector = '[data-' + this.data + ']';
      $(document).on('click', selector, function(event) {
        return self.toggleChecked(this);
      });
      return $(document).on('turbolinks:load', function() {
        return $(selector).each(function(i, e) {
          return self.toggleChecked(e);
        });
      });
    };

    return Toggler;

  })();

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.checkbox || (app.checkbox = {});

  app.checkbox.AllChecker = (function() {
    function AllChecker(name) {
      this.name = name;
    }

    AllChecker.prototype.toggle = function(checked) {
      return $('input[type=checkbox][name="' + this.name + '"]').prop('checked', checked);
    };

    return AllChecker;

  })();

  new app.checkbox.Toggler('check', app.checkbox.AllChecker).bind();

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.checkbox || (app.checkbox = {});

  app.checkbox.ElementHider = (function() {
    function ElementHider(selector) {
      this.selector = selector;
    }

    ElementHider.prototype.toggle = function(hide) {
      return $(this.selector).toggle(!hide);
    };

    return ElementHider;

  })();

  new app.checkbox.Toggler('hide', app.checkbox.ElementHider).bind();

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.checkbox || (app.checkbox = {});

  app.checkbox.InputEnabler = (function() {
    function InputEnabler(selector) {
      this.selector = selector;
      this.inputs = function() {
        return $('input' + this.selector + ', select' + this.selector + ', textarea' + this.selector);
      };
      this.affected = function() {
        return $(this.selector);
      };
    }

    InputEnabler.prototype.toggle = function(enabled) {
      if (enabled) {
        return this.enable();
      } else {
        return this.disable();
      }
    };

    InputEnabler.prototype.enable = function() {
      this.inputs().prop('disabled', false);
      this.affected().removeClass('disabled');
      return $.each(this.affected(), function(i, e) {
        if (e.selectize) {
          return e.selectize.enable();
        }
      });
    };

    InputEnabler.prototype.disable = function() {
      this.inputs().prop('disabled', true);
      this.affected().addClass('disabled');
      return $.each(this.affected(), function(i, e) {
        if (e.selectize) {
          return e.selectize.disable();
        }
      });
    };

    return InputEnabler;

  })();

  new app.checkbox.Toggler('enable', app.checkbox.InputEnabler).bind();

}).call(this);
(function() {
  var ClearInput;

  ClearInput = (function() {
    function ClearInput() {}

    ClearInput.prototype.clear = function(cross) {
      console.log('click');
      this._input(cross).val('').trigger('change');
      return this._input(cross).parents('form').submit();
    };

    ClearInput.prototype.toggleHide = function(input) {
      var group;
      group = input.parents('.has-clear');
      if (input.val() === '') {
        return group.addClass('has-empty-value');
      } else {
        return group.removeClass('has-empty-value');
      }
    };

    ClearInput.prototype._input = function(cross) {
      return cross.parents('.has-clear').find('input[type=search]');
    };

    ClearInput.prototype.bind = function() {
      var self;
      self = this;
      $(document).on('click', '[data-clear]', function() {
        return self.clear($(this));
      });
      return $(document).on('change', '.has-clear input[type=search]', function() {
        return self.toggleHide($(this));
      });
    };

    return ClearInput;

  })();

  new ClearInput().bind();

  $(document).on('turbolinks:load', function() {
    return $('.has-clear input[type=search]').each(function(i, e) {
      return new ClearInput().toggleHide($(e));
    });
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.DynamicParams = (function() {
    function DynamicParams(element, request1) {
      this.element = element;
      this.request = request1;
      this.url = function() {
        return this.request.url + this.joint() + this.urlParams().join('&');
      };
      this.urlParams = function() {
        var i, len, p, ref, results, value;
        ref = this.dynamicParams();
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          p = ref[i];
          value = $('#' + p.replace('[', '_').replace(']', '')).val() || '';
          results.push(encodeURIComponent(p) + "=" + value);
        }
        return results;
      };
      this.dynamicParams = function() {
        return $(this.element).data('dynamic-params').split(',');
      };
      this.joint = function() {
        if (this.request.url.indexOf('?') === -1) {
          return '?';
        } else {
          return '&';
        }
      };
    }

    DynamicParams.prototype.append = function() {
      return this.request.url = this.url();
    };

    return DynamicParams;

  })();

  $(document).on('ajax:beforeSend', '[data-dynamic-params]', function(event, xhr, request) {
    return new app.DynamicParams(this, request).append();
  });

}).call(this);
(function() {
  var app,
    slice = [].slice;

  app = window.App || (window.App = {});

  app.FormUpdater = (function() {
    function FormUpdater() {
      var event, formSelector, url, watchSelectors;
      url = arguments[0], event = arguments[1], formSelector = arguments[2], watchSelectors = 4 <= arguments.length ? slice.call(arguments, 3) : [];
      this.url = url;
      this.event = event;
      this.form = $(formSelector);
      this.watchedElements = watchSelectors.join(', ');
      this._bind();
    }

    FormUpdater.prototype.updateForm = function() {
      return this._getUrl(this.url);
    };

    FormUpdater.prototype._params = function() {
      return this.form.serialize();
    };

    FormUpdater.prototype._getUrl = function() {
      return $.getScript(this.url + "?" + (this._params()));
    };

    FormUpdater.prototype._bind = function() {
      return $(document).on(this.event, this.watchedElements, (function(_this) {
        return function(event) {
          return _this.updateForm();
        };
      })(this));
    };

    return FormUpdater;

  })();

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.LinkedTableRow = (function() {
    function LinkedTableRow(cell) {
      this.row = $(cell).closest('tr');
      this.url = function() {
        return this.urlTemplate().replace('/:id/', '/' + this.rowId() + '/');
      };
      this.urlTemplate = function() {
        return this.row.closest('[data-row-link]').data('row-link');
      };
      this.rowId = function() {
        return this.row.get(0).id.match(/\w+_(\d+)/)[1];
      };
    }

    LinkedTableRow.prototype.openLink = function() {
      return window.location = this.url();
    };

    return LinkedTableRow;

  })();

  $(document).on('click', '[data-row-link] tbody tr:not([data-no-link=true]) td:not(.no-link)', function(event) {
    return new app.LinkedTableRow(this).openLink();
  });

}).call(this);
(function() {
  var app,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  app = window.App || (window.App = {});

  app.OrderAutocomplete = (function(superClass) {
    extend(OrderAutocomplete, superClass);

    function OrderAutocomplete() {
      return OrderAutocomplete.__super__.constructor.apply(this, arguments);
    }

    OrderAutocomplete.prototype.onItemAdd = function(value, item) {
      if (value) {
        return window.location = window.location.toString().replace(/orders\/\d+/, 'orders/' + value);
      }
    };

    return OrderAutocomplete;

  })(app.Autocomplete);

  $(document).on('turbolinks:load', function() {
    return $('[data-autocomplete=order]').each(function(i, element) {
      return new app.OrderAutocomplete().bind(element);
    });
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.SelectizeRefresher = (function() {
    function SelectizeRefresher(master) {
      this.master = master;
      this.url = function() {
        return this.master.data('url');
      };
      this.params = function() {
        return this.master.serialize();
      };
      this.selectize = function() {
        return $(this.master.data('update'))[0].selectize;
      };
    }

    SelectizeRefresher.prototype.load = function() {
      return $.getJSON(this.url(), this.params(), (function(_this) {
        return function(data) {
          return _this.refresh(data);
        };
      })(this));
    };

    SelectizeRefresher.prototype.refresh = function(data) {
      var selectize;
      selectize = this.selectize();
      selectize.clear();
      selectize.clearOptions();
      data.forEach(function(e) {
        return selectize.addOption({
          value: e.id,
          text: e.label
        });
      });
      return selectize.refreshOptions(false);
    };

    return SelectizeRefresher;

  })();

  $(document).on('change', '[data-update][data-url]', function(event) {
    return new app.SelectizeRefresher($(this)).load();
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.Spinner = (function() {
    function Spinner() {}

    Spinner.prototype.show = function(button) {
      button.prop('disable', true).addClass('disabled');
      button.siblings('.spinner').show();
      return button.find('.spinner').show();
    };

    Spinner.prototype.hide = function(button) {
      button.prop('disable', false).removeClass('disabled');
      button.siblings('.spinner').hide();
      return button.find('.spinner').hide();
    };

    Spinner.prototype.bind = function() {
      var self;
      self = this;
      $(document).on('ajax:beforeSend', '[data-spin]', function() {
        return self.show($(this));
      });
      return $(document).on('ajax:complete', '[data-spin]', function() {
        return self.hide($(this));
      });
    };

    return Spinner;

  })();

  new app.Spinner().bind();

}).call(this);
(function() {
  var app,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  app = window.App || (window.App = {});

  app.WorkItemAutocomplete = (function(superClass) {
    extend(WorkItemAutocomplete, superClass);

    function WorkItemAutocomplete() {
      return WorkItemAutocomplete.__super__.constructor.apply(this, arguments);
    }

    WorkItemAutocomplete.prototype.onItemAdd = function(value, item) {
      var billable, meal_compensation;
      billable = item.attr('data-billable') === 'true';
      meal_compensation = item.attr('data-meal_compensation') === 'true';
      $('#ordertime_billable').prop('checked', billable);
      return $('#ordertime_meal_compensation').prop('checked', meal_compensation);
    };

    WorkItemAutocomplete.prototype.renderOption = function(item, escape) {
      return "<div class='selectize-option'>" + ("<div class='shortname'>" + (escape(item.path_shortnames)) + "</div>") + ("<div class='name'>" + (escape(this.limitText(item.name, 70))) + "</div>") + ("<div class='description'>" + (escape(this.limitText(item.description || '', 120))) + "</div>") + "</div>";
    };

    WorkItemAutocomplete.prototype.renderItem = function(item, escape) {
      return ("<div data-billable=" + item.billable + " data-meal_compensation=" + item.meal_compensation + ">") + ((escape(item.path_shortnames)) + ": " + (escape(item.name)) + "</div>");
    };

    return WorkItemAutocomplete;

  })(app.Autocomplete);

  $(document).on('turbolinks:load', function() {
    return $('[data-autocomplete=work_item]').each(function(i, element) {
      return new app.WorkItemAutocomplete().bind(element);
    });
  });

}).call(this);
(function() {
  window.nested_form_fields || (window.nested_form_fields = {});

  nested_form_fields.bind_nested_forms_links = function() {
    $('body').off("click", '.add_nested_fields_link');
    $('body').on('click', '.add_nested_fields_link', function(event, additional_data) {
      var $child_templates, $link, $parsed_template, $template, added_index, association_path, index_placeholder, object_class, target, template_html;
      $link = $(this);
      object_class = $link.data('object-class');
      association_path = $link.data('association-path');
      added_index = $(".nested_" + association_path).length;
      $.event.trigger("fields_adding.nested_form_fields", {
        object_class: object_class,
        added_index: added_index,
        association_path: association_path,
        additional_data: additional_data
      });
      if ($link.data('scope')) {
        $template = $(($link.data('scope')) + " #" + association_path + "_template");
      } else {
        $template = $("#" + association_path + "_template");
      }
      target = $link.data('insert-into');
      template_html = $template.html();
      index_placeholder = "__" + association_path + "_index__";
      template_html = template_html.replace(new RegExp(index_placeholder, "g"), added_index);
      template_html = template_html.replace(new RegExp("__nested_field_for_replace_with_index__", "g"), added_index);
      $parsed_template = $(template_html);
      $child_templates = $parsed_template.closestChild('.form_template');
      $child_templates.each(function() {
        var $child;
        $child = $(this);
        return $child.replaceWith($("<script id='" + ($child.attr('id')) + "' type='text/html' />").html($child.html()));
      });
      if (target != null) {
        $('#' + target).append($parsed_template);
      } else {
        $template.before($parsed_template);
      }
      $parsed_template.trigger("fields_added.nested_form_fields", {
        object_class: object_class,
        added_index: added_index,
        association_path: association_path,
        event: event,
        additional_data: additional_data
      });
      return false;
    });
    $('body').off("click", '.remove_nested_fields_link');
    return $('body').on('click', '.remove_nested_fields_link', function() {
      var $link, $nested_fields_container, delete_association_field_name, delete_field, object_class, removed_index;
      $link = $(this);
      if (!($.rails === void 0 || $.rails.allowAction($link))) {
        return false;
      }
      if ($link.attr('disabled')) {
        return false;
      }
      object_class = $link.data('object-class');
      delete_association_field_name = $link.data('delete-association-field-name');
      removed_index = parseInt(delete_association_field_name.match('(\\d+\\]\\[_destroy])')[0].match('\\d+')[0]);
      $.event.trigger("fields_removing.nested_form_fields", {
        object_class: object_class,
        delete_association_field_name: delete_association_field_name,
        removed_index: removed_index
      });
      $nested_fields_container = $link.parents(".nested_fields").first();
      delete_field = $nested_fields_container.find("input[type='hidden'][name='" + delete_association_field_name + "']");
      if (delete_field.length > 0) {
        delete_field.val('1');
      } else {
        $nested_fields_container.before("<input type='hidden' name='" + delete_association_field_name + "' value='1' />");
      }
      $nested_fields_container.hide();
      $nested_fields_container.find('input[required]:hidden, select[required]:hidden, textarea[required]:hidden').removeAttr('required');
      $nested_fields_container.trigger("fields_removed.nested_form_fields", {
        object_class: object_class,
        delete_association_field_name: delete_association_field_name,
        removed_index: removed_index
      });
      return false;
    });
  };

  $(document).on("page:change turbolinks:load", function() {
    return nested_form_fields.bind_nested_forms_links();
  });

  jQuery(function() {
    return nested_form_fields.bind_nested_forms_links();
  });

  $.fn.closestChild = function(selector) {
    var $children, $results;
    $children = void 0;
    $results = void 0;
    $children = this.children();
    if ($children.length === 0) {
      return $();
    }
    $results = $children.filter(selector);
    if ($results.length > 0) {
      return $results;
    } else {
      return $children.closestChild(selector);
    }
  };

}).call(this);
(function() {
  var addOptionToSelectize, app, displayFormWithErrors, prepareModalRequest, processCreatedEntry, replaceElementModalContent, showModal;

  app = window.App || (window.App = {});

  prepareModalRequest = function(event, xhr, settings) {
    var index;
    index = settings.url.indexOf('?');
    if (index < 1) {
      return settings.url += '.js';
    } else {
      return settings.url = settings.url.substr(0, index) + '.js' + settings.url.substr(index);
    }
  };

  showModal = function(event, data, status, xhr) {
    var $this, modal, title;
    $this = $(this);
    modal = $($this.data('modal'));
    modal.find('.modal-body').html(data);
    title = $this.data('title');
    if (title) {
      modal.find('.modal-title').html(title);
    }
    modal.data('originator', $this);
    return modal.modal('show');
  };

  processCreatedEntry = function(event, data, status, xhr) {
    var modal, originator;
    data = $.parseJSON(eval(data));
    modal = $(this).closest('.modal');
    originator = modal.data('originator');
    if (originator.data('update') === 'selectize') {
      addOptionToSelectize(originator, data);
    } else if (originator.data('update') === 'element') {
      replaceElementModalContent(originator, data);
    }
    return modal.modal('hide');
  };

  addOptionToSelectize = function(originator, data) {
    var id, idField, selectize;
    selectize = $(originator.data('element'))[0].selectize;
    idField = originator.data('idField');
    id = idField ? data[idField] : data.id;
    selectize.addOption({
      value: id,
      text: data.label
    });
    selectize.refreshOptions(false);
    return selectize.addItem(id);
  };

  replaceElementModalContent = function(originator, data) {
    var content, contentField, element;
    element = $(originator.data('element'));
    contentField = originator.data('contentField');
    content = contentField ? data[contentField] : data.content;
    return element.html(content);
  };

  displayFormWithErrors = function(event, xhr, status, error) {
    var $this;
    $this = $(this);
    $this.closest('.modal-body').html(xhr.responseText);
    return event.stopPropagation();
  };

  $(document).on('ajax:beforeSend', '[data-modal]', prepareModalRequest);

  $(document).on('ajax:success', '[data-modal]', showModal);

  $(document).on('ajax:success', '.modal form', processCreatedEntry);

  $(document).on('ajax:error', '.modal form', displayFormWithErrors);

  $(document).on('click', '.modal .cancel', function(event) {
    $(this).closest('.modal').modal('hide');
    return event.preventDefault();
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.datepicker = new ((function() {
    var formatWeek, i18n, onSelect, options;

    function _Class() {}

    i18n = function() {
      return $.datepicker.regional[$('html').attr('lang')];
    };

    formatWeek = function(date) {
      var week;
      week = $.datepicker.iso8601Week(date);
      if (date.getMonth() + 1 === 12 && Number(week) === 1) {
        return (date.getFullYear() + 1) + " " + week;
      } else {
        return (date.getFullYear()) + " " + week;
      }
    };

    onSelect = function(dateString, instance) {
      var date;
      if (instance.input.data('format') === 'week') {
        date = $.datepicker.parseDate(i18n().dateFormat, dateString);
        instance.input.val(formatWeek(date));
      }
      return instance.input.trigger('change');
    };

    options = $.extend({
      onSelect: onSelect,
      showWeek: true
    }, i18n());

    _Class.prototype.init = function() {
      $('input.date').each(function(_i, elem) {
        return $(elem).datepicker($.extend({}, options, {
          changeYear: $(elem).data('changeyear')
        }));
      });
      return this.bindListeners();
    };

    _Class.prototype.formatWeek = formatWeek;

    _Class.prototype.destroy = function() {
      $('input.date').datepicker('destroy');
      return this.bindListeners(true);
    };

    _Class.prototype.bindListeners = function(unbind) {
      var func;
      func = unbind ? 'off' : 'on';
      return $(document)[func]('click', 'input.date + .input-group-addon', this.show);
    };

    _Class.prototype.show = function(event) {
      var field;
      field = $(event.target);
      if (!field.is('input.date')) {
        field = field.closest('.input-group').find('.date');
      }
      return field.datepicker('show');
    };

    return _Class;

  })());

  $(document).on('turbolinks:load', function() {
    app.datepicker.destroy();
    return app.datepicker.init();
  });

}).call(this);
(function() {
  var app,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  app = window.App || (window.App = {});

  app.worktimes = new ((function() {
    var activationEnabled, headerOffset, scrollSpeed, showMultiAbsence, showRegularAbsence, toggle, worktimesWaypoint;

    function _Class() {
      this.activateNavDayWithDate = bind(this.activateNavDayWithDate, this);
    }

    scrollSpeed = 300;

    activationEnabled = true;

    worktimesWaypoint = null;

    headerOffset = 0;

    toggle = function(selector, disable) {
      $(selector).prop('disabled', disable);
      if (disable) {
        return $(selector).val('');
      }
    };

    showMultiAbsence = function(e) {
      $('#absencetime_create_multi').val('true');
      $('#single').hide();
      $('#multi').show();
      if (e) {
        return e.preventDefault();
      }
    };

    showRegularAbsence = function(e) {
      $('#absencetime_create_multi').val('');
      $('#single').show();
      $('#multi').hide();
      if (e) {
        return e.preventDefault();
      }
    };

    _Class.prototype.init = function() {
      this.bind();
      this.initWaypoint();
      return this.initScroll();
    };

    _Class.prototype.container = function(selector) {
      if (selector) {
        return $(selector, '.worktimes-container');
      } else {
        return $('.worktimes-container');
      }
    };

    _Class.prototype.bind = function() {
      $('#new_ordertime_link').click(function(e) {
        e.preventDefault();
        return window.location.href = ($(this).attr('href')) + "?work_date=" + ($('#week_date').val());
      });
      $('#new_other_ordertime_link').click(function(e) {
        e.preventDefault();
        return window.location.href = ($(this).attr('href')) + "&work_date=" + ($('#week_date').val());
      });
      if (this.container().length) {
        $('#week_date').on('change', function(event) {
          var date;
          date = event.target.value;
          window.location = "/worktimes?week_date=" + date;
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
      $('#multi_absence_link').click(showMultiAbsence);
      return $('#regular_absence_link').click(showRegularAbsence);
    };

    _Class.prototype.initWaypoint = function() {
      if (worktimesWaypoint) {
        worktimesWaypoint.destroy();
        worktimesWaypoint = null;
      }
      headerOffset = ($(window).width() > 768 ? $('header').height() : 0);
      if (this.container().length) {
        this.container('.weekcontent .date-label').waypoint({
          handler: function(direction) {
            if (direction === 'down') {
              return app.worktimes.activateNavDayWithDate($(this.element).data('date'));
            } else if (direction === 'up' && $(this.element).prev().length) {
              return app.worktimes.activateNavDayWithDate($(this.element).prev().data('date'));
            }
          },
          offset: function() {
            return $('.weeknav').height() + headerOffset;
          }
        });
        this.container('.weeknav .day').on('click', (function(_this) {
          return function(e) {
            var date;
            e.preventDefault();
            date = new Date($(e.currentTarget).data('date'));
            $('#week_date').datepicker('setDate', date);
            return _this.scrollToDayWithDate($(e.currentTarget).data('date'));
          };
        })(this));
        if (!Modernizr.csspositionsticky) {
          return setTimeout((function(_this) {
            return function() {
              return worktimesWaypoint = new Waypoint.Sticky({
                element: _this.container()[0]
              });
            };
          })(this));
        }
      }
    };

    _Class.prototype.initScroll = function() {
      var day, selectedDate;
      if (this.container().length && !$('.alert:not(.alert-success)', 'main').length) {
        selectedDate = this.container().data('selectedDate');
        if (!selectedDate) {
          return;
        }
        day = this.container(".weeknav .day[data-date=\"" + selectedDate + "\"]");
        if (day.length) {
          return day.click();
        }
      }
    };

    _Class.prototype.activate = function(selector) {
      if (!activationEnabled) {
        return;
      }
      return this.container('.weeknav .day').removeClass('active').filter(selector).addClass('active');
    };

    _Class.prototype.activateNavDayWithDate = function(date) {
      return this.activate("[data-date=\"" + date + "\"]");
    };

    _Class.prototype.activateFirstNavDay = function() {
      return this.activate(':first-child');
    };

    _Class.prototype.activateLastNavDay = function() {
      return this.activate(':last-child');
    };

    _Class.prototype.scrollToDayWithDate = function(date) {
      var dateLabel, offset;
      dateLabel = this.container(".weekcontent .date-label[data-date=\"" + date + "\"]");
      if (dateLabel.length === 0) {
        return;
      }
      offset = dateLabel.offset().top - this.container('.weeknav').height() - 20 - headerOffset;
      return this.scrollTo(offset, this.activateNavDayWithDate, date);
    };

    _Class.prototype.scrollTo = function(offset, callback, date) {
      activationEnabled = false;
      return $('html, body').animate({
        scrollTop: offset
      }, scrollSpeed, void 0, (function(_this) {
        return function() {
          var entries;
          activationEnabled = true;
          callback(date);
          if (date) {
            entries = _this.container('.weekcontent .date-label[data-date="' + date + '"], ' + '.weekcontent .entry[data-date="' + date + '"]');
            entries.addClass('highlight');
            return setTimeout((function() {
              return entries.removeClass('highlight');
            }), 400);
          }
        };
      })(this));
    };

    return _Class;

  })());

  $(document).on('turbolinks:load', function() {
    return app.worktimes.init();
  });

}).call(this);
(function() {
  var app,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    slice = [].slice;

  app = window.App || (window.App = {});

  app.plannings || (app.plannings = {});

  app.plannings = new ((function() {
    var addRowOptions, addRowSelect, addRowSelectize, board, positioningHeaders, waypoints;

    function _Class() {
      this.positionHeaders = bind(this.positionHeaders, this);
      this.onAddSelect = bind(this.onAddSelect, this);
      this.add = bind(this.add, this);
    }

    board = '.planning-calendar';

    addRowSelect = null;

    addRowSelectize = null;

    addRowOptions = [];

    waypoints = [];

    positioningHeaders = false;

    _Class.prototype.init = function() {
      this.bindListeners();
      this.dateFilterChanged();
      this.initSelectize();
      this.initGroupheaders();
      this.initWaypoints();
      return this.positionHeaders();
    };

    _Class.prototype.destroy = function() {
      this.bindListeners(true);
      return this.destroyWaypoints();
    };

    _Class.prototype.reloadAll = function() {
      return [this, app.plannings.selectable, app.plannings.panel].forEach((function(_this) {
        return function(p) {
          p.destroy();
          return p.init();
        };
      })(this));
    };

    _Class.prototype.dateFilterChanged = function() {
      return $('#planning_filter_form').find('#start_date,#end_date').closest('.form-group').css('visibility', !$('#period_shortcut').val() ? 'visible' : 'hidden');
    };

    _Class.prototype.add = function(event) {
      return this.showSelect(event);
    };

    _Class.prototype.showSelect = function(event) {
      var actionData;
      actionData = $(event.target).closest('.actions').data();
      addRowSelectize.setValue(null);
      addRowSelectize.clearOptions();
      addRowOptions.filter(function(option) {
        return option != null ? option.value : void 0;
      }).forEach((function(_this) {
        return function(option) {
          actionData[actionData.type + "Id"] = option.value;
          if (_this.board().has("#planning_row_employee_" + actionData.employeeId + "_work_item_" + actionData.workItemId).length) {
            return;
          }
          return addRowSelectize.addOption(option);
        };
      })(this));
      $(event.target).closest('.buttons').prepend(addRowSelect);
      this.board('.add').show();
      $(event.target).hide();
      addRowSelect.show();
      return requestAnimationFrame((function(_this) {
        return function() {
          return addRowSelectize.refreshOptions();
        };
      })(this));
    };

    _Class.prototype.addRow = function(employeeId, workItemId) {
      return app.plannings.service.addPlanningRow(employeeId, workItemId).then((function(_this) {
        return function() {
          addRowSelect.hide();
          _this.board('.add').show();
          return _this.initWaypoints();
        };
      })(this));
    };

    _Class.prototype.onAddSelect = function(value) {
      var employeeId, workItemId;
      if (value) {
        if (addRowSelect.is('#add_employee_id')) {
          employeeId = value;
          workItemId = addRowSelect.closest('.actions').data('work-item-id');
        } else if (addRowSelect.is('#add_work_item_id')) {
          workItemId = value;
          employeeId = addRowSelect.closest('.actions').data('employee-id');
        } else {
          throw new Error('Unknown select!');
        }
        return this.addRow(employeeId, workItemId);
      }
    };

    _Class.prototype.bindListeners = function(unbind) {
      var func;
      func = unbind ? 'off' : 'on';
      this.board('.actions .add')[func]('click', this.add);
      return $('main')[func]('scroll', this.positionHeaders);
    };

    _Class.prototype.initSelectize = function() {
      var ref;
      addRowSelect = $('#add_employee_id,#add_work_item_id');
      addRowSelectize = (ref = addRowSelect.children('select').selectize({
        selectOnTab: true,
        dropdownParent: 'body',
        onItemAdd: this.onAddSelect
      }).get(0)) != null ? ref.selectize : void 0;
      if (!addRowSelectize) {
        return;
      }
      return addRowOptions = [void 0].concat(slice.call(Object.keys(addRowSelectize.options).map(function(key) {
          return addRowSelectize.options[key];
        })));
    };

    _Class.prototype.initGroupheaders = function() {
      $('.groupheader').click(function(e) {
        var children, collapsed;
        if ($(e.target).hasClass('day')) {
          return;
        }
        collapsed = $(this).hasClass('collapsed');
        $(this).toggleClass('collapsed', !collapsed).find('.glyphicon').toggleClass('glyphicon-chevron-left', !collapsed).toggleClass('glyphicon-chevron-down', collapsed).end().nextUntil('.groupheader').toggle(collapsed);
        app.plannings.positionHeaders();
        if (collapsed) {
          $(this).children().removeClass('has-planning');
          if ($(this).next('.actions').length) {
            return $(this).next('.actions').find('.add').click();
          }
        } else {
          children = $(this).children();
          return $(this).nextUntil('.actions,.groupheader').find('.day').filter('.-definitive,.-provisional').map(function() {
            return children.get($(this.parentNode.children).index(this));
          }).addClass('has-planning');
        }
      });
      $('.groupheader').filter(function() {
        return !$(this).nextUntil('.groupheader').length;
      }).find('.glyphicon').remove();
      return $('.groupheader').filter(function() {
        return $(this).next('.actions,.groupheader').length || $(this).is(':last-child');
      }).click();
    };

    _Class.prototype.initWaypoints = function() {
      if (Modernizr.csspositionsticky) {
        return;
      }
      waypoints = [];
      this.destroyWaypoints();
      this.initTopCalendarHeaderWaypoints();
      return this.initLeftCalendarHeaderWaypoints();
    };

    _Class.prototype.initTopCalendarHeaderWaypoints = function() {
      return $('.planning-calendar').toArray().map(function(el) {
        return [$(el).find('.planning-calendar-weeks'), $(el).find('.planning-calendar-days-header')];
      }).forEach(function(arg) {
        var daysHeader, weeks;
        weeks = arg[0], daysHeader = arg[1];
        waypoints.push(new Waypoint.Sticky({
          element: weeks,
          context: $('main')
        }));
        return waypoints.push(new Waypoint.Sticky({
          element: daysHeader,
          context: $('main')
        }));
      });
    };

    _Class.prototype.initLeftCalendarHeaderWaypoints = function() {
      return this.getLeftCalendarHeaderElements().each(function(_i, element) {
        return waypoints.push(new Waypoint.Sticky({
          element: element,
          context: $('main'),
          horizontal: true
        }));
      });
    };

    _Class.prototype.positionHeaders = function() {
      if (!positioningHeaders) {
        requestAnimationFrame((function(_this) {
          return function() {
            _this.positionBoardHeader();
            if (!Modernizr.csspositionsticky) {
              $('.planning-calendar-weeks,.planning-calendar-days-header').each(function(_i, element) {
                return _this.positionTopCalendarHeader(element);
              });
              _this.getLeftCalendarHeaderElements().each(function(_i, element) {
                return _this.positionLeftCalendarHeader(element);
              });
            }
            return positioningHeaders = false;
          };
        })(this));
      }
      return positioningHeaders = true;
    };

    _Class.prototype.positionBoardHeader = function() {
      return $('.planning-board-header').css('left', $(document).scrollLeft() + 'px');
    };

    _Class.prototype.positionTopCalendarHeader = function(element) {
      var firstDay, leftHeaderWidth, offset, ref;
      if ($(element).hasClass('stuck')) {
        leftHeaderWidth = parseInt($('.legend').first().css('width'), 10);
        firstDay = $(element).closest('.planning-calendar-inner').find('.day:first');
        offset = ((ref = firstDay[0]) != null ? ref.getBoundingClientRect().left : void 0) - leftHeaderWidth;
        return $(element).css('left', offset + 'px');
      } else {
        return $(element).css('left', 'auto');
      }
    };

    _Class.prototype.positionLeftCalendarHeader = function(element) {
      var offset;
      if ($(element).hasClass('stuck')) {
        offset = $(element).closest('.sticky-wrapper')[0].getBoundingClientRect().top;
        return $(element).css('top', offset + 'px');
      } else {
        return $(element).css('top', 'auto');
      }
    };

    _Class.prototype.getLeftCalendarHeaderElements = function() {
      return $(['.planning-calendar-inner > .groupheader .legend', '.planning-calendar-inner > .actions .buttons', '.planning-calendar-days .legend', '.planning-board-header', '.planning-legend'].join(','));
    };

    _Class.prototype.destroyWaypoints = function() {
      waypoints.forEach(function(waypoint) {
        return waypoint.destroy();
      });
      waypoints = [];
      $('.stuck').removeClass('stuck');
      return $('.sticky-wrapper').replaceWith(function() {
        return this.children;
      });
    };

    _Class.prototype.board = function(selector) {
      if (selector) {
        return $(selector, board);
      } else {
        return $(board);
      }
    };

    return _Class;

  })());

  $(document).on('turbolinks:load', function() {
    app.plannings.destroy();
    return app.plannings.init();
  });

}).call(this);
(function() {
  var app,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  app = window.App || (window.App = {});

  app.plannings || (app.plannings = {});

  app.plannings.panel = new ((function() {
    var container, default_repeat_offset, focusPercentOnShow, panel, positioning;

    function _Class() {
      this.position = bind(this.position, this);
      this.repetitionChange = bind(this.repetitionChange, this);
      this.definitiveChange = bind(this.definitiveChange, this);
      this.deleteSelected = bind(this.deleteSelected, this);
      this.submit = bind(this.submit, this);
      this.cancel = bind(this.cancel, this);
    }

    default_repeat_offset = 7;

    panel = '.planning-panel';

    container = '.planning-calendar';

    positioning = false;

    focusPercentOnShow = false;

    _Class.prototype.init = function() {
      if (this.panel().length === 0) {
        return;
      }
      return this.bindListeners();
    };

    _Class.prototype.destroy = function() {
      return this.bindListeners(true);
    };

    _Class.prototype.bindListeners = function(unbind) {
      var func;
      func = unbind ? 'off' : 'on';
      $('main')[func]('scroll', this.position);
      this.panel('.planning-definitive-group button')[func]('click', this.definitiveChange);
      this.panel('#repetition')[func]('click', this.repetitionChange);
      this.panel('.planning-cancel')[func]('click', this.cancel);
      this.panel('form')[func]('submit', this.submit);
      return this.panel('.planning-delete')[func]('click', this.deleteSelected);
    };

    _Class.prototype.show = function(selectedElements) {
      var hasExisting;
      this.position();
      this.hideErrors();
      this.initPercent();
      this.initDefinitive();
      this.initRepetition();
      hasExisting = app.plannings.selectable.selectionHasExistingPlannings();
      return this.panel('.planning-delete').css('visibility', hasExisting ? 'visible' : 'hidden');
    };

    _Class.prototype.hide = function() {
      return $(panel).hide();
    };

    _Class.prototype.cancel = function(event) {
      $(event.target).blur();
      return app.plannings.selectable.clear();
    };

    _Class.prototype.showErrors = function(errors) {
      var alert, alerts;
      alerts = this.panel('.alerts').empty();
      if (errors != null ? errors.length : void 0) {
        alert = '<div class="alert alert-danger">';
        if (errors.length > 1) {
          alert += '<ul>';
          errors.forEach(function(error) {
            return alert += "<li>" + error + "</li>";
          });
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
    };

    _Class.prototype.hideErrors = function() {
      return this.panel('.alert').hide();
    };

    _Class.prototype.submit = function(event) {
      var data;
      event.preventDefault();
      this.hideErrors();
      data = $(event.target).serializeArray().reduce((function(prev, curr) {
        prev[curr.name] = curr.value;
        return prev;
      }), {});
      return this.disableButtons(app.plannings.service.updateSelected(this.getFormAction(), data));
    };

    _Class.prototype.deleteSelected = function(event) {
      if (confirm('Bist du sicher, dass du die selektierte Planung löschen willst?')) {
        event.preventDefault();
        return this.disableButtons(app.plannings.service["delete"](this.getFormAction(), app.plannings.selectable.getSelectedPlanningIds()));
      }
    };

    _Class.prototype.getFormAction = function() {
      return this.panel('form').prop('action');
    };

    _Class.prototype.setPercent = function(percent, indefinite) {
      return this.panel('#percent').val(percent).prop('placeholder', indefinite ? '?' : '');
    };

    _Class.prototype.initPercent = function() {
      var percent, values;
      values = app.plannings.selectable.getSelectedPercentValues();
      percent = values.length === 1 ? values[0] : '';
      this.setPercent(percent, values.length > 1);
      return focusPercentOnShow = values.length === 1;
    };

    _Class.prototype.setDefinitive = function(definitive) {
      var value;
      this.panel('.planning-definitive').toggleClass('active', definitive === true);
      this.panel('.planning-provisional').toggleClass('active', definitive === false);
      value = definitive != null ? definitive.toString() : '';
      return this.panel('#definitive').val(value);
    };

    _Class.prototype.initDefinitive = function() {
      var values;
      values = app.plannings.selectable.getSelectedDefinitiveValues();
      if (values.length === 1) {
        return this.setDefinitive(values[0] === null ? false : values[0]);
      } else {
        return this.setDefinitive(null);
      }
    };

    _Class.prototype.definitiveChange = function(event) {
      var current, source;
      source = $(event.target).hasClass('planning-definitive');
      current = this.panel('#definitive').val();
      return this.setDefinitive(source.toString() === current ? null : source);
    };

    _Class.prototype.initDatepickerValue = function() {
      var date;
      date = app.plannings.selectable.getSelectedDays()[0].date;
      date = new Date(date);
      date.setDate(date.getDate() + default_repeat_offset);
      return this.panel('#repeat_until').datepicker('option', 'defaultDate', date).val(app.datepicker.formatWeek(date));
    };

    _Class.prototype.initRepetition = function() {
      this.panel('#repetition').prop('checked', false);
      this.panel('.planning-repetition-group').hide();
      this.panel('#repeat_until').prop('disabled', true);
      return this.initDatepickerValue();
    };

    _Class.prototype.repetitionChange = function(event) {
      var enabled;
      enabled = $(event.target).prop('checked');
      this.panel('#repeat_until').prop('disabled', !enabled);
      this.panel('.planning-repetition-group')[enabled ? 'show' : 'hide']();
      return this.initDatepickerValue();
    };

    _Class.prototype.position = function(e) {
      var hasSelection;
      hasSelection = function() {
        return $(container).find('.ui-selected').length;
      };
      if (this.panel().length === 0 || ((e != null ? e.type : void 0) === 'scroll' && this.panel().is(':hidden')) || !hasSelection()) {
        return;
      }
      if (!positioning) {
        requestAnimationFrame((function(_this) {
          return function() {
            var wasHidden;
            if (!hasSelection()) {
              positioning = false;
              return;
            }
            wasHidden = _this.panel().is(':hidden');
            _this.panel().show().position({
              my: 'right top',
              at: 'right bottom',
              of: $(container).find('.ui-selected').last(),
              within: 'body',
              collision: 'flipfit flipfit'
            });
            positioning = false;
            if (wasHidden) {
              if (focusPercentOnShow) {
                return _this.panel('#percent').focus().select();
              } else {
                return _this.panel('#percent').blur();
              }
            }
          };
        })(this));
      }
      return positioning = true;
    };

    _Class.prototype.disableButtons = function(promise) {
      var buttons;
      buttons = this.panel('.panel-footer .btn');
      buttons.prop('disabled', true);
      return promise.always(function() {
        return buttons.prop('disabled', false);
      });
    };

    _Class.prototype.panel = function(selector) {
      if (selector) {
        return $(selector, panel);
      } else {
        return $(panel);
      }
    };

    return _Class;

  })());

  $(document).on('turbolinks:load', function() {
    app.plannings.panel.destroy();
    return app.plannings.panel.init();
  });

}).call(this);
(function() {
  var app,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  app = window.App || (window.App = {});

  app.plannings || (app.plannings = {});

  app.plannings.selectable = new ((function() {
    var copyCell, isSelecting, selectable, selectee;

    function _Class() {
      this.startTranslate = bind(this.startTranslate, this);
      this.start = bind(this.start, this);
      this.clearOnEscape = bind(this.clearOnEscape, this);
      this.preventClear = bind(this.preventClear, this);
      this.clear = bind(this.clear, this);
    }

    selectable = '.planning-calendar-inner.editable';

    selectee = '.planning-calendar-days > .day';

    isSelecting = false;

    _Class.prototype.init = function() {
      if (this.selectable().length === 0) {
        return;
      }
      this.bindListeners();
      return this.selectable().selectable({
        filter: selectee,
        cancel: ['a', '.actions', '.legend'].join(','),
        classes: {
          'ui-selected': '-selected',
          'ui-selecting': '-selected'
        },
        start: this.start,
        stop: this.stop
      });
    };

    _Class.prototype.destroy = function() {
      this.bindListeners(true);
      if (this.selectable().selectable('instance')) {
        return this.selectable().selectable('destroy');
      }
    };

    _Class.prototype.bindListeners = function(unbind) {
      var func;
      func = unbind ? 'off' : 'on';
      $(document)[func]('click', this.clear);
      $(document)[func]('keyup', this.clearOnEscape);
      this.selectable()[func]('click', this.stopPropagation);
      return this.selectable()[func]('mousedown', '.ui-selected', this.startTranslate);
    };

    _Class.prototype.clear = function(e) {
      var selected;
      if (!this.preventClear(e)) {
        selected = this.selectable('.ui-selected');
        if ((e != null ? e.type : void 0) === 'selectablestart') {
          selected = this.selectable().not(e.target).find('.ui-selected');
        }
        selected.removeClass('ui-selected -selected');
        return app.plannings.panel.hide();
      }
    };

    _Class.prototype.preventClear = function(e) {
      var ignoredContainers;
      ignoredContainers = '.panel, .ui-datepicker';
      return e && ($(e.target).closest(ignoredContainers).length || $(e.target).is(':hidden'));
    };

    _Class.prototype.clearOnEscape = function(event) {
      if (event.key === 'Escape') {
        return this.clear();
      }
    };

    _Class.prototype.stopPropagation = function(event) {
      return event.stopPropagation();
    };

    _Class.prototype.getSelectedDays = function(elements) {
      if (elements == null) {
        elements = this.selectable('.ui-selected');
      }
      return elements.toArray().map((function(_this) {
        return function(element) {
          var _match, date, employee_id, ref, row, work_item_id;
          row = $(element).parent();
          ref = row.prop('id').match(/planning_row_employee_(\d+)_work_item_(\d+)/), _match = ref[0], employee_id = ref[1], work_item_id = ref[2];
          date = _this.selectable('.planning-calendar-days-header .dayheader').eq(row.children('.day').index(element)).data('date');
          return {
            employee_id: employee_id,
            work_item_id: work_item_id,
            date: date
          };
        };
      })(this));
    };

    _Class.prototype.getSelectedPlanningIds = function() {
      return this.selectable('.ui-selected').toArray().map(function(el) {
        return el.dataset.id;
      }).filter(function(id) {
        return id;
      });
    };

    _Class.prototype.getSelectedPercentValues = function() {
      return this.selectable('.ui-selected').toArray().map(function(element) {
        return $(element).text().trim();
      }).filter(function(value, index, self) {
        return self.indexOf(value) === index;
      });
    };

    _Class.prototype.getSelectedDefinitiveValues = function() {
      return this.selectable('.ui-selected').toArray().map(function(element) {
        if ($(element).hasClass('-definitive')) {
          return true;
        } else if ($(element).hasClass('-provisional')) {
          return false;
        } else {
          return null;
        }
      }).filter(function(value, index, self) {
        return self.indexOf(value) === index;
      });
    };

    _Class.prototype.selectionHasExistingPlannings = function() {
      return this.selectable('.ui-selected.-definitive,.ui-selected.-provisional').length > 0;
    };

    _Class.prototype.start = function(event, ui) {
      isSelecting = true;
      this.clear(event);
      return setTimeout((function() {
        return isSelecting && app.plannings.panel.hide();
      }), 100);
    };

    _Class.prototype.stop = function(event, ui) {
      var selectedElements;
      isSelecting = false;
      selectedElements = $(event.target).find('.ui-selected');
      selectedElements.addClass('-selected');
      if (selectedElements.length > 0) {
        return app.plannings.panel.show(selectedElements);
      }
    };

    _Class.prototype.selectable = function(selector) {
      if (selector) {
        return $(selector, selectable);
      } else {
        return $(selectable);
      }
    };

    _Class.prototype.startTranslate = function(e) {
      var children, currentlySelected, daysToUpdate, getRows, maxSelectedIndex, maxTranslateBy, minTranslateBy, originalRows, selectedIndexes, startNodeIndex, translateBy;
      if (!e.target.matches('.-definitive,.-provisional')) {
        return;
      }
      e.stopPropagation();
      currentlySelected = this.selectable('.ui-selected');
      daysToUpdate = this.getSelectedDays(currentlySelected.filter('.-definitive,.-provisional'));
      children = e.target.parentNode.children;
      startNodeIndex = $(children).index(e.target);
      selectedIndexes = Array.from(currentlySelected, function(el) {
        return $(el.parentNode.children).index(el);
      });
      minTranslateBy = -selectedIndexes.reduce(function(a, b) {
        return Math.min(a, b);
      });
      maxSelectedIndex = selectedIndexes.reduce(function(a, b) {
        return Math.max(a, b);
      });
      maxTranslateBy = children.length - maxSelectedIndex;
      translateBy = 0;
      getRows = function(elements) {
        return $.unique(elements.map(function() {
          return this.parentNode;
        }));
      };
      originalRows = getRows(currentlySelected).clone();
      this.selectable().on('mousemove', (function(_this) {
        return function(e) {
          var currentNodeIndex, currentTranslateBy;
          e.stopPropagation();
          if (e.target.matches('.day')) {
            app.plannings.panel.hide();
            currentNodeIndex = $(e.target.parentNode.children).index(e.target);
            currentTranslateBy = currentNodeIndex - startNodeIndex;
            translateBy = Math.max(minTranslateBy + 1, Math.min(maxTranslateBy - 1, currentTranslateBy));
            _this.resetCellsOfRows(getRows(_this.selectable('.ui-selected')), originalRows, translateBy);
            return _this.translateDays(currentlySelected, translateBy);
          }
        };
      })(this));
      return this.selectable().on('mouseup', (function(_this) {
        return function(e) {
          _this.selectable().off('mousemove mouseup');
          if (translateBy) {
            return _this.updateDayTranslation(daysToUpdate, translateBy);
          }
        };
      })(this));
    };

    _Class.prototype.resetCellsOfRows = function(rows, originalRows, unselect) {
      return Array.from(rows, function(row, i) {
        return Array.from(row.children, function(cell, j) {
          copyCell(cell, originalRows[i].children[j]);
          if (unselect) {
            cell.classList.remove('ui-selected', '-selected');
          }
          return cell;
        });
      });
    };

    copyCell = function(to, from) {
      to.innerHTML = from.innerHTML;
      to.className = from.className;
      return to;
    };

    _Class.prototype.translateDays = function(days, translateBy) {
      if (!translateBy) {
        return;
      }
      return Array.from(days, function(el) {
        return [$(el.parentNode.children).index(el), el.parentNode];
      }).map(function(arg) {
        var i, parentNode;
        i = arg[0], parentNode = arg[1];
        return [parentNode.children[i], parentNode.children[i + translateBy]];
      })["do"](function() {
        if (translateBy > 0) {
          return this.reverse();
        }
      }).forEach(function(arg) {
        var from, to;
        from = arg[0], to = arg[1];
        copyCell(to, from);
        to.classList.add('ui-selected', '-selected');
        from.className = 'day';
        return from.innerHTML = '';
      });
    };

    _Class.prototype.updateDayTranslation = function(items, translateBy) {
      return app.plannings.service.update("" + window.location.origin + window.location.pathname, {
        items: items,
        planning: {
          translate_by: translateBy
        }
      });
    };

    return _Class;

  })());

  $(document).on('turbolinks:load', function() {
    app.plannings.selectable.destroy();
    return app.plannings.selectable.init();
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.plannings || (app.plannings = {});

  app.plannings.service = new ((function() {
    function _Class() {}

    _Class.prototype.updateSelected = function(url, planning) {
      var token;
      planning.utf8 = void 0;
      token = planning.authenticity_token;
      planning.authenticity_token = void 0;
      return this.update(url, {
        planning: planning,
        items: app.plannings.selectable.getSelectedDays(),
        authenticity_token: token
      }).fail(function(res) {
        return console.log('update error', res.status, res.statusText);
      });
    };

    _Class.prototype.update = function(url, data) {
      return $.ajax({
        type: 'PATCH',
        url: url,
        data: this._buildParams(data)
      });
    };

    _Class.prototype["delete"] = function(url, ids) {
      return $.ajax({
        type: 'DELETE',
        url: url,
        data: this._buildParams({
          planning_ids: ids
        })
      });
    };

    _Class.prototype.addPlanningRow = function(employee_id, work_item_id) {
      return $.ajax({
        url: "" + window.location.origin + window.location.pathname + "/new",
        data: this._buildParams({
          employee_id: employee_id,
          work_item_id: work_item_id
        })
      });
    };

    _Class.prototype._buildParams = function(params) {
      return $.extend({
        utf8: '✓'
      }, params);
    };

    return _Class;

  })());

}).call(this);
(function() {
  var renderIconItem, renderStyleItem;

  renderIconItem = function(item, escape) {
    return '<div><span class="glyphicon glyphicon-' + item.value + '"></span> ' + escape(item.value) + '</div>';
  };

  renderStyleItem = function(item, escape) {
    return '<div><span class="label label-' + item.value + '">' + escape(item.value) + '</span></div>';
  };

  $(document).on('click', '[data-submit-form]', function(event) {
    var form_id;
    form_id = $(this).attr('data-submit-form');
    $(form_id).submit();
    return event.preventDefault();
  });

  $(document).on('turbolinks:load', function() {
    var cwi;
    cwi = $('#client_work_item_id');
    if (cwi.length > 0 && cwi[0].selectize) {
      cwi[0].selectize.on('change', function(element) {
        var categoryParam;
        $('#category_active').prop('disabled', false);
        categoryParam = 'work_item[parent_id]=' + element;
        return $('#category_work_item_id_create_link').attr('data-params', categoryParam).data('params', categoryParam);
      });
    }
    $('#target_scope_icon').selectize({
      render: {
        option: renderIconItem,
        item: renderIconItem
      }
    });
    return $('#order_status_style').selectize({
      render: {
        option: renderStyleItem,
        item: renderStyleItem
      }
    });
  });

}).call(this);
(function() {
  var app, replaceContactsWithCrm;

  app = window.App || (window.App = {});

  app.loadContactsWithCrm = function() {
    var addButton, clientId, url;
    clientId = $('#client_work_item_id').val();
    if (clientId.length < 1) {
      $('.add_nested_fields_link[data-association-path=order_order_contacts]').addClass('disabled');
      return;
    }
    url = $('form[data-contacts-url]').data('contacts-url');
    url = url += '?client_work_item_id=' + clientId;
    addButton = $('.add_nested_fields_link[data-association-path=order_order_contacts]');
    addButton.hide().siblings('.spinner').show();
    if (this.xhr) {
      this.xhr.abort();
    }
    return this.xhr = $.getJSON(url, function(data) {
      replaceContactsWithCrm(data);
      return addButton.show().removeClass('disabled').siblings('.spinner').hide();
    });
  };

  replaceContactsWithCrm = function(data) {
    var modified, original;
    original = $('#order_order_contacts_template').html();
    if (!original) {
      return;
    }
    modified = original.replace(/<option value=".+">.*<\/option>/g, '');
    data.forEach(function(element) {
      var option;
      option = "<option value=\"" + element.id_or_crm + "\">" + element.label + "</option>";
      return modified = modified.replace(/<\/select>/, option + '</select>');
    });
    return $('#order_order_contacts_template').html(modified);
  };

  $(document).on('change', '#new_order #client_work_item_id', app.loadContactsWithCrm);

  $(document).on('turbolinks:load', function() {
    if (!$('#client_work_item_id').val()) {
      return $('.add_nested_fields_link[data-association-path=order_order_contacts]').addClass('disabled');
    }
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.initOrderControllingChart = function(labels, datasets, budget, currency, currentLabel) {
    var budgetColor, canvas, chart, ctx, formatCurrency, gridColor, gridLightColor, todayColor;
    canvas = document.getElementById('order_controlling_chart');
    ctx = canvas.getContext('2d');
    Chart.defaults.global.defaultFontFamily = 'Roboto, Helvetica, Arial, sans-serif';
    Chart.defaults.global.defaultFontColor = '#444444';
    Chart.defaults.global.defaultFontSize = 14;
    budgetColor = '#B44B5B';
    todayColor = '#f0ad4e';
    gridColor = 'rgba(0,0,0,0.1)';
    gridLightColor = 'rgba(0,0,0,0.02)';
    formatCurrency = function(value) {
      return Number(value).toLocaleString() + ' ' + currency;
    };
    return chart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: datasets
      },
      options: {
        responsive: false,
        scales: {
          xAxes: [
            {
              stacked: true,
              gridLines: {
                color: gridColor
              }
            }
          ],
          yAxes: [
            {
              stacked: true,
              ticks: {
                beginAtZero: true,
                callback: formatCurrency
              },
              gridLines: {
                color: gridLightColor,
                zeroLineColor: gridColor
              }
            }
          ]
        },
        legend: {
          labels: {
            boxWidth: Chart.defaults.global.defaultFontSize
          }
        },
        tooltips: {
          callbacks: {
            label: function(item, data) {
              return data.datasets[item.datasetIndex].label + ': ' + formatCurrency(item.yLabel);
            }
          }
        },
        annotation: {
          annotations: [
            {
              type: 'line',
              mode: 'vertical',
              scaleID: 'x-axis-0',
              value: currentLabel,
              borderColor: todayColor,
              borderWidth: 2,
              label: {
                enabled: true,
                content: 'heute',
                position: 'top',
                yAdjust: 10,
                xPadding: 2,
                yPadding: 3,
                backgroundColor: '#ffffff',
                fontFamily: Chart.defaults.global.defaultFontFamily,
                fontSize: Chart.defaults.global.defaultFontSize,
                fontStyle: 'normal',
                fontColor: todayColor
              }
            }, {
              type: 'line',
              mode: 'horizontal',
              scaleID: 'y-axis-0',
              value: budget,
              borderColor: budgetColor,
              borderWidth: 2,
              label: {
                enabled: true,
                content: 'Budget ' + formatCurrency(budget),
                position: 'left',
                yAdjust: 11,
                backgroundColor: 'transparent',
                fontFamily: Chart.defaults.global.defaultFontFamily,
                fontSize: Chart.defaults.global.defaultFontSize,
                fontStyle: 'normal',
                fontColor: budgetColor
              }
            }
          ]
        }
      }
    });
  };

}).call(this);
(function() {
  var app,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  app = window.App || (window.App = {});

  app.orderServices = new ((function() {
    function _Class() {
      this.selectionChanged = bind(this.selectionChanged, this);
    }

    _Class.prototype.init = function() {
      this.dateFilterChanged();
      this.initSelection();
      return this.selectionChanged();
    };

    _Class.prototype.dateFilterChanged = function() {
      return $('#order_services_filter_form').find('#start_date,#end_date').datepicker('option', 'disabled', $('#period_shortcut').val());
    };

    _Class.prototype.initSelection = function() {
      return $('body.order_services #worktimes').on('change', '[name="worktime_ids[]"],#all_worktimes', this.selectionChanged);
    };

    _Class.prototype.selectionChanged = function() {
      return $('[data-submit-form="#worktimes"]').prop('hidden', !$('[name="worktime_ids[]"]:checked').length);
    };

    return _Class;

  })());

  $(document).on('ajax:success', '#order_services_filter_form', function() {
    return app.orderServices.init();
  });

  $(document).on('turbolinks:load', function() {
    return app.orderServices.init();
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  $(document).on('turbolinks:load', function() {
    var $hoursPerDay, activeSource, handle_book_on_order_radio, updateOfferedValues;
    handle_book_on_order_radio = function(value) {
      var work_item_fields;
      work_item_fields = $('#work_item_fields');
      if (value === 'true') {
        return work_item_fields.hide();
      } else {
        return work_item_fields.show();
      }
    };
    $('input[name=book_on_order]').on('change', function(event) {
      var value;
      value = event.target.value.toLowerCase();
      return handle_book_on_order_radio(value);
    });
    handle_book_on_order_radio($('input[name=book_on_order]:checked').val());
    $hoursPerDay = parseFloat($('[data-hours-per-day]').data('hoursPerDay'));
    activeSource = null;
    updateOfferedValues = function() {
      var days, hours, newDays, newHours, rate, source, total;
      source = $(this).attr('id');
      hours = parseFloat($('#accounting_post_offered_hours').val());
      days = parseFloat($('#accounting_post_offered_days').val());
      rate = parseFloat($('#accounting_post_offered_rate').val());
      total = parseFloat($('#accounting_post_offered_total').val());
      newHours = newDays = null;
      if (!isNaN(rate) && rate > 0 && (source.endsWith('_total') || source.endsWith('_rate') && activeSource.endsWith('_total'))) {
        newHours = total / rate;
        newDays = newHours / $hoursPerDay;
      } else if (!isNaN(hours) && hours > 0 && (source.endsWith('_hours') || source.endsWith('_rate') && activeSource.endsWith('_hours'))) {
        newDays = hours / $hoursPerDay;
        $('#accounting_post_offered_total').val(!isNaN(rate) && rate > 0 && hours * rate || '');
      } else if (!isNaN(days) && days > 0 && (source.endsWith('_days') || source.endsWith('_rate') && activeSource.endsWith('_days'))) {
        newHours = days * $hoursPerDay;
        $('#accounting_post_offered_total').val(!isNaN(rate) && rate > 0 && newHours * rate || '');
      }
      if (newHours !== null) {
        $('#accounting_post_offered_hours').val(newHours || '');
      }
      if (newDays !== null) {
        $('#accounting_post_offered_days').val(newDays || '');
      }
      if (!source.endsWith('_rate')) {
        return activeSource = source;
      }
    };
    return $('#accounting_post_offered_hours, ' + '#accounting_post_offered_days, ' + '#accounting_post_offered_rate, ' + '#accounting_post_offered_total').on('keyup change', updateOfferedValues);
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  app.reportsOrders = new ((function() {
    function _Class() {}

    _Class.prototype.init = function() {
      return this.dateFilterChanged();
    };

    _Class.prototype.dateFilterChanged = function() {
      return $('.order_reports form[role="filter"]').find('#start_date,#end_date').datepicker('option', 'disabled', $('#period_shortcut').val());
    };

    return _Class;

  })());

  $(document).on('ajax:success', '.order_reports form[role="filter"]', function() {
    return app.reportsOrders.init();
  });

  $(document).on('turbolinks:load', function() {
    return app.reportsOrders.init();
  });

}).call(this);
(function() {
  $(document).on('turbolinks:load', function() {
    var check_file_type, toggle_project_display;
    if (!($('body.expenses').length || $('body.expenses_reviews').length)) {
      return;
    }
    toggle_project_display = function() {
      var form_group, input, kind, order;
      kind = $('#expense_kind :selected');
      order = $('#expense_order_id');
      form_group = order.closest('.form-group');
      input = form_group.find('input');
      return kind.each(function() {
        if (this.value === 'project') {
          if (order[0].textContent && !input[0].value) {
            input[0].value = ' ';
          }
          form_group.show();
          return input.attr('required', 'required');
        } else {
          form_group.hide();
          return input.removeAttr('required');
        }
      });
    };
    check_file_type = function(initial) {
      var files, input, warning;
      if (initial == null) {
        initial = false;
      }
      input = $('#expense_receipt')[0];
      files = input.files;
      warning = $('#file_warning');
      warning.addClass('hidden');
      if (!(files.length > 0)) {
        return;
      }
      if (/^image/.test(files[0].type)) {
        return;
      }
      if (!initial) {
        warning.removeClass('hidden');
      }
      return input.value = '';
    };
    check_file_type(true);
    toggle_project_display();
    $('#expense_kind').change(function(e) {
      return toggle_project_display();
    });
    return $('#expense_receipt').change(function(e) {
      return check_file_type();
    });
  });

}).call(this);
(function() {
  $(document).on('turbolinks:load', function() {
    var approve_button, reason, reimbursement, reject_button, toggle_approve_button, toggle_reject_button;
    reimbursement = $('#expense_reimbursement_date');
    reason = $('#expense_reason');
    approve_button = $('#approve_btn');
    reject_button = $('#reject_btn');
    toggle_approve_button = function() {
      var switch_to;
      switch_to = reimbursement.val() === '';
      return approve_button.prop('disabled', switch_to);
    };
    toggle_reject_button = function() {
      var switch_to;
      switch_to = reason.val() === '' || reimbursement.val() !== '';
      return reject_button.prop('disabled', switch_to);
    };
    toggle_approve_button();
    toggle_reject_button();
    reimbursement.change(function(e) {
      toggle_approve_button();
      return toggle_reject_button();
    });
    reason.change(function(e) {
      return toggle_reject_button();
    });
    return reason.keyup(function(e) {
      return toggle_reject_button();
    });
  });

}).call(this);
(function() {
  var app;

  app = window.App || (window.App = {});

  $(document).on('turbolinks:load', function() {
    var dateFilterChanged;
    dateFilterChanged = function() {
      return $('#meal_compensations_filter_form').find('#start_date,#end_date').closest('.form-group').css('visibility', !$('#period_shortcut').val() ? 'visible' : 'hidden');
    };
    $('#period_shortcut').on('change', function(event) {
      return dateFilterChanged();
    });
    return dateFilterChanged();
  });

}).call(this);
