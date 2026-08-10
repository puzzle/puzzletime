//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.

// Bare-name globals for our own files and the server-rendered .js.haml responses.
import Selectize from "selectize";
import Chart from "chart.js/auto";
import annotationPlugin from "chartjs-plugin-annotation";

window.Selectize = Selectize;

Chart.register(annotationPlugin);
window.Chart = Chart;
