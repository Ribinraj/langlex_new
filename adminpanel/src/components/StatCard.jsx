import { Avatar, Box, Card, CardContent, Stack, Typography } from '@mui/material'

export default function StatCard({
  title,
  value,
  helper,
  icon,
  color = '#8E5CE6',
  iconBg,
  sparkline = [],
}) {
  return (
    <Card
      sx={{
        height: '100%',
        borderColor: 'rgba(129, 113, 168, 0.16)',
        boxShadow: '0 18px 46px rgba(43, 34, 86, 0.08)',
        overflow: 'hidden',
      }}
    >
      <CardContent sx={{ p: 2.2 }}>
        <Stack
          direction="row"
          spacing={2}
          sx={{ alignItems: 'flex-start', justifyContent: 'space-between' }}
        >
          <Avatar
            sx={{
              bgcolor: iconBg || `${color}1A`,
              color,
              width: 48,
              height: 48,
              borderRadius: 3,
            }}
          >
            {icon}
          </Avatar>
          <Stack spacing={0.8} sx={{ minWidth: 0, flex: 1 }}>
            <Typography variant="body2" color="text.primary" fontWeight={700} noWrap>
              {title}
            </Typography>
            <Typography variant="h4" sx={{ fontSize: { xs: 24, md: 29 }, lineHeight: 1.05 }}>
              {value}
            </Typography>
            {helper ? (
              <Typography variant="caption" color="text.secondary">
                {helper}
              </Typography>
            ) : null}
          </Stack>
        </Stack>
        <Stack direction="row" sx={{ justifyContent: 'flex-end', mt: 2 }}>
          <MiniSparkline color={color} values={sparkline} />
        </Stack>
      </CardContent>
    </Card>
  )
}

function MiniSparkline({ color, values }) {
  const safeValues = values.length > 1 ? values.map(Number) : [0, 0]
  const max = Math.max(...safeValues)
  const min = Math.min(...safeValues)
  const points = safeValues
    .map((value, index) => {
      const x = (index / (safeValues.length - 1)) * 130
      const y = 40 - ((value - min) / Math.max(max - min, 1)) * 32
      return `${x},${y}`
    })
    .join(' ')

  return (
    <Box
      component="svg"
      viewBox="0 0 130 44"
      aria-hidden="true"
      sx={{ width: 136, height: 46, flexShrink: 0 }}
    >
      <polyline
        points={points}
        fill="none"
        stroke={color}
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Box>
  )
}
