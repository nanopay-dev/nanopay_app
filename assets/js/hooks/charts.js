import ApexCharts from 'apexcharts'

const balanceSeries = [{
  x: new Date('2022-01-16').getTime(),
  y: 4.80
}, {
  x: new Date('2022-01-17').getTime(),
  y: 4.36
}, {
  x: new Date('2022-01-18').getTime(),
  y: 14.36
}, {
  x: new Date('2022-01-19').getTime(),
  y: 14.11
}, {
  x: new Date('2022-01-20').getTime(),
  y: 14.11
}, {
  x: new Date('2022-01-21').getTime(),
  y: 14.01
}, {
  x: new Date('2022-01-22').getTime(),
  y: 12.06
}, {
  x: new Date('2022-01-23').getTime(),
  y: 11.01
}, {
  x: new Date('2022-01-24').getTime(),
  y: 9.23
}, {
  x: new Date('2022-01-25').getTime(),
  y: 5.23
}, {
  x: new Date('2022-01-26').getTime(),
  y: 5.01
}, {
  x: new Date('2022-01-27').getTime(),
  y: 4.46
}, {
  x: new Date('2022-01-28').getTime(),
  y: 3.78
}, {
  x: new Date('2022-01-29').getTime(),
  y: 3.26
}, {
  x: new Date('2022-01-30').getTime(),
  y: 13.26
}]

const spendSeries = balanceSeries.map((el, i, array) => {
  const prev = array[i-1]
  const spend = Math.max((prev ? prev.y : 0) - el.y, 0)
  return {x: el.x, y: spend}
})

var formatter = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',

  // These options are needed to round to whole numbers if that's what you want.
  //minimumFractionDigits: 0, // (this suffices for whole numbers, but will print 2500.10 as $2,500.1)
  //maximumFractionDigits: 0, // (causes 2500.99 to be printed as $2,501)
});

export const BalanceChart = {
  mounted() {
    this._chart = new ApexCharts(this.el, {
      chart: {
        type: 'area',
        height: 380,
        toolbar: { show: false },
        zoom: { enabled: false }
      },
      colors: ['#f43f5e', '#10b981',],
      fill: {
        type: ['solid', 'gradient']
      },
      dataLabels: {
        enabled: true,
        enabledOnSeries: [0],
        formatter(val) {
          if (val > 0) {
            return formatter.format(val)
          }
        },
        style: {
          colors: ['#d1d5db'],
          fontFamily: '"Inter var", sans-serif',
          fontSize: '11px',
          fontWeight: 400
        },
        background: { enabled: false },
        offsetY: -10
      },
      grid: {
        borderColor: '#374151',
        xaxis: {
          lines: { show: false }
        },
        yaxis: {
          lines: { show: true }
        }
      },
      legend: {
        fontFamily: '"Inter var", sans-serif',
        fontSize: '13px',
        fontWeight: 400,
        labels: { colors: '#d1d5db' },
        itemMargin: { vertical: 10 },
        onItemClick: { toggleDataSeries: false },
      },
      states: {
        hover: {
          filter: { type: 'none' }
        },
        active: {
          filter: { type: 'none' }
        },
      },
      stroke: {
        curve: 'smooth',
        width: [0, 4]
      },
      tooltip: {
        enabled: false,
        theme: 'dark'
      },
      series: [{
        name: 'Daily spend',
        type: 'column',
        data: spendSeries
      }, {
        name: 'Wallet balance',
        type: 'area',
        data: balanceSeries
      }],
      xaxis: {
        type: 'datetime',
        axisBorder: { show: false },
        axisTicks: { color: '#374151' },
        labels: {
          style: {
            colors: '#9ca3af',
            fontFamily: '"Inter var", sans-serif',
            fontSize: '11px',
          }
        }
      },
      yaxis: [{
        show: false,
        opposite: true,
        max: Math.max(...spendSeries.map(e => e.y)) * 1.66
      }, {
        show: true,
        floating: true,
        labels: {
          align: 'left',
          offsetX: 50,
          formatter(val) {
            return formatter.format(val)
          },
          style: {
            colors: '#9ca3af',
            fontFamily: '"Inter var", sans-serif',
            fontSize: '11px',
          }
        }
      }]
    })

    this._chart.render()
  },

  destroyed() {
    this._chart.destroy()
  }
}