#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}


app.initOrderControllingChart = (labels, datasets, budget, currency) ->
  canvas = document.getElementById('order_controlling_chart')
  ctx = canvas.getContext('2d')

  Chart.defaults.global.defaultFontFamily = 'Roboto, Helvetica, Arial, sans-serif'
  Chart.defaults.global.defaultFontColor = '#444444'
  Chart.defaults.global.defaultFontSize = 14

  formatCurrency = (value) -> Number(value).toLocaleString() + ' ' + currency

  chart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: datasets
    },
    options: {
      responsive: false,
      scales: {
        xAxes: [{
          stacked: true,
          gridLines: {
            color: '#ddd'
          }
        }],
        yAxes: [{
          stacked: true,
          ticks: {
            beginAtZero: true,
            callback: formatCurrency
          },
          gridLines: {
            color: '#f3f3f3',
            zeroLineColor: '#ddd'
          },
        }],
      },
      legend: {
        labels: {
          boxWidth: Chart.defaults.global.defaultFontSize
        }
      },
      tooltips: {
        callbacks: {
          label: (item, data) ->
            data.datasets[item.datasetIndex].label + ': ' + formatCurrency(item.yLabel)
        }
      }
      annotation: {
        annotations: [{
          type: 'line',
          mode: 'horizontal',
          scaleID: 'y-axis-0',
          value: budget,
          borderColor: '#B44B5B',
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
            fontColor: '#B44B5B'
          }
        }]
      }
    },
  })
