import {
  ArrowForwardRounded,
  AutoStoriesRounded,
  PeopleRounded,
  PaymentsRounded,
  CardMembershipRounded,
  AddRounded,
} from '@mui/icons-material'
import {
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Grid,
  Skeleton,
  Stack,
  Typography,
  useTheme,
} from '@mui/material'
import { useCallback } from 'react'
import { Link } from 'react-router-dom'
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import PageHeader from '../components/PageHeader'
import StatCard from '../components/StatCard'
import EmptyState from '../components/EmptyState'
import { useAsyncData } from '../hooks/useAsyncData'
import { adminApi } from '../services/adminApi'
import { currency, formatDate, number } from '../utils/formatters'
export default function DashboardPage() {
  const theme = useTheme()
  const loader = useCallback(() => adminApi.overview(), [])
  const { data, loading, error, reload } = useAsyncData(loader)
  const stats = data?.stats || {}
  const mix = data?.content_mix || []
  const mixTotal = mix.reduce((sum, row) => sum + row.value, 0)
  const colors = [
    theme.palette.primary.main,
    theme.palette.secondary.main,
    '#DDA352',
    '#6B98D7',
    '#C77EA6',
  ]
  const trend = data?.revenue_trend || []
  const metrics = [
    [
      'Registered users',
      number(stats.users),
      'Total learner accounts',
      <PeopleRounded key="PeopleRounded" />,
    ],
    [
      'Knowledge topics',
      number(stats.courses),
      `${number(stats.content)} words · ${number(stats.quizzes)} questions`,
      <AutoStoriesRounded key="AutoStoriesRounded" />,
    ],
    [
      'Paid revenue',
      currency(stats.revenue),
      'All time · paid orders only',
      <PaymentsRounded key="PaymentsRounded" />,
    ],
    [
      'Active subscriptions',
      number(stats.active_subscriptions),
      'Current, unexpired subscriptions',
      <CardMembershipRounded key="CardMembershipRounded" />,
    ],
  ]
  return (
    <>
      <PageHeader
        title="Overview"
        subtitle="A clear view of your learners, content and operations."
        action={{
          label: 'Manage content',
          onClick: undefined,
          to: '/learning',
        }}
      />
      {error ? (
        <Card>
          <EmptyState error={error} onRetry={reload} />
        </Card>
      ) : (
        <>
          <Grid container spacing={2}>
            {metrics.map(([title, value, helper, icon]) => (
              <Grid key={title} size={{ xs: 12, sm: 6, lg: 3 }}>
                <StatCard
                  title={title}
                  value={value}
                  helper={helper}
                  icon={icon}
                  loading={loading}
                />
              </Grid>
            ))}
          </Grid>
          <Grid container spacing={2.5} sx={{ mt: 2.5 }}>
            <Grid size={{ xs: 12, lg: 8 }}>
              <Card sx={{ height: '100%' }}>
                <CardContent>
                  <Stack
                    direction="row"
                    spacing={1}
                    sx={{
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      mb: 1,
                    }}
                  >
                    <Box>
                      <Typography variant="h6">Revenue</Typography>
                      <Typography variant="caption" color="text.secondary">
                        Daily paid revenue · last 14 days
                      </Typography>
                    </Box>
                    <Chip size="small" variant="outlined" label="INR" />
                  </Stack>
                  {loading ? (
                    <Skeleton variant="rounded" height={240} sx={{ mt: 2 }} />
                  ) : trend.some((row) => row.revenue > 0) ? (
                    <Box sx={{ height: 260, mt: 3 }}>
                      <ResponsiveContainer width="100%" height="100%">
                        <AreaChart
                          data={trend}
                          margin={{ top: 10, right: 8, left: -12, bottom: 0 }}
                        >
                          <defs>
                            <linearGradient
                              id="revenueFill"
                              x1="0"
                              y1="0"
                              x2="0"
                              y2="1"
                            >
                              <stop
                                offset="0%"
                                stopColor={theme.palette.primary.main}
                                stopOpacity={0.25}
                              />
                              <stop
                                offset="100%"
                                stopColor={theme.palette.primary.main}
                                stopOpacity={0}
                              />
                            </linearGradient>
                          </defs>
                          <CartesianGrid
                            stroke={theme.palette.divider}
                            vertical={false}
                            strokeDasharray="3 5"
                          />
                          <XAxis
                            dataKey="date"
                            tickFormatter={(date) => formatDate(date, 'dd MMM')}
                            tick={{
                              fill: theme.palette.text.secondary,
                              fontSize: 10,
                            }}
                            axisLine={false}
                            tickLine={false}
                            minTickGap={30}
                          />
                          <YAxis
                            tick={{
                              fill: theme.palette.text.secondary,
                              fontSize: 10,
                            }}
                            tickFormatter={(value) => `₹${value}`}
                            axisLine={false}
                            tickLine={false}
                          />
                          <Tooltip
                            labelFormatter={(date) => formatDate(date)}
                            formatter={(value) => [currency(value), 'Revenue']}
                            contentStyle={{
                              background: theme.palette.background.paper,
                              borderColor: theme.palette.divider,
                              borderRadius: 10,
                              color: theme.palette.text.primary,
                            }}
                          />
                          <Area
                            name="Revenue"
                            type="monotone"
                            dataKey="revenue"
                            stroke={theme.palette.primary.main}
                            strokeWidth={2.5}
                            fill="url(#revenueFill)"
                            isAnimationActive={false}
                          />
                        </AreaChart>
                      </ResponsiveContainer>
                    </Box>
                  ) : (
                    <EmptyState
                      title="No revenue in this period"
                      description="Paid orders from the last 14 days will appear here."
                    />
                  )}
                </CardContent>
              </Card>
            </Grid>
            <Grid size={{ xs: 12, lg: 4 }}>
              <Card sx={{ height: '100%' }}>
                <CardContent>
                  <Typography variant="h6">Learning activity</Typography>
                  <Typography variant="caption" color="text.secondary">
                    Recorded sessions by content type
                  </Typography>
                  {loading ? (
                    <Skeleton variant="rounded" height={220} sx={{ mt: 3 }} />
                  ) : mixTotal ? (
                    <>
                      <Stack
                        direction="row"
                        spacing={1}
                        sx={{ alignItems: 'baseline', mt: 3 }}
                      >
                        <Typography variant="h4">{number(mixTotal)}</Typography>
                        <Typography color="text.secondary" variant="body2">
                          sessions
                        </Typography>
                      </Stack>
                      <Box
                        sx={{
                          display: 'flex',
                          height: 12,
                          borderRadius: 8,
                          overflow: 'hidden',
                          gap: 0.5,
                          my: 2.5,
                        }}
                      >
                        {mix.map((row, index) => (
                          <Box
                            key={row.name}
                            sx={{
                              width: `${(row.value / mixTotal) * 100}%`,
                              bgcolor: colors[index % colors.length],
                            }}
                          />
                        ))}
                      </Box>
                      <Stack spacing={1.5}>
                        {mix.map((row, index) => (
                          <Stack
                            key={row.name}
                            direction="row"
                            spacing={1.2}
                            sx={{ alignItems: 'center' }}
                          >
                            <Box
                              sx={{
                                width: 8,
                                height: 8,
                                borderRadius: '50%',
                                bgcolor: colors[index % colors.length],
                              }}
                            />
                            <Typography
                              variant="body2"
                              sx={{ flex: 1, textTransform: 'capitalize' }}
                            >
                              {row.name}
                            </Typography>
                            <Typography variant="body2" fontWeight={600}>
                              {number(row.value)}
                            </Typography>
                            <Typography
                              variant="caption"
                              color="text.secondary"
                              sx={{ width: 35, textAlign: 'right' }}
                            >
                              {Math.round((row.value / mixTotal) * 100)}%
                            </Typography>
                          </Stack>
                        ))}
                      </Stack>
                      <Typography
                        variant="caption"
                        color="text.secondary"
                        sx={{ display: 'block', pt: 3 }}
                      >
                        {number(stats.completed_sessions)} completed sessions
                        across all learners
                      </Typography>
                    </>
                  ) : (
                    <EmptyState
                      title="Learning starts here"
                      description="Activity will appear as learners start lessons."
                    />
                  )}
                </CardContent>
              </Card>
            </Grid>
            <Grid size={{ xs: 12, lg: 8 }}>
              <Card>
                <CardContent>
                  <Stack
                    direction="row"
                    sx={{
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      mb: 1,
                    }}
                  >
                    <Typography variant="h6">Recent learners</Typography>
                    <Button
                      component={Link}
                      to="/users"
                      endIcon={<ArrowForwardRounded />}
                    >
                      View all
                    </Button>
                  </Stack>
                  {loading ? (
                    <Skeleton height={180} />
                  ) : data?.recent_users?.length ? (
                    data.recent_users.slice(0, 4).map((user) => (
                      <Stack
                        key={user.id}
                        component={Link}
                        to={`/users/${user.id}`}
                        direction="row"
                        spacing={1.5}
                        sx={{
                          py: 1.7,
                          borderTop: 1,
                          borderColor: 'divider',
                          alignItems: 'center',
                          textDecoration: 'none',
                          '&:hover': { bgcolor: 'action.hover' },
                          borderRadius: 1,
                        }}
                      >
                        <Avatar
                          sx={{
                            bgcolor: 'action.selected',
                            color: 'primary.main',
                            fontSize: 14,
                            width: 38,
                            height: 38,
                          }}
                        >
                          {user.full_name?.[0] || 'U'}
                        </Avatar>
                        <Box sx={{ flex: 1, minWidth: 0 }}>
                          <Typography variant="body2" fontWeight={600} noWrap>
                            {user.full_name}
                          </Typography>
                          <Typography
                            variant="caption"
                            color="text.secondary"
                            noWrap
                            component="p"
                          >
                            {user.email || user.mobile_number}
                          </Typography>
                        </Box>
                        <Typography
                          variant="caption"
                          color="text.secondary"
                          sx={{ whiteSpace: 'nowrap' }}
                        >
                          {formatDate(user.created_at, 'dd MMM')}
                        </Typography>
                        <ArrowForwardRounded
                          sx={{ fontSize: 16, color: 'text.secondary' }}
                        />
                      </Stack>
                    ))
                  ) : (
                    <EmptyState
                      title="No learners yet"
                      description="Accounts will appear when learners register in the app."
                    />
                  )}
                </CardContent>
              </Card>
            </Grid>
            <Grid size={{ xs: 12, lg: 4 }}>
              <Card sx={{ height: '100%', bgcolor: 'action.selected' }}>
                <CardContent>
                  <AutoStoriesRounded
                    sx={{ color: 'primary.main', fontSize: 36, mb: 2 }}
                  />
                  <Typography variant="h6" sx={{ mb: 1 }}>
                    Make room for discovery
                  </Typography>
                  <Typography
                    variant="body2"
                    color="text.secondary"
                    sx={{ mb: 2 }}
                  >
                    Keep the learning library fresh with new lessons, stories
                    and practice activities.
                  </Typography>
                  <Button
                    component={Link}
                    to="/resources/stories"
                    variant="contained"
                    startIcon={<AddRounded />}
                  >
                    Manage stories
                  </Button>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </>
      )}
    </>
  )
}
