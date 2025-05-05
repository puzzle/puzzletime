#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}


app.initOrderControllingChart = (labels, datasets, budget, budget_hours, currency, currentLabel) ->
  canvas = document.getElementById('order_controlling_chart')
  ctx = canvas.getContext('2d')

  Chart.defaults.font.family = 'Roboto, Helvetica, Arial, sans-serif'
  Chart.defaults.color = '#444444'
  Chart.defaults.font.size = 14

  budgetColor = '#B44B5B'
  todayColor = '#f0ad4e'
  gridColor = 'rgba(0,0,0,0.1)'
  gridLightColor = 'rgba(0,0,0,0.02)'

  formatCurrency = (value) ->
    new Intl.NumberFormat('de-CH', {
      style: 'decimal'
    }).format(value) + ' ' + currency

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
      plugins: {
        tooltip: {
          callbacks: {
            label: (tooltipItem) ->
              hours = tooltipItem.dataset.tooltipData[tooltipItem.dataIndex];
              datasetLabel = tooltipItem.dataset.label
              value = formatCurrency(tooltipItem.raw)
              [
                "#{datasetLabel}:"
                "#{value} (#{hours}h)"
              ]
            }
        },
        annotation: {
          annotations: [{
            type: 'line',
            scaleID: 'x',
            value: currentLabel,
            borderColor: todayColor,
            borderWidth: 2,
            label: {
              display: true,
              content: 'heute',
              position: 'start',
              yAdjust: 10,
              padding: {x: 2, y: 3},
              backgroundColor: '#ffffff',
              color: todayColor,
              font: {
                family: Chart.defaults.font.family,
                size: Chart.defaults.font.size,
                style: 'normal',
              }
            }
          }, {
            type: 'line',
            scaleID: 'y',
            value: budget,
            borderColor: budgetColor,
            borderWidth: 2,
            label: {
              display: true,
              content: 'Budget ' + formatCurrency(budget) + " (#{budget_hours}h)",
              position: 'start',
              yAdjust: 11,
              backgroundColor: 'transparent',
              color: budgetColor,
              font: {
                family: Chart.defaults.font.family,
                size: Chart.defaults.font.size,
                style: 'normal',
              }
            }
          }]
        }
      }
    },
  })
