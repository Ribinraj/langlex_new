import {
  PaletteRounded,
  ShieldRounded,
  CloudDoneRounded,
} from '@mui/icons-material'
import {
  Alert,
  Button,
  Card,
  CardContent,
  FormControlLabel,
  Grid,
  Stack,
  Switch,
  Typography,
} from '@mui/material'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useDispatch, useSelector } from 'react-redux'
import PageHeader from '../components/PageHeader'
import { toggleMode } from '../features/auth/uiSlice'
import { apiClient } from '../services/apiClient'
export default function SettingsPage() {
  const dispatch = useDispatch(),
    mode = useSelector((state) => state.ui.mode),
    admin = useSelector((state) => state.auth.admin)
  const [connection, setConnection] = useState(''),
    [checking, setChecking] = useState(false)
  const check = async () => {
    setChecking(true)
    setConnection('')
    try {
      await apiClient.get('/admin/auth/me', { silent: true })
      setConnection('connected')
    } catch {
      setConnection('failed')
    } finally {
      setChecking(false)
    }
  }
  return (
    <>
      <PageHeader
        title="Settings"
        subtitle="Personalize your workspace and review your administrator account."
      />
      <Button component={Link} to="/resources/plans" variant="outlined" sx={{mb:3}}>Manage subscription plans</Button>
      <Grid container spacing={2.5}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Stack spacing={2}>
                <PaletteRounded color="primary" />
                <Typography variant="h6">Appearance</Typography>
                <Typography variant="body2" color="text.secondary">
                  Choose a comfortable workspace. Your preference is saved on
                  this browser.
                </Typography>
                <FormControlLabel
                  control={
                    <Switch
                      checked={mode === 'dark'}
                      onChange={() => dispatch(toggleMode())}
                    />
                  }
                  label="Dark mode"
                />
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Stack spacing={2}>
                <ShieldRounded color="primary" />
                <Typography variant="h6">Administrator account</Typography>
                <Typography fontWeight={600}>
                  {admin?.full_name || 'Administrator'}
                </Typography>
                <Typography
                  variant="body2"
                  color="text.secondary"
                  sx={{ overflowWrap: 'anywhere' }}
                >
                  {admin?.email}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Role: {admin?.role || 'Administrator'}
                </Typography>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12 }}>
          <Card>
            <CardContent>
              <Stack spacing={2} sx={{ alignItems: 'flex-start' }}>
                <CloudDoneRounded color="primary" />
                <Typography variant="h6">Service connection</Typography>
                <Typography variant="body2" color="text.secondary">
                  Check that this workspace can reach the service with your
                  current session.
                </Typography>
                <Typography
                  variant="caption"
                  sx={{ overflowWrap: 'anywhere', maxWidth: '100%' }}
                >
                  {apiClient.defaults.baseURL}
                </Typography>
                {connection && (
                  <Alert
                    severity={connection === 'connected' ? 'success' : 'error'}
                  >
                    {connection === 'connected'
                      ? 'Connected. Your administrator session is valid.'
                      : 'Connection failed. Please check the service and try again.'}
                  </Alert>
                )}
                <Button variant="outlined" disabled={checking} onClick={check}>
                  {checking ? 'Checking…' : 'Check connection'}
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </>
  )
}
