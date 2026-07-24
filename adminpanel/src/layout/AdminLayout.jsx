import {
  ArticleRounded,
  CardMembershipRounded,
  DashboardRounded,
  DarkModeRounded,
  LightModeRounded,
  LogoutRounded,
  MenuRounded,
  NotificationsRounded,
  PaymentsRounded,
  PeopleRounded,
  SchoolRounded,
  SettingsRounded,
} from '@mui/icons-material'
import {
  AppBar,
  Avatar,
  Box,
  Button,
  Divider,
  Drawer,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Stack,
  Switch,
  Toolbar,
  Typography,
  useMediaQuery,
} from '@mui/material'
import { useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { logout } from '../features/auth/authSlice'
import { toggleMode } from '../features/auth/uiSlice'

const drawerWidth = 292
const logoUrl = `${import.meta.env.BASE_URL}brand/logo_new.png`

const navItems = [
  { label: 'Dashboard', path: '/', icon: <DashboardRounded /> },
  { label: 'Users', path: '/users', icon: <PeopleRounded /> },
  { label: 'Learning Content', path: '/resources/courses', icon: <SchoolRounded /> },
  { label: 'Stories', path: '/resources/stories', icon: <ArticleRounded /> },
  { label: 'Payments', path: '/payments', icon: <PaymentsRounded /> },
  { label: 'Subscriptions', path: '/subscriptions', icon: <CardMembershipRounded /> },
  { label: 'Notifications', path: '/notifications', icon: <NotificationsRounded /> },
  { label: 'Settings', path: '/settings', icon: <SettingsRounded /> },
]

export default function AdminLayout() {
  const dispatch = useDispatch()
  const navigate = useNavigate()
  const admin = useSelector((state) => state.auth.admin)
  const mode = useSelector((state) => state.ui.mode)
  const compact = useMediaQuery((theme) => theme.breakpoints.down('lg'))
  const [drawerOpen, setDrawerOpen] = useState(false)

  const handleLogout = () => {
    dispatch(logout())
    navigate('/login', { replace: true })
  }

  const drawer = (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <Stack spacing={1.5} sx={{ px: 2.6, py: 2.6 }}>
        <Stack direction="row" spacing={1.5} sx={{ alignItems: 'center' }}>
          <Box
            component="img"
            src={logoUrl}
            alt="LangLex"
            sx={{
              width: 54,
              height: 54,
              objectFit: 'contain',
              flexShrink: 0,
              bgcolor: '#FFFFFF',
              border: 1,
              borderColor: mode === 'dark' ? 'rgba(255,255,255,0.18)' : 'divider',
              borderRadius: 2,
              p: 0.4,
              boxShadow: mode === 'dark' ? '0 10px 24px rgba(0,0,0,0.32)' : 'none',
            }}
          />
          <Box>
            <Typography variant="h5" sx={{ lineHeight: 1.05, fontSize: 20 }}>
              LangLex
            </Typography>
            <Typography variant="body2" color="text.secondary" fontWeight={600}>
              Admin Console
            </Typography>
          </Box>
        </Stack>
      </Stack>
      <Divider />
      <List sx={{ px: 1.6, py: 2, flex: 1 }}>
        {navItems.map((item) => (
          <ListItemButton
            key={item.path}
            component={NavLink}
            to={item.path}
            end={item.path === '/'}
            onClick={() => setDrawerOpen(false)}
            sx={{
              mb: 0.8,
              minHeight: 52,
              borderRadius: 2,
              color: 'text.primary',
              transition: 'background 160ms ease, color 160ms ease, transform 160ms ease',
              '& .MuiListItemIcon-root': { color: '#77718E' },
              '&:hover': {
                bgcolor: '#F3EEFB',
                transform: 'translateX(2px)',
              },
              '&.active': {
                bgcolor: 'transparent',
                backgroundImage: 'linear-gradient(135deg, #8E5CE6 0%, #7B3FE7 100%)',
                color: 'primary.contrastText',
                boxShadow: '0 12px 28px rgba(126, 72, 224, 0.26)',
                '& .MuiListItemIcon-root': { color: 'inherit' },
              },
            }}
          >
            <ListItemIcon sx={{ minWidth: 42 }}>{item.icon}</ListItemIcon>
            <ListItemText
              primary={
                <Typography component="span" fontWeight={800} fontSize={15}>
                  {item.label}
                </Typography>
              }
            />
          </ListItemButton>
        ))}
      </List>
      <Box sx={{ px: 2, pb: 2.2 }}>
        <Stack
          spacing={1.4}
          sx={{
            borderTop: 1,
            borderColor: 'divider',
            pt: 1.8,
          }}
        >
          <Stack
            direction="row"
            spacing={1.2}
            sx={{
              alignItems: 'center',
              px: 1,
            }}
          >
            <Avatar
              sx={{
                width: 42,
                height: 42,
                bgcolor: '#F0E7FF',
                backgroundImage: 'linear-gradient(135deg, #F0E7FF 0%, #E3F1EC 100%)',
                color: 'primary.main',
                fontWeight: 900,
              }}
            >
              CT
            </Avatar>
            <Box sx={{ minWidth: 0 }}>
              <Typography variant="caption" color="text.secondary" fontWeight={700}>
                Administrator
              </Typography>
              <Typography variant="body2" fontWeight={800} noWrap>
                {admin?.full_name || 'Crisant Technologies'}
              </Typography>
              <Typography variant="caption" color="text.secondary" noWrap>
                {admin?.email}
              </Typography>
            </Box>
          </Stack>
          <Button
            startIcon={<LogoutRounded />}
            onClick={handleLogout}
            fullWidth
            variant="text"
            sx={{
              justifyContent: 'flex-start',
              color: 'primary.main',
              fontWeight: 800,
              px: 1,
              bgcolor: 'rgba(142, 92, 230, 0.08)',
              '&:hover': { bgcolor: 'rgba(142, 92, 230, 0.13)' },
            }}
          >
            Log out
          </Button>
        </Stack>
      </Box>
    </Box>
  )

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: 'background.default' }}>
      <AppBar
        position="fixed"
        color="inherit"
        elevation={0}
        sx={{
          borderBottom: 1,
          borderColor: 'divider',
          width: { lg: `calc(100% - ${drawerWidth}px)` },
          ml: { lg: `${drawerWidth}px` },
        }}
      >
        <Toolbar sx={{ minHeight: 68, px: { xs: 2, md: 3.5 } }}>
          {compact ? (
            <IconButton edge="start" onClick={() => setDrawerOpen(true)} sx={{ mr: 1 }}>
              <MenuRounded />
            </IconButton>
          ) : null}
          <Box sx={{ flex: 1 }}>
            <Typography variant="body1" color="text.primary" fontWeight={700}>
              Administrative workspace
            </Typography>
          </Box>
          <Stack direction="row" spacing={1} sx={{ alignItems: 'center' }}>
            {mode === 'light' ? <LightModeRounded color="action" /> : <DarkModeRounded color="action" />}
            <Switch
              checked={mode === 'dark'}
              onChange={() => dispatch(toggleMode())}
              color="primary"
              slotProps={{ input: { 'aria-label': 'Toggle color mode' } }}
            />
          </Stack>
        </Toolbar>
      </AppBar>

      <Box component="nav" sx={{ width: { lg: drawerWidth }, flexShrink: { lg: 0 } }}>
        <Drawer
          variant={compact ? 'temporary' : 'permanent'}
          open={compact ? drawerOpen : true}
          onClose={() => setDrawerOpen(false)}
          ModalProps={{ keepMounted: true }}
          sx={{
            '& .MuiDrawer-paper': {
              width: drawerWidth,
              borderRight: 1,
              borderColor: 'divider',
              bgcolor: 'background.paper',
              boxShadow: '8px 0 30px rgba(38, 30, 78, 0.04)',
            },
          }}
        >
          {drawer}
        </Drawer>
      </Box>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { xs: '100%', lg: `calc(100% - ${drawerWidth}px)` },
          maxWidth: { xs: '100vw', lg: 'none' },
          minWidth: 0,
          overflowX: 'clip',
          px: { xs: 2, md: 3.2 },
          py: { xs: 10, md: 10.8 },
        }}
      >
        <Outlet />
      </Box>
    </Box>
  )
}
