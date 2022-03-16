import ApexCharts from 'apexcharts'

var formatter = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',
  minimumFractionDigits: 4,
  maximumFractionDigits: 4
});

export const PaymentChart = {
  mounted() {
    const stats = JSON.parse(this.el.dataset.stats)

    const spendSeries = stats.map(s => {
      const x = new Date(s.date).getTime()
      const y = stats.some(s => Number(s.amount) > 0) ? Number(s.amount) : undefined;
      return { x, y }
    })

    const paymentsSeries = stats.map(s => {
      const x = new Date(s.date).getTime()
      const y = stats.some(s => Number(s.payments) > 0) ? Number(s.payments) : undefined;
      return { x, y }
    })
    
    this._chart = new ApexCharts(this.el, {
      chart: {
        type: 'area',
        height: 380,
        toolbar: { show: false },
        zoom: { enabled: false }
      },
      colors: ['#10b981', '#f43f5e'],
      fill: {
        type: ['gradient', 'solid']
      },
      dataLabels: {
        enabled: true,
        enabledOnSeries: [1],
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
        padding: {
          left: 30
        },
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
        width: [4, 0]
      },
      tooltip: {
        enabled: false,
        theme: 'dark'
      },
      series: [{
        name: 'Daily payments',
        type: 'area',
        data: paymentsSeries
      }, {
        name: 'Daily spend',
        type: 'column',
        data: spendSeries
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
        show: true,
        name: 'Daily payments',
        forceNiceScale: true,
        decimalsInFloat: 0,
        floating: true,
        labels: {
          align: 'left',
          formatter(val) {
            return val >= 1 ? val : 0;
          },
          offsetX: 30,
          style: {
            colors: '#9ca3af',
            fontFamily: '"Inter var", sans-serif',
            fontSize: '11px',
          }
        },
        title: {
          text: 'Daily payments',
          //offsetX: -20,
          style: {
            color: '#9ca3af',
            fontFamily: '"Inter var", sans-serif',
            fontSize: '11px',
            fontWeight: 400
          }
        }
      },{
        show: false,
        name: 'Daily spend',
        opposite: true,
        max: Math.max(...spendSeries.map(e => e.y)) * 1.66
      },]
    })

    this._chart.render()
  },

  destroyed() {
    this._chart.destroy()
  }
}