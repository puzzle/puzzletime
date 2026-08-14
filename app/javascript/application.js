//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.

// Import order mirrors the old Sprockets manifest; import order is execution
// order. ./jquery_global must stay first and turbolinks last.

// -- vendor ------------------------------------------------------------------
import "./jquery_global";
import "jquery-ujs";
// jquery-ui declares its dependencies only in its AMD branch, so esbuild needs
// this chain listed explicitly and in order. A new widget needs its deps added.
import "jquery-ui/ui/version";
import "jquery-ui/ui/keycode";
import "jquery-ui/ui/position";
import "jquery-ui/ui/unique-id";
import "jquery-ui/ui/widget";
import "jquery-ui/ui/widgets/mouse";
import "jquery-ui/ui/widgets/menu";
import "jquery-ui/ui/widgets/datepicker";
import "./vendor/jquery-ui-datepicker-i18n";
import "jquery-ui/ui/widgets/autocomplete";
import "jquery-ui/ui/widgets/selectable";
import "selectize";
// Missing from the Sprockets manifest; the other plugins need it to sequence.
import "bootstrap/js/transition";
import "bootstrap/js/modal";
import "bootstrap/js/tooltip";
import "bootstrap/js/button";
import "bootstrap/js/alert";
import "waypoints/lib/jquery.waypoints";
import "waypoints/lib/shortcuts/sticky";
import "waypoints/lib/shortcuts/inview";
import "./modernizr";
import "./globals";

// -- was `//= require_self` --------------------------------------------------
import "./boot";

// -- was `//= require_tree ./modules` (alphabetical, as Sprockets walked it) --
import "./modules/autocomplete";
import "./modules/checkbox/all_checker";
import "./modules/checkbox/element_hider";
import "./modules/checkbox/input_enabler";
import "./modules/checkbox/toggler";
import "./modules/clear_input";
import "./modules/dynamic_params";
import "./modules/form_updater";
import "./modules/linked_table_row";
import "./modules/order_autocomplete";
import "./modules/selection_watcher";
import "./modules/selectize_refresher";
import "./modules/spinner";
import "./modules/work_item_autocomplete";

// -- feature files -----------------------------------------------------------
import "./vendor/nested_form_fields";
import "./modal_create";
import "./datepicker";
import "./header";
import "./worktimes";
import "./plannings";
import "./plannings_panel";
import "./plannings_selectable";
import "./plannings_service";
import "./orders";
import "./order_contacts";
import "./order_controlling";
import "./order_services";
import "./accounting_posts";
import "./reports_orders";
import "./reports_invoices";
import "./reports_billing";
import "./expenses";
import "./expense_reviews";
import "./meal_compensations";
import "./invoices";
import "./cockpit";

// Bundled, turbolinks takes its CommonJS branch and never self-starts.
import Turbolinks from "turbolinks";

window.Turbolinks = Turbolinks;
Turbolinks.start();
