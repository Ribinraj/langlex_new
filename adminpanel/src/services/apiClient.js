import axios from 'axios'
import toast from 'react-hot-toast'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') || 'http://127.0.0.1:5050/api'

export const mediaBaseUrl = API_BASE_URL.replace(/\/api$/, '')

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 20000,
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  },
})

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('langlex_admin_token')
  if (token) {
    config.headers.Authorization = token.toLowerCase().startsWith('bearer ')
      ? token
      : `Bearer ${token}`
  }
  return config
})

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status
    const message = error.response?.data?.message || error.message || 'Request failed'

    if (status === 401) {
      localStorage.removeItem('langlex_admin_token')
      localStorage.removeItem('langlex_admin_user')
    }

    if (!error.config?.silent) {
      toast.error(message)
    }

    return Promise.reject(error)
  },
)

export function mediaUrl(path) {
  const value = String(path || '').trim()
  if (!value) return ''
  if (value.startsWith('http://') || value.startsWith('https://')) return value
  return `${mediaBaseUrl}/${value.replace(/^\//, '')}`
}
