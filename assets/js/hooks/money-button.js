import Alpine from 'alpinejs'

/**
 * TODO
 */
export const MoneyButton = {
  async mounted() {
    const mb = await Alpine.store('libs').get('moneybutton')

    mb.render(this.el, {
      to: 'libs@moneybutton.com',
      amount: 0.00100000,
      currency: 'BSV',
      label: 'Send payment'
    })
  }
}