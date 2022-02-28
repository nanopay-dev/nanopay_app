import Alpine from 'alpinejs'

const cacheTs = '1637152000'

const libs = {
  moneybutton: {
    src: `https://www.moneybutton.com/moneybutton.js?${cacheTs}`,
    global: 'moneyButton'
  },
  relayone: {
    src: `https://one.relayx.io/relayone.js?${cacheTs}`,
    global: 'relayone'
  }
}

async function loadLib(lib) {
  return new Promise((resolve, reject) => {
    const el = document.createElement('script')
    el.type = 'text/javascript'
    el.async = true
    el.src = libs[lib].src

    el.addEventListener('load', _ => resolve(window[libs[lib].global]))
    el.addEventListener('error', reject)
    el.addEventListener('abort', reject)
    document.head.appendChild(el)
  })
}

Alpine.store('libs', {
  moneybutton: null,
  relayone: null,

  async get(lib) {
    if (!this[lib]) {
      this[lib] = await loadLib(lib)
    }
    return this[lib]
  }
})