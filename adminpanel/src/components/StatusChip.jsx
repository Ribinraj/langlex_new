import { Chip } from '@mui/material'

const colorMap = {
  active: 'success',
  paid: 'success',
  completed: 'success',
  free: 'default',
  created: 'info',
  in_progress: 'warning',
  failed: 'error',
  expired: 'default',
  cancelled: 'default',
  premium: 'secondary',
  paid_plan: 'secondary',
}

export default function StatusChip({ value, size = 'small' }) {
  const text = String(value || 'unknown')
  return (
    <Chip
      size={size}
      label={text.replace(/_/g, ' ')}
      color={colorMap[text.toLowerCase()] || 'default'}
      variant={colorMap[text.toLowerCase()] ? 'filled' : 'outlined'}
      sx={{ fontWeight: 700, textTransform: 'capitalize' }}
    />
  )
}
