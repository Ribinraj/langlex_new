import { CssBaseline, ThemeProvider } from '@mui/material'
import { useMemo } from 'react'
import { Toaster } from 'react-hot-toast'
import { useSelector } from 'react-redux'
import { BrowserRouter, Navigate, Outlet, Route, Routes } from 'react-router-dom'
import { buildTheme } from './app/theme'
import AdminLayout from './layout/AdminLayout'
import DashboardPage from './pages/DashboardPage'
import LoginPage from './pages/LoginPage'
import NotificationsPage from './pages/NotificationsPage'
import NotFoundPage from './pages/NotFoundPage'
import PaymentsPage from './pages/PaymentsPage'
import ResourcePage from './pages/ResourcePage'
import SettingsPage from './pages/SettingsPage'
import SubscriptionsPage from './pages/SubscriptionsPage'
import UserDetailPage from './pages/UserDetailPage'
import UsersPage from './pages/UsersPage'

function App() {
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
              <Route path="resources/:resource" element={<ResourcePage />} />
              <Route path="payments" element={<PaymentsPage />} />
              <Route path="subscriptions" element={<SubscriptionsPage />} />
              <Route path="notifications" element={<NotificationsPage />} />
              <Route path="settings" element={<SettingsPage />} />
            </Route>
          </Route>
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </BrowserRouter>
      <Toaster position="top-right" toastOptions={{ duration: 3500 }} />
    </ThemeProvider>
  )
}

function ProtectedRoute() {
  const token = useSelector((state) => state.auth.token)
  if (!token) return <Navigate to="/login" replace />
  return <Outlet />
}

export default App
