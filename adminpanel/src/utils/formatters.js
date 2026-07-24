import { format, formatDistanceToNowStrict, isValid, parseISO } from 'date-fns'

export function formatDate(value, pattern = 'dd MMM yyyy') {
  if (!value) return '-'
  const date = typeof value === 'string' ? parseISO(value) : new Date(value)
  return isValid(date) ? format(date, pattern) : '-'
}

export function formatDateTime(value) {
  return formatDate(value, 'dd MMM yyyy, HH:mm')
}

export function timeAgo(value) {
  if (!value) return '-'
  const date = typeof value === 'string' ? parseISO(value) : new Date(value)
  return isValid(date) ? `${formatDistanceToNowStrict(date)} ago` : '-'
}

export function currency(value) {
  const amount = Number(value || 0)
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(amount)
}

export function number(value) {
  return new Intl.NumberFormat('en-IN').format(Number(value || 0))
}

export function percent(value) {
  return `${Math.round(Number(value || 0))}%`
}
