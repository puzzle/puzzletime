#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}


app.initOrderControllingChart = (labels, datasets, budget, currency, currentLabel) ->
  canvas = document.getElementById('order_controlling_chart')
  ctx = canvas.getContext('2d')

  Chart.defaults.global.defaultFontFamily = 'Roboto, Helvetica, Arial, sans-serif'
  Chart.defaults.global.defaultFontColor = '#444444'
  Chart.defaults.global.defaultFontSize = 14

  budgetColor = '#B44B5B'
  gridColor = 'rgba(0,0,0,0.1)'
  gridLightColor = 'rgba(0,0,0,0.02)'
  gridCurrentColor = '#444444'

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
            color: labels.map((l) -> (if l == currentLabel then gridCurrentColor else gridColor))
          }
        }],
        yAxes: [{
          stacked: true,
          ticks: {
            beginAtZero: true,
            callback: formatCurrency
          },
          gridLines: {
            color: gridLightColor,
            zeroLineColor: gridColor
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
        }]
      }
    },
  })
