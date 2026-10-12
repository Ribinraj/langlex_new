import {
  HistoryRounded,
  PermMediaOutlined,
  CardMembershipOutlined,
  SpaceDashboardOutlined,
  DarkModeRounded,
  LightModeRounded,
  LogoutRounded,
  MenuRounded,
  NotificationsNoneRounded,
  PaymentsOutlined,
  PeopleOutlineRounded,
  SchoolOutlined,
  SettingsOutlined,
  ChevronRightRounded,
  CloseRounded,
} from '@mui/icons-material'
import {
  AppBar,
  ThemeProvider,
  Avatar,
  Box,
  Button,
  Drawer,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Stack,
  Toolbar,
  Tooltip,
  Typography,
  useMediaQuery,
} from '@mui/material'
import { useEffect, useMemo, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { logout } from '../features/auth/authSlice'
import { toggleMode } from '../features/auth/uiSlice'
import { buildWorkspaceTheme } from '../app/workspaceTheme'
const drawerWidth = 252
const navItems = [
  {
    label: 'Overview',
    path: '/',
    icon: <SpaceDashboardOutlined />,
    group: 'WORKSPACE',
  },
  { label: 'Users', path: '/users', icon: <PeopleOutlineRounded /> },
  {
    label: 'Learning content',
    path: '/learning',
    icon: <SchoolOutlined />,
  },

  {
    label: 'Payments',
    path: '/payments',
    icon: <PaymentsOutlined />,
    group: 'OPERATIONS',
  },
  {
    label: 'Subscriptions',
    path: '/subscriptions',
    icon: <CardMembershipOutlined />,
  },
  {
    label: 'Notifications',
    path: '/notifications',
    icon: <NotificationsNoneRounded />,
  },
  { label: 'Media library', path: '/media', icon: <PermMediaOutlined /> },
  { label: 'Audit history', path: '/audit', icon: <HistoryRounded /> },
  { label: 'Settings', path: '/settings', icon: <SettingsOutlined /> },
]
export default function AdminLayout() {
  const mode = useSelector((state) => state.ui.mode)
  const theme = useMemo(() => buildWorkspaceTheme(mode), [mode])
  return (
    <ThemeProvider theme={theme}>
      <WorkspaceLayout />
    </ThemeProvider>
  )
}

function WorkspaceLayout() {
  const dispatch = useDispatch(),
    navigate = useNavigate(),
    { pathname } = useLocation()
  const admin = useSelector((state) => state.auth.admin),
    mode = useSelector((state) => state.ui.mode)
  const compact = useMediaQuery((theme) => theme.breakpoints.down('lg'))
  const [drawerOpen, setDrawerOpen] = useState(false)
  useEffect(() => {
    window.scrollTo(0, 0)
  }, [pathname])
  const active = (item) =>
    item.path === '/'
      ? pathname === '/'
      : item.path === '/resources/courses'
        ? pathname.startsWith('/resources/') &&
          pathname !== '/resources/stories'
        : pathname.startsWith(item.path)
  const section = navItems.find(active)?.label || 'Workspace'
  const drawer = (
    <Box
      sx={{
        height: '100%',
        minHeight: 0,
        display: 'flex',
        flexDirection: 'column',
        background: (theme) => theme.workspace.sidebar,
      }}
    >
      <Stack
        direction="row"
        spacing={1.25}
        sx={{ px: 2.5, py: 2.5, alignItems: 'center', flexShrink: 0 }}
      >
        <Box
          component="img"
          src={`${import.meta.env.BASE_URL}brand/logo_new.png`}
          alt="LangLex"
          sx={{
            width: 42,
            height: 42,
            objectFit: 'contain',
            bgcolor: '#fff',
            borderRadius: 2,
            p: 0.4,
          }}
        />
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography
            variant="h6"
            sx={{ fontSize: 20, lineHeight: 1.3, letterSpacing: '-0.5px' }}
          >
            LangLex
          </Typography>
          <Typography
            variant="caption"
            sx={{ color: 'text.secondary', fontSize: 11 }}
          >
            Administration
          </Typography>
        </Box>
        {compact && (
          <IconButton
            aria-label="Close navigation"
            onClick={() => setDrawerOpen(false)}
          >
            <CloseRounded />
          </IconButton>
        )}
      </Stack>
      <List
        aria-label="Main navigation"
        sx={{
          px: 1.5,
          py: 0.5,
          flex: 1,
          minHeight: 0,
          overflowY: 'auto',
          scrollbarWidth: 'thin',
          scrollbarColor: 'transparent transparent',
          '&:hover, &:focus-within': { scrollbarColor: 'auto' },
          '&::-webkit-scrollbar': { width: 4 },
        }}
      >
        {navItems.map((item) => (
          <Box key={item.path}>
            {item.group && (
              <Typography
                sx={{
                  px: 1.5,
                  pt: item.path === '/' ? 0.5 : 2.25,
                  pb: 1,
                  fontSize: 10,
                  fontWeight: 700,
                  letterSpacing: 1.3,
                  color: 'text.secondary',
                }}
                color="text.secondary"
              >
                {item.group}
              </Typography>
            )}
            <ListItemButton
              component={Link}
              to={item.path}
              selected={active(item)}
              aria-current={active(item) ? 'page' : undefined}
              onClick={() => setDrawerOpen(false)}
              sx={{
                mb: 0.25,
                minHeight: 44,
                px: 1.5,
                py: 0.75,
                borderRadius: '10px',
                position: 'relative',
                transition: 'background-color 160ms ease, color 160ms ease',
                '&::before': {
                  content: '""',
                  position: 'absolute',
                  left: 0,
                  top: 12,
                  bottom: 12,
                  width: 3,
                  borderRadius: 3,
                  bgcolor: 'primary.main',
                  opacity: active(item) ? 1 : 0,
                },
                color: 'text.secondary',
                '&:hover, &.Mui-focusVisible': {
                  bgcolor: 'action.hover',
                  color: 'text.primary',
                },
                '&.Mui-selected': {
                  bgcolor: 'action.selected',
                  color: 'primary.main',
                  '&:hover, &.Mui-focusVisible': {
                    bgcolor: 'action.selected',
                    color: 'primary.main',
                  },
                },
              }}
            >
              <ListItemIcon
                sx={{
                  minWidth: 34,
                  color: 'inherit',
                  '& svg': { fontSize: 21 },
                }}
              >
                {item.icon}
              </ListItemIcon>
              <ListItemText
                primary={item.label}
                slotProps={{
                  primary: {
                    sx: {
                      fontSize: 13,
                      lineHeight: 1.5,
                      fontWeight: active(item) ? 700 : 500,
                    },
                  },
                }}
              />
            </ListItemButton>
          </Box>
        ))}
      </List>
      <Box
        sx={{
          p: 1.5,
          mt: 1,
          flexShrink: 0,
          borderTop: 1,
          borderColor: 'divider',
          bgcolor:
            mode === 'dark' ? 'rgba(2,17,28,0.2)' : 'rgba(255,255,255,0.4)',
        }}
      >
        <Stack
          direction="row"
          spacing={1.25}
          sx={{ alignItems: 'center', p: 0.75, mb: 1 }}
        >
          <Avatar
            sx={{
              width: 36,
              height: 36,
              borderRadius: '10px',
              flexShrink: 0,
              bgcolor: 'action.selected',
              color: 'primary.main',
              fontSize: 12,
              fontWeight: 700,
            }}
          >
            {(admin?.full_name || 'Admin')
              .split(' ')
              .map((part) => part[0])
              .slice(0, 2)
              .join('')}
          </Avatar>
          <Box sx={{ minWidth: 0, flex: 1 }}>
            <Typography
              noWrap
              variant="body2"
              title={admin?.full_name || 'Administrator'}
              sx={{ fontSize: 12, fontWeight: 600, lineHeight: 1.7 }}
            >
              {admin?.full_name || 'Administrator'}
            </Typography>
            <Typography
              noWrap
              component="p"
              variant="caption"
              title={admin?.email}
              sx={{ fontSize: 10, color: 'text.secondary', lineHeight: 1.6 }}
            >
              {admin?.email}
            </Typography>
          </Box>
        </Stack>
        <Button
          fullWidth
          startIcon={<LogoutRounded sx={{ fontSize: '18px !important' }} />}
          sx={{
            justifyContent: 'flex-start',
            px: 1.5,
            minHeight: 44,
            color: 'text.secondary',
            fontSize: 12,
            borderRadius: '10px',
            border: 1,
            borderColor: 'divider',
            bgcolor: 'transparent',
            '&:hover': { bgcolor: 'action.hover', color: 'text.primary' },
          }}
          onClick={() => {
            dispatch(logout())
            navigate('/login', { replace: true })
          }}
        >
          Log out
        </Button>
      </Box>
    </Box>
  )
  return (
    <Box
      sx={{
        display: 'flex',
        minHeight: '100vh',
        color: 'text.primary',
        backgroundColor: 'background.default',
        backgroundImage: (theme) => theme.workspace.background,
        backgroundAttachment: 'fixed',
        '& *:focus-visible': { outlineColor: 'primary.main' },
      }}
    >
      <Box
        component="a"
        href="#main-content"
        sx={{
          position: 'fixed',
          top: -100,
          left: 16,
          zIndex: 1500,
          p: 2,
          bgcolor: 'background.paper',
          '&:focus': { top: 8 },
        }}
      >
        Skip to content
      </Box>
      <AppBar
        position="fixed"
        color="inherit"
        elevation={0}
        sx={{
          borderBottom: 1,
          borderColor: 'divider',
          backgroundColor: (theme) => theme.workspace.header,
          backdropFilter: 'blur(18px)',
          width: { lg: `calc(100% - ${drawerWidth}px)` },
        }}
      >
        <Toolbar sx={{ gap: 1, minHeight: 68, px: { xs: 2, md: 4 } }}>
          {compact && (
            <IconButton
              aria-label="Open navigation"
              onClick={() => setDrawerOpen(true)}
            >
              <MenuRounded />
            </IconButton>
          )}
          <Stack
            direction="row"
            spacing={1}
            sx={{ alignItems: 'center', flex: 1 }}
          >
            <Typography
              variant="body2"
              color="text.secondary"
              sx={{ display: { xs: 'none', sm: 'block' } }}
            >
              Workspace
            </Typography>
            <ChevronRightRounded
              sx={{
                fontSize: 16,
                color: 'text.secondary',
                display: { xs: 'none', sm: 'block' },
              }}
            />
            <Typography variant="body2" fontWeight={600}>
              {section}
            </Typography>
          </Stack>
          <Tooltip
            title={`Switch to ${mode === 'dark' ? 'light' : 'dark'} mode`}
          >
            <IconButton
              aria-label={`Switch to ${mode === 'dark' ? 'light' : 'dark'} mode`}
              onClick={() => dispatch(toggleMode())}
            >
              {mode === 'dark' ? (
                <LightModeRounded fontSize="small" />
              ) : (
                <DarkModeRounded fontSize="small" />
              )}
            </IconButton>
          </Tooltip>
          <Avatar
            sx={{
              width: 32,
              height: 32,
              ml: 1,
              bgcolor: 'action.selected',
              color: 'primary.main',
              fontSize: 12,
            }}
          >
            {admin?.full_name?.[0] || 'A'}
          </Avatar>
        </Toolbar>
      </AppBar>
      <Box component="nav" sx={{ width: { lg: drawerWidth }, flexShrink: 0 }}>
        <Drawer
          variant={compact ? 'temporary' : 'permanent'}
          open={compact ? drawerOpen : true}
          onClose={() => setDrawerOpen(false)}
          ModalProps={{ keepMounted: true }}
          sx={{
            '& .MuiDrawer-paper': {
              width: drawerWidth,
              borderColor: 'divider',
              overflow: 'hidden',
              boxSizing: 'border-box',
            },
          }}
        >
          {drawer}
        </Drawer>
      </Box>
      <Box
        component="main"
        id="main-content"
        tabIndex={-1}
        sx={{
          flex: 1,
          minWidth: 0,
          px: { xs: 2, md: 4 },
          pt: { xs: 11, md: 12 },
          pb: 5,
        }}
      >
        <Box sx={{ maxWidth: 1600, mx: 'auto' }}>
          <Outlet />
        </Box>
      </Box>
    </Box>
  )
}
