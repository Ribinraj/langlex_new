import { ApiRounded, PaletteRounded, ShieldRounded } from '@mui/icons-material'
import { Card, CardContent, Grid, Stack, Typography } from '@mui/material'
import PageHeader from '../components/PageHeader'

export default function SettingsPage() {
  const apiBase = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:5050/api'

  return (
    <>
      <PageHeader
        title="Settings"
        subtitle="Environment and administrator workspace configuration."
      />
      <Grid container spacing={2.2}>
        <Grid size={{ xs: 12, md: 4 }}>
          <SettingCard
            icon={<ApiRounded />}
            title="API Base URL"
            value={apiBase}
            helper="Configured with VITE_API_BASE_URL."
          />
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <SettingCard
            icon={<ShieldRounded />}
            title="Authentication"
            value="Admin JWT"
            helper="Separate /api/admin namespace, independent from student OTP auth."
          />
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <SettingCard
            icon={<PaletteRounded />}
            title="Brand System"
            value="LangLex purple and green"
            helper="Business-oriented dashboard theme with light/dark mode."
          />
        </Grid>
      </Grid>
    </>
  )
}

function SettingCard({ icon, title, value, helper }) {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Stack spacing={1.3}>
          {icon}
          <Typography variant="h6">{title}</Typography>
          <Typography fontWeight={700} sx={{ wordBreak: 'break-word' }}>
            {value}
          </Typography>
          <Typography color="text.secondary">{helper}</Typography>
        </Stack>
      </CardContent>
    </Card>
  )
}
