//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});


app.initOrderControllingChart = function(labels, datasets, budget, budget_hours, currency, currentLabel) {
  let chart;
  const canvas = document.getElementById('order_controlling_chart');
  const ctx = canvas.getContext('2d');

  Chart.defaults.font.family = 'Roboto, Helvetica, Arial, sans-serif';
  Chart.defaults.color = '#444444';
  Chart.defaults.font.size = 14;

  const budgetColor = '#B44B5B';
  const todayColor = '#f0ad4e';
  const gridColor = 'rgba(0,0,0,0.1)';
  const gridLightColor = 'rgba(0,0,0,0.02)';

  const formatCurrency = value => new Intl.NumberFormat('de-CH', {
    style: 'decimal'
  }).format(value) + ' ' + currency;

  return chart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets
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
            label(tooltipItem) {
              const hours = tooltipItem.dataset.tooltipData[tooltipItem.dataIndex];
              const datasetLabel = tooltipItem.dataset.label;
              const value = formatCurrency(tooltipItem.raw);
              return [
                `${datasetLabel}:`,
                `${value} (${hours}h)`
              ];
            }
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
              content: 'Budget ' + formatCurrency(budget) + ` (${budget_hours}h)`,
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
  });
};
