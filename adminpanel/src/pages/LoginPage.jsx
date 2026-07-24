import { zodResolver } from '@hookform/resolvers/zod'
import { LockRounded, MailRounded } from '@mui/icons-material'
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  InputAdornment,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useEffect } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { useDispatch, useSelector } from 'react-redux'
import { Navigate, useNavigate } from 'react-router-dom'
import { z } from 'zod'
import { loginAdmin } from '../features/auth/authSlice'

const logoUrl = `${import.meta.env.BASE_URL}brand/logo_new.png`

const schema = z.object({
  email: z.string().email('Enter a valid admin email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

export default function LoginPage() {
  const dispatch = useDispatch()
  const navigate = useNavigate()
  const { token, status, error } = useSelector((state) => state.auth)
  const mode = useSelector((state) => state.ui.mode)
  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
    defaultValues: {
      email: 'crisanttechnologies@gmail.com',
      password: '',
    },
  })

  useEffect(() => {
    if (token) navigate('/', { replace: true })
  }, [navigate, token])

  if (token) return <Navigate to="/" replace />

  const submit = async (values) => {
    const result = await dispatch(loginAdmin(values))
    if (loginAdmin.fulfilled.match(result)) {
      navigate('/', { replace: true })
    }
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'grid',
        placeItems: 'center',
        bgcolor: 'background.default',
        px: 2,
      }}
    >
      <Card sx={{ width: '100%', maxWidth: 460 }}>
        <CardContent sx={{ p: { xs: 3, sm: 4 } }}>
          <Stack spacing={3}>
            <Stack spacing={1.5} sx={{ alignItems: 'center', textAlign: 'center' }}>
              <Box
                component="img"
                src={logoUrl}
                alt="LangLex"
                sx={{
                  width: 68,
                  height: 68,
                  objectFit: 'contain',
                  bgcolor: '#FFFFFF',
                  border: 1,
                  borderColor: mode === 'dark' ? 'rgba(255,255,255,0.18)' : 'divider',
                  borderRadius: 2,
                  p: 0.5,
                  boxShadow: mode === 'dark' ? '0 10px 24px rgba(0,0,0,0.32)' : 'none',
                }}
              />
              <Box>
                <Typography variant="h4" sx={{ fontSize: 28 }}>
                  LangLex Admin
                </Typography>
                <Typography color="text.secondary">
                  Secure administrator access for content and operations.
                </Typography>
              </Box>
            </Stack>

            {error ? <Alert severity="error">{error}</Alert> : null}

            <Stack component="form" spacing={2} onSubmit={handleSubmit(submit)}>
              <Controller
                name="email"
                control={control}
                render={({ field }) => (
                  <TextField
                    label="Email"
                    autoComplete="email"
                    error={Boolean(errors.email)}
                    helperText={errors.email?.message}
                    slotProps={{
                      input: {
                        startAdornment: (
                          <InputAdornment position="start">
                            <MailRounded fontSize="small" />
                          </InputAdornment>
                        ),
                      },
                    }}
                    {...field}
                  />
                )}
              />
              <Controller
                name="password"
                control={control}
                render={({ field }) => (
                  <TextField
                    label="Password"
                    type="password"
                    autoComplete="current-password"
                    error={Boolean(errors.password)}
                    helperText={errors.password?.message}
                    slotProps={{
                      input: {
                        startAdornment: (
                          <InputAdornment position="start">
                            <LockRounded fontSize="small" />
                          </InputAdornment>
                        ),
                      },
                    }}
                    {...field}
                  />
                )}
              />
              <Button type="submit" variant="contained" size="large" disabled={status === 'loading'}>
                {status === 'loading' ? 'Signing in...' : 'Sign in'}
              </Button>
            </Stack>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  )
}
