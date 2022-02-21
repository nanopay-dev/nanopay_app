import axios from 'axios'

export const appApi = axios.create({
  baseURL: '/app'
})

const meta = document.querySelector('meta[name="csrf-token"]')
if (meta) {
  appApi.defaults.headers.common['X-CSRF-TOKEN'] = meta.getAttribute('content')
}

