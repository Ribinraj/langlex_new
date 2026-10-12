import { zodResolver } from '@hookform/resolvers/zod'
import {
  ArrowForwardRounded,
  AutoStoriesOutlined,
  AbcRounded,
  LightbulbOutlined,
  ExtensionOutlined,
  LockOutlined,
  MailOutlineRounded,
  VisibilityRounded,
  VisibilityOffRounded,
} from '@mui/icons-material'
import {
  Alert,
  Box,
  Button,
  Card,
  CircularProgress,
  FormLabel,
  InputAdornment,
  IconButton,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useState } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { useDispatch, useSelector } from 'react-redux'
import { Navigate, useNavigate } from 'react-router-dom'
import { z } from 'zod'
import { loginAdmin } from '../features/auth/authSlice'

const logoUrl = `${import.meta.env.BASE_URL}brand/logo_new.png`
const illustrationUrl = `${import.meta.env.BASE_URL}brand/login/learning-adventure.png`
const learningSections = [
  { label: 'Knowledge', icon: LightbulbOutlined, color: '#766124' },
  { label: 'Alphabets', icon: AbcRounded, color: '#7041CB' },
  { label: 'Stories', icon: AutoStoriesOutlined, color: '#35705B' },
  { label: 'Quizzes', icon: ExtensionOutlined, color: '#A64A33' },
]
const schema = z.object({
  email: z.string().email('Enter a valid admin email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

// Match browser autofill to the surrounding field while keeping password managers enabled.
const fieldStyles = (theme) => {
  const dark = theme.palette.mode === 'dark'
  const surface = dark ? '#22232D' : '#FAF9FC'
  return {
    '& .MuiOutlinedInput-root': {
      minHeight: 56,
      borderRadius: '12px',
      backgroundColor: surface,
      transition: 'box-shadow 160ms ease, border-color 160ms ease',
      '& fieldset': { borderColor: dark ? '#4A4758' : '#D9D5E1' },
      '&:hover fieldset': { borderColor: dark ? '#898096' : '#9A8FA9' },
      '&.Mui-focused': {
        boxShadow: `0 0 0 4px ${dark ? '#BC9AFF24' : '#7041CB14'}`,
      },
      '&.Mui-focused fieldset': { borderColor: 'primary.main', borderWidth: 2 },
      '&.Mui-error fieldset': { borderColor: 'error.main' },
      '&.Mui-error.Mui-focused': {
        boxShadow: `0 0 0 4px ${dark ? '#FF9FAD20' : '#BC304B12'}`,
      },
    },
    '& .MuiInputBase-input': {
      py: '16px',
      fontSize: 15,
      '&::placeholder': { color: 'text.secondary', opacity: 0.8 },
      // Keyboard focus is displayed on the complete field, including its icons.
      '&:focus-visible': { outline: 'none' },
      '&:autofill, &:-webkit-autofill': {
        WebkitBoxShadow: `0 0 0 1000px ${surface} inset`,
        WebkitTextFillColor: theme.palette.text.primary,
        caretColor: theme.palette.text.primary,
        borderRadius: 0,
      },
    },
    '& .MuiInputAdornment-root': { color: 'text.secondary' },
    '& .MuiFormHelperText-root': { mx: 0, mt: 0.75 },
  }
}
const labelStyles = { fontSize: 13, fontWeight: 600, color: 'text.primary' }

export default function LoginPage() {
  const [showPassword, setShowPassword] = useState(false)
  const dispatch = useDispatch()
  const navigate = useNavigate()
  const { token, status, error } = useSelector((state) => state.auth)
  const loading = status === 'loading'
  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
    defaultValues: { email: '', password: '' },
  })
  if (token) return <Navigate to="/" replace />
  const submit = async (values) => {
    const result = await dispatch(loginAdmin(values))
    if (loginAdmin.fulfilled.match(result)) navigate('/', { replace: true })
  }

  return (
    <Box
      component="main"
      sx={(theme) => ({
        minHeight: '100svh',
        display: 'grid',
        placeItems: 'center',
        bgcolor: theme.palette.mode === 'dark' ? '#14131B' : '#F6F4F8',
        px: { xs: 2, sm: 3, md: 4 },
        py: { xs: 2, sm: 4 },
      })}
    >
      <Card
        elevation={0}
        sx={(theme) => ({
          width: '100%',
          maxWidth: { xs: 560, md: 1120 },
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', md: '1.05fr 1fr' },
          borderRadius: { xs: '24px', md: '32px' },
          overflow: 'hidden',
          borderColor: theme.palette.mode === 'dark' ? '#35313F' : '#E7E1EC',
          boxShadow:
            theme.palette.mode === 'dark'
              ? '0 20px 80px rgba(0,0,0,0.2)'
              : '0 20px 80px rgba(47,30,70,0.07)',
        })}
      >
        <Box
          component="aside"
          aria-label="Learning with LangLex"
          sx={{
            bgcolor: '#FFF7E9',
            color: '#302638',
            p: { xs: 2.5, sm: 3, md: 4 },
            display: 'flex',
            flexDirection: { xs: 'row', md: 'column' },
            alignItems: 'center',
            justifyContent: 'center',
            gap: { xs: 1, md: 2 },
          }}
        >
          <Box
            sx={{
              flex: { xs: 1, md: 'none' },
              textAlign: { xs: 'left', md: 'center' },
            }}
          >
            <Typography
              sx={{
                display: { xs: 'none', md: 'block' },
                color: '#7E6654',
                fontSize: 11,
                fontWeight: 700,
                letterSpacing: '1.7px',
                mb: 1.5,
              }}
            >
              A WORLD OF LEARNING
            </Typography>
            <Typography
              component="h2"
              sx={{
                fontSize: { xs: 20, sm: 26, md: 34 },
                fontWeight: 700,
                lineHeight: 1.22,
                letterSpacing: '-0.8px',
              }}
            >
              Little words.
              <br />
              Big discoveries.
            </Typography>
            <Typography
              sx={{
                color: '#736456',
                fontSize: 13,
                lineHeight: 1.7,
                mt: 1.5,
                maxWidth: 320,
                mx: 'auto',
                display: { xs: 'none', md: 'block' },
              }}
            >
              Helping children discover languages through stories, curiosity and
              play.
            </Typography>
          </Box>
          <Box
            component="img"
            src={illustrationUrl}
            alt="Two children and a friendly fox exploring a storybook beneath alphabet blocks."
            fetchPriority="high"
            width="1254"
            height="1254"
            sx={{
              width: { xs: 96, sm: 156, md: '100%' },
              height: 'auto',
              maxWidth: { md: 340 },
              aspectRatio: '1',
              objectFit: 'contain',
              mixBlendMode: 'multiply',
              maskImage:
                'radial-gradient(ellipse at center, #000 62%, transparent 74%)',
              flexShrink: 0,
            }}
          />
          <Box
            sx={{
              display: { xs: 'none', md: 'flex' },
              gap: 2.5,
              justifyContent: 'center',
              flexWrap: 'wrap',
            }}
          >
            {learningSections.map(({ label, icon: Icon, color }) => (
              <Stack key={label} spacing={0.5} sx={{ alignItems: 'center' }}>
                <Icon sx={{ fontSize: 23, color }} />
                <Typography
                  sx={{ fontSize: 10, fontWeight: 600, color: '#736456' }}
                >
                  {label}
                </Typography>
              </Stack>
            ))}
          </Box>
        </Box>
        <Box
          sx={{
            p: { xs: 3, sm: 5, md: 6 },
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Stack spacing={4} sx={{ width: '100%', maxWidth: 360 }}>
            <Stack direction="row" spacing={1.5} sx={{ alignItems: 'center' }}>
              <Box
                component="img"
                src={logoUrl}
                alt=""
                sx={{
                  width: 48,
                  height: 48,
                  objectFit: 'contain',
                  bgcolor: '#FFFFFF',
                  borderRadius: '12px',
                  p: 0.5,
                }}
              />
              <Box>
                <Typography
                  sx={{
                    fontSize: 21,
                    fontWeight: 700,
                    lineHeight: 1.25,
                    letterSpacing: '-0.5px',
                  }}
                >
                  LangLex
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Admin workspace
                </Typography>
              </Box>
            </Stack>
            <Stack spacing={3.5}>
              <Box>
                <Typography
                  component="h1"
                  variant="h4"
                  sx={{ fontSize: { xs: 26, sm: 30 }, mb: 1 }}
                >
                  Welcome back
                </Typography>
                <Typography color="text.secondary">
                  Sign in to manage your learning content.
                </Typography>
              </Box>
              {error ? (
                <Alert severity="error" sx={{ borderRadius: '12px' }}>
                  {error}
                </Alert>
              ) : null}
              <Stack
                component="form"
                noValidate
                spacing={1}
                onSubmit={handleSubmit(submit)}
                aria-busy={loading}
              >
                <Stack spacing={1}>
                  <FormLabel htmlFor="admin-email" sx={labelStyles}>
                    Email address
                  </FormLabel>
                  <Controller
                    name="email"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        id="admin-email"
                        type="email"
                        fullWidth
                        disabled={loading}
                        placeholder="you@example.com"
                        autoComplete="username"
                        error={Boolean(errors.email)}
                        helperText={errors.email?.message || ' '}
                        sx={fieldStyles}
                        slotProps={{
                          htmlInput: {
                            autoCapitalize: 'none',
                            spellCheck: false,
                            'aria-required': true,
                          },
                          input: {
                            startAdornment: (
                              <InputAdornment position="start">
                                <MailOutlineRounded sx={{ fontSize: 20 }} />
                              </InputAdornment>
                            ),
                          },
                        }}
                      />
                    )}
                  />
                </Stack>
                <Stack spacing={1}>
                  <FormLabel htmlFor="admin-password" sx={labelStyles}>
                    Password
                  </FormLabel>
                  <Controller
                    name="password"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        id="admin-password"
                        fullWidth
                        disabled={loading}
                        placeholder="Your password"
                        type={showPassword ? 'text' : 'password'}
                        autoComplete="current-password"
                        error={Boolean(errors.password)}
                        helperText={errors.password?.message || ' '}
                        sx={fieldStyles}
                        slotProps={{
                          htmlInput: { 'aria-required': true },
                          input: {
                            startAdornment: (
                              <InputAdornment position="start">
                                <LockOutlined sx={{ fontSize: 20 }} />
                              </InputAdornment>
                            ),
                            endAdornment: (
                              <InputAdornment position="end">
                                <IconButton
                                  type="button"
                                  aria-label={
                                    showPassword
                                      ? 'Hide password'
                                      : 'Show password'
                                  }
                                  aria-pressed={showPassword}
                                  disabled={loading}
                                  onMouseDown={(event) =>
                                    event.preventDefault()
                                  }
                                  onClick={() =>
                                    setShowPassword((visible) => !visible)
                                  }
                                  edge="end"
                                  sx={{ color: 'text.secondary' }}
                                >
                                  {showPassword ? (
                                    <VisibilityOffRounded
                                      sx={{ fontSize: 20 }}
                                    />
                                  ) : (
                                    <VisibilityRounded sx={{ fontSize: 20 }} />
                                  )}
                                </IconButton>
                              </InputAdornment>
                            ),
                          },
                        }}
                      />
                    )}
                  />
                </Stack>
                <Button
                  type="submit"
                  variant="contained"
                  size="large"
                  disabled={loading}
                  endIcon={
                    loading ? (
                      <CircularProgress size={18} color="inherit" />
                    ) : (
                      <ArrowForwardRounded />
                    )
                  }
                  sx={{ minHeight: 52, borderRadius: '12px', fontSize: 15 }}
                >
                  {loading ? 'Signing in…' : 'Sign in'}
                </Button>
              </Stack>
            </Stack>
            <Stack
              direction="row"
              spacing={0.75}
              sx={{
                alignItems: 'center',
                justifyContent: 'center',
                color: 'text.secondary',
              }}
            >
              <LockOutlined sx={{ fontSize: 14 }} />
              <Typography variant="caption">
                For authorized administrators
              </Typography>
            </Stack>
          </Stack>
        </Box>
      </Card>
    </Box>
  )
}
