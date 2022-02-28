import Alpine from 'alpinejs'

/**
 * TODO
 */
export const RelayOne = {
  async mounted() {
    const rx = await Alpine.store('libs').get('relayone')

    rx.render(this.el, {
      to: 'libs@moneybutton.com',
      amount: 0.00100000,
      currency: 'BSV',
      label: 'Send payment'
    })
  }
}