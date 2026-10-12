import EmptyState from '../components/EmptyState'
import { Button, Stack } from '@mui/material'
import { Link as RouterLink } from 'react-router-dom'

export default function NotFoundPage() {
  return (
    <Stack
      spacing={2}
      sx={{
        minHeight: '100vh',
        px: 2,
        textAlign: 'center',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <EmptyState
        title="This page wandered off"
        description="The page may have moved, or the address may be incorrect."
      />
      <Button component={RouterLink} to="/" variant="contained">
        Go to dashboard
      </Button>
    </Stack>
  )
}
