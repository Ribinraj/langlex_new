import { Box, Button, Stack, Typography } from '@mui/material'

export default function PageHeader({ title, subtitle, action, actionIcon }) {
  return (
    <Stack
      direction={{ xs: 'column', sm: 'row' }}
      spacing={2}
      sx={{
        mb: 3,
        alignItems: { xs: 'flex-start', sm: 'center' },
        justifyContent: 'space-between',
      }}
    >
      <Box>
        <Typography variant="h4" sx={{ fontSize: { xs: 24, md: 30 }, mb: 0.5 }}>
          {title}
        </Typography>
        {subtitle ? (
          <Typography color="text.secondary" sx={{ maxWidth: 760 }}>
            {subtitle}
          </Typography>
        ) : null}
      </Box>
      {action ? (
        <Button variant="contained" startIcon={actionIcon} onClick={action.onClick}>
          {action.label}
        </Button>
      ) : null}
    </Stack>
  )
}
