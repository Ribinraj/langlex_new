import {
  SearchOffRounded,
  CloudOffRounded,
  RefreshRounded,
} from '@mui/icons-material'
import { Box, Button, Stack, Typography } from '@mui/material'
export default function EmptyState({
  title = 'No results found',
  description = 'Try a different search or adjust your filters.',
  error,
  onRetry,
}) {
  const Icon = error ? CloudOffRounded : SearchOffRounded
  return (
    <Stack
      role={error ? 'alert' : 'status'}
      spacing={1.5}
      sx={{ alignItems: 'center', py: 6, px: 3, textAlign: 'center' }}
    >
      <Box
        sx={{
          position: 'relative',
          width: 80,
          height: 80,
          display: 'grid',
          placeItems: 'center',
          borderRadius: '24px',
          bgcolor: 'action.selected',
          color: 'primary.main',
          mb: 1,
          '&::after': {
            content: '""',
            position: 'absolute',
            width: 14,
            height: 14,
            border: '3px solid',
            borderColor: 'background.paper',
            bgcolor: 'secondary.main',
            borderRadius: '50%',
            top: -4,
            right: -4,
          },
        }}
      >
        <Icon sx={{ fontSize: 38 }} />
      </Box>
      <Typography variant="h6">
        {error ? 'Unable to load this page' : title}
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 350 }}>
        {error || description}
      </Typography>
      {onRetry && (
        <Button
          startIcon={<RefreshRounded />}
          onClick={onRetry}
          variant="outlined"
        >
          Try again
        </Button>
      )}
    </Stack>
  )
}
