import { CssBaseline, ThemeProvider } from '@mui/material'
import { useMemo, useEffect } from 'react'
import { Toaster } from 'react-hot-toast'
import { useDispatch, useSelector } from 'react-redux'
import {
  BrowserRouter,
  Navigate,
  Outlet,
  Route,
  Routes,
} from 'react-router-dom'
import { logout } from './features/auth/authSlice'
import { buildTheme } from './app/theme'
import AdminLayout from './layout/AdminLayout'
import DashboardPage from './pages/DashboardPage'
import LoginPage from './pages/LoginPage'
import NotificationsPage from './pages/NotificationsPage'
import NotFoundPage from './pages/NotFoundPage'
import PaymentsPage from './pages/PaymentsPage'
import LearningContentPage from './pages/LearningContentPage'
import ResourcePage from './pages/ResourcePage'
import SettingsPage from './pages/SettingsPage'
import SubscriptionsPage from './pages/SubscriptionsPage'
import UserDetailPage from './pages/UserDetailPage'
import AuditPage from './pages/AuditPage'
import MediaPage from './pages/MediaPage'
import UsersPage from './pages/UsersPage'

function App() {
  const dispatch = useDispatch()
  useEffect(() => {
    const expire = () => dispatch(logout())
    window.addEventListener('langlex:session-expired', expire)
    return () => window.removeEventListener('langlex:session-expired', expire)
  }, [dispatch])
  const mode = useSelector((state) => state.ui.mode)
  const theme = useMemo(() => buildTheme(mode), [mode])

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <BrowserRouter basename={import.meta.env.BASE_URL.replace(/\/$/, '')}>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route element={<ProtectedRoute />}>
            <Route element={<AdminLayout />}>
              <Route index element={<DashboardPage />} />
              <Route path="users" element={<UsersPage />} />
              <Route path="users/:id" element={<UserDetailPage />} />
              <Route path="learning" element={<LearningContentPage />} />
              <Route path="learning/:section" element={<LearningContentPage />} />
              <Route path="learning/:section/:topicId" element={<LearningContentPage />} />
              <Route path="resources/:resource" element={<ResourcePage />} />
              <Route path="payments" element={<PaymentsPage />} />
              <Route path="subscriptions" element={<SubscriptionsPage />} />
              <Route path="notifications" element={<NotificationsPage />} />
              <Route path="audit" element={<AuditPage />} />
              <Route path="media" element={<MediaPage />} />
              <Route path="settings" element={<SettingsPage />} />
            </Route>
          </Route>
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </BrowserRouter>
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 3500,
          style: {
            background: theme.palette.background.paper,
            color: theme.palette.text.primary,
            border: `1px solid ${theme.palette.divider}`,
          },
        }}
      />
    </ThemeProvider>
  )
}

function ProtectedRoute() {
  const token = useSelector((state) => state.auth.token)
  if (!token) return <Navigate to="/login" replace />
  return <Outlet />
}

export default App
