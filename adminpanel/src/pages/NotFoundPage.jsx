import { Button, Stack, Typography } from '@mui/material'
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
      <Typography variant="h3">Page not found</Typography>
      <Typography color="text.secondary">
        The admin route you requested does not exist.
      </Typography>
      <Button component={RouterLink} to="/" variant="contained">
        Go to dashboard
      </Button>
    </Stack>
  )
}
