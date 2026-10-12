import {
  format,
  formatDistanceToNowStrict,
  isValid,
  parse,
  parseISO,
} from 'date-fns'

export function formatDate(value, pattern = 'dd MMM yyyy') {
  if (!value) return '-'
  const date = parseDate(value)
  return isValid(date) ? format(date, pattern) : '-'
}

export function formatDateTime(value) {
  return formatDate(value, 'dd MMM yyyy, HH:mm')
}

export function timeAgo(value) {
  if (!value) return '-'
  const date = parseDate(value)
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

function parseDate(value) {
  if (typeof value !== 'string') return new Date(value)
  if (/^\d{2}\/\d{2}\/\d{2} \d{2}:\d{2}$/.test(value))
    return parse(value, 'dd/MM/yy HH:mm', new Date(2026, 0, 1))
  return parseISO(value)
}
