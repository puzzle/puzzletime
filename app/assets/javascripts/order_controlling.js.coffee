#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}


app.initOrderControllingChart = (labels, datasets, budget, currency, currentLabel) ->
  canvas = document.getElementById('order_controlling_chart')
  ctx = canvas.getContext('2d')

  Chart.defaults.font.family = 'Roboto, Helvetica, Arial, sans-serif'
  Chart.defaults.color = '#444444'
  Chart.defaults.font.size = 14

  budgetColor = '#B44B5B'
  todayColor = '#f0ad4e'
  gridColor = 'rgba(0,0,0,0.1)'
  gridLightColor = 'rgba(0,0,0,0.02)'

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
        x: {
          stacked: true,
          gridLines: {
            color: gridColor
          }
        },
        y: {
          stacked: true,
          ticks: {
            beginAtZero: true,
            callback: formatCurrency
          },
          gridLines: {
            color: gridLightColor,
            zeroLineColor: gridColor
          },
        },
      },
      legend: {
        labels: {
          boxWidth: Chart.defaults.font.size
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
          mode: 'vertical',
          scaleID: 'x-axis-0',
          value: currentLabel,
          borderColor: todayColor,
          borderWidth: 2,
          label: {
            enabled: true,
            content: 'heute',
            position: 'top'
            yAdjust: 10,
            xPadding: 2,
            yPadding: 3,
            backgroundColor: '#ffffff'
            fontFamily: Chart.defaults.font.family,
            fontSize: Chart.defaults.font.size,
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
            fontFamily: Chart.defaults.font.family,
            fontSize: Chart.defaults.font.size,
            fontStyle: 'normal',
            fontColor: budgetColor
          }
        }]
      }
    },
  })
