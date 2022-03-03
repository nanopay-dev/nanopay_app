import Alpine from 'alpinejs'

Alpine.data('PayRequest', () => {
  return {
    init() {
      this.$el.addEventListener('phx.hooked', () => {
        this.$el.$hook.handleEvent('funded', (data) => {
          this.$store.iframe.postMessage('pr.funded', data)
        })
      })
    }
  }
})