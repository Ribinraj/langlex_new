import {
  CheckCircleRounded,
  MenuBookRounded,
  PaidRounded,
  PeopleRounded,
  QueryStatsRounded,
} from '@mui/icons-material'
import {
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Grid,
  Stack,
  Typography,
} from '@mui/material'
import { useCallback } from 'react'
import { Link as RouterLink } from 'react-router-dom'
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import StatCard from '../components/StatCard'
import StatusChip from '../components/StatusChip'
import { adminApi } from '../services/adminApi'
import { currency, formatDate, number } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'

const colors = ['#8E5CE6', '#5C9B81', '#DC8E2E', '#4B80D7']

export default function DashboardPage() {
  const loadOverview = useCallback(() => adminApi.overview(), [])
  const { data, loading } = useAsyncData(loadOverview)
  const stats = data?.stats || {}
  const activityTrend = normalizedActivity(data?.activity_trend || [])
  const revenueTrend = normalizedRevenue(data?.revenue_trend || [])
  const progressMix = normalizedMix(data?.content_mix || [])
  const activitySparkline = activityTrend.map((item) => item.minutes)
  const revenueSparkline = revenueTrend.map((item) => item.revenue)
  const progressSparkline = activityTrend.map((item) => item.activities || item.minutes)

  return (
    <Stack spacing={2.4}>
      <Stack
        direction={{ xs: 'column', md: 'row' }}
        spacing={2}
        sx={{ justifyContent: 'space-between', alignItems: { xs: 'stretch', md: 'center' } }}
      >
        <Box>
          <Typography variant="h3" sx={{ fontSize: { xs: 26, md: 34 }, mb: 0.7 }}>
            Welcome back, Admin! <Box component="span">👋</Box>
          </Typography>
          <Typography color="text.secondary">
            Here&apos;s what&apos;s happening with your platform today.
          </Typography>
        </Box>
      </Stack>

      <Grid container spacing={2.2}>
        <Grid size={{ xs: 12, sm: 6, xl: 3 }}>
          <StatCard
            title="Registered Users"
            value={loading ? '-' : number(stats.users)}
            helper="Student accounts"
            icon={<PeopleRounded />}
            color="#8E5CE6"
            iconBg="#F0E7FF"
            sparkline={activitySparkline}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, xl: 3 }}>
          <StatCard
            title="Learning Items"
            value={loading ? '-' : number(stats.content)}
            helper={`${number(stats.courses)} courses`}
            icon={<MenuBookRounded />}
            color="#5C9B81"
            iconBg="#E4F4ED"
            sparkline={progressMix.map((item) => item.value)}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, xl: 3 }}>
          <StatCard
            title="Paid Revenue"
            value={loading ? '-' : currency(stats.revenue)}
            helper={`${number(stats.payment_orders)} payment orders`}
            icon={<PaidRounded />}
            color="#DC8E2E"
            iconBg="#FCEEDC"
            sparkline={revenueSparkline}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, xl: 3 }}>
          <StatCard
            title="Completed Sessions"
            value={loading ? '-' : number(stats.completed_sessions)}
            helper={`${number(stats.quizzes)} quiz questions`}
            icon={<CheckCircleRounded />}
            color="#4B80D7"
            iconBg="#E5EEFF"
            sparkline={progressSparkline}
          />
        </Grid>

        <Grid size={{ xs: 12, lg: 7 }}>
          <ChartCard title="Daily Learning Activity" icon={<QueryStatsRounded />}>
            <ResponsiveContainer width="100%" height={290}>
              <AreaChart data={activityTrend} margin={{ left: -10, right: 14, top: 8, bottom: 0 }}>
                <defs>
                  <linearGradient id="activityFill" x1="0" x2="0" y1="0" y2="1">
                    <stop offset="0%" stopColor="#8E5CE6" stopOpacity={0.26} />
                    <stop offset="100%" stopColor="#8E5CE6" stopOpacity={0.02} />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="#E9E4F1" vertical={false} />
                <XAxis
                  dataKey="label"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: '#6D6580', fontSize: 12 }}
                />
                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#6D6580', fontSize: 12 }} />
                <Tooltip />
                <Area
                  type="monotone"
                  dataKey="minutes"
                  name="Minutes"
                  stroke="#8E5CE6"
                  fill="url(#activityFill)"
                  strokeWidth={3}
                  dot={{ r: 4, fill: '#8E5CE6', strokeWidth: 2, stroke: '#FFFFFF' }}
                  activeDot={{ r: 6 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </ChartCard>
        </Grid>

        <Grid size={{ xs: 12, lg: 5 }}>
          <ChartCard title="Progress Mix" icon={<QueryStatsRounded />}>
            <Grid container spacing={2} sx={{ alignItems: 'center' }}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <ResponsiveContainer width="100%" height={260}>
                  <PieChart>
                    <Pie
                      data={progressMix}
                      dataKey="value"
                      nameKey="name"
                      innerRadius={68}
                      outerRadius={104}
                      paddingAngle={4}
                    >
                      {progressMix.map((entry, index) => (
                        <Cell key={entry.name} fill={colors[index % colors.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <Stack spacing={2.1}>
                  {progressMix.map((item, index) => (
                    <Stack
                      key={item.name}
                      direction="row"
                      spacing={1.4}
                      sx={{ alignItems: 'center', justifyContent: 'space-between' }}
                    >
                      <Stack direction="row" spacing={1.2} sx={{ alignItems: 'center' }}>
                        <Box
                          sx={{
                            width: 12,
                            height: 12,
                            borderRadius: '50%',
                            bgcolor: colors[index % colors.length],
                          }}
                        />
                        <Typography fontWeight={700} fontSize={13}>
                          {item.name}
                        </Typography>
                      </Stack>
                      <Box sx={{ textAlign: 'right' }}>
                        <Typography fontWeight={800}>{item.percent}%</Typography>
                        <Typography variant="caption" color="text.secondary">
                          {number(item.value)} users
                        </Typography>
                      </Box>
                    </Stack>
                  ))}
                </Stack>
              </Grid>
            </Grid>
          </ChartCard>
        </Grid>

        <Grid size={{ xs: 12, lg: 7 }}>
          <ChartCard
            title="Revenue Trend"
            icon={<PaidRounded />}
            iconTone="#8E5CE6"
          >
            <ResponsiveContainer width="100%" height={235}>
              <BarChart data={revenueTrend} margin={{ left: -6, right: 14, top: 8, bottom: 0 }}>
                <CartesianGrid stroke="#E9E4F1" vertical={false} />
                <XAxis
                  dataKey="label"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: '#6D6580', fontSize: 12 }}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: '#6D6580', fontSize: 12 }}
                  tickFormatter={(value) => `₹${value}`}
                />
                <Tooltip formatter={(value) => currency(value)} />
                <Bar dataKey="revenue" fill="#8E5CE6" radius={[6, 6, 0, 0]} barSize={38} />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
        </Grid>

        <Grid size={{ xs: 12, lg: 5 }}>
          <Card sx={{ height: '100%' }}>
            <CardContent sx={{ p: 2.4 }}>
              <Stack spacing={2}>
                <Stack direction="row" sx={{ alignItems: 'center', justifyContent: 'space-between' }}>
                  <Typography variant="h6">Recent Users</Typography>
                  <Button
                    component={RouterLink}
                    to="/users"
                    size="small"
                    sx={{ bgcolor: '#F1E8FF', color: 'primary.main', px: 1.5 }}
                  >
                    View all
                  </Button>
                </Stack>
                <Chip
                  label={`${number(stats.active_subscriptions || 0)} Active`}
                  size="small"
                  color="success"
                  variant="outlined"
                  sx={{ alignSelf: 'flex-start', fontWeight: 800 }}
                />
                {(data?.recent_users || []).slice(0, 4).map((user, index) => (
                  <Stack
                    key={user.id}
                    direction="row"
                    spacing={1.5}
                    sx={{
                      alignItems: 'center',
                      borderBottom: 1,
                      borderColor: 'divider',
                      pb: 1.4,
                    }}
                  >
                    <Avatar sx={{ bgcolor: index % 2 ? '#FBE8C6' : '#DDF4E8', color: index % 2 ? '#B36A18' : '#268658' }}>
                      {initials(user.full_name)}
                    </Avatar>
                    <Box sx={{ minWidth: 0, flex: 1 }}>
                      <Typography fontWeight={800} noWrap>
                        {user.full_name}
                      </Typography>
                      <Typography color="text.secondary" variant="caption" noWrap>
                        {user.email || user.mobile_number}
                      </Typography>
                    </Box>
                    <StatusChip value={user.subscription_status || 'active'} />
                    <Typography variant="caption" color="text.secondary" sx={{ minWidth: 86, textAlign: 'right' }}>
                      {formatDate(user.created_at)}
                    </Typography>
                  </Stack>
                ))}
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Stack>
  )
}

function ChartCard({ title, icon, children, iconTone = '#161229' }) {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent sx={{ p: 2.4 }}>
        <Stack
          direction="row"
          spacing={1.2}
          sx={{ mb: 2, alignItems: 'center', justifyContent: 'space-between' }}
        >
          <Stack direction="row" spacing={1.2} sx={{ alignItems: 'center' }}>
            <Avatar sx={{ width: 28, height: 28, bgcolor: `${iconTone}14`, color: iconTone }}>
              {icon}
            </Avatar>
            <Typography variant="h6">{title}</Typography>
          </Stack>
        </Stack>
        {children}
      </CardContent>
    </Card>
  )
}

function normalizedActivity(rows) {
  return rows.map((row) => ({
    ...row,
    label: formatDate(row.date, 'dd MMM'),
    minutes: Number(row.minutes || row.activities || 0),
  }))
}

function normalizedRevenue(rows) {
  return rows.map((row) => ({
    ...row,
    label: formatDate(row.date, 'dd MMM'),
    revenue: Number(row.revenue || 0),
  }))
}

function normalizedMix(rows) {
  const source = rows
  const total = source.reduce((sum, row) => sum + Number(row.value || 0), 0) || 1

  return source.map((row) => ({
    name: String(row.name || row.content_type || 'Unknown').replace(/_/g, ' '),
    value: Number(row.value || 0),
    percent: Math.round((Number(row.value || 0) / total) * 100),
  }))
}

function initials(name = '') {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  return (parts[0]?.[0] || 'A') + (parts[1]?.[0] || '')
}
