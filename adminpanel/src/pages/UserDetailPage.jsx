import { ArrowBackRounded } from '@mui/icons-material'
import { Card, CardContent, Chip, Grid, Stack, Typography } from '@mui/material'
import { useCallback } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import AppDataTable from '../components/AppDataTable'
import PageHeader from '../components/PageHeader'
import StatusChip from '../components/StatusChip'
import { adminApi } from '../services/adminApi'
import { currency, formatDate, formatDateTime } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'

export default function UserDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const loadUser = useCallback(() => adminApi.user(id), [id])
  const { data, loading } = useAsyncData(loadUser)
  const user = data?.user

  return (
    <>
      <PageHeader
        title={user?.full_name || 'User Detail'}
        subtitle={user ? `${user.mobile_number} · ${user.email || 'No email'}` : 'Loading account'}
        action={{
          label: 'Back to users',
          onClick: () => navigate('/users'),
        }}
        actionIcon={<ArrowBackRounded />}
      />

      <Grid container spacing={2.2}>
        <Grid size={{ xs: 12, md: 4 }}>
          <InfoCard title="Profile">
            <Info label="Name" value={user?.full_name} />
            <Info label="Mobile" value={user?.mobile_number} />
            <Info label="Email" value={user?.email} />
            <Info label="School" value={user?.school} />
            <Info label="Location" value={[user?.city, user?.state].filter(Boolean).join(', ')} />
            <Info label="Joined" value={formatDateTime(user?.created_at)} />
          </InfoCard>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <InfoCard title="Learning Setup">
            <Info label="Child name" value={data?.learning_setup?.child_name} />
            <Info label="Age group" value={data?.learning_setup?.age_group} />
            <Info label="Home language" value={data?.learning_setup?.primary_language} />
            <Info label="Learning language" value={data?.learning_setup?.learning_language} />
            <Info label="Level" value={data?.learning_setup?.level} />
            <Info label="Daily goal" value={`${data?.learning_setup?.daily_goal_minutes || 15} minutes`} />
            <Stack direction="row" spacing={0.8} flexWrap="wrap">
              {(data?.learning_setup?.interests || []).map((interest) => (
                <Chip key={interest} label={interest} size="small" />
              ))}
            </Stack>
          </InfoCard>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <InfoCard title="Current Subscription">
            {data?.subscriptions?.[0] ? (
              <>
                <Info label="Plan" value={data.subscriptions[0].plan_name} />
                <Info label="Amount" value={currency(data.subscriptions[0].amount)} />
                <Info label="Period" value={data.subscriptions[0].plan_timeperiod} />
                <StatusChip value={data.subscriptions[0].status} />
                <Info label="Expires" value={formatDateTime(data.subscriptions[0].expires_at)} />
              </>
            ) : (
              <Typography color="text.secondary">Free access, no active paid subscription.</Typography>
            )}
          </InfoCard>
        </Grid>

        <Grid size={{ xs: 12 }}>
          <Section title="Content Progress" />
          <AppDataTable
            loading={loading}
            rows={data?.progress || []}
            columns={[
              { key: 'content_type', label: 'Type' },
              { key: 'content_key', label: 'Key', minWidth: 180 },
              { key: 'status', label: 'Status', render: (row) => <StatusChip value={row.status} /> },
              { key: 'position', label: 'Position' },
              { key: 'total_items', label: 'Items' },
              { key: 'score', label: 'Score' },
              { key: 'updated_at', label: 'Updated', render: (row) => formatDateTime(row.updated_at) },
            ]}
          />
        </Grid>

        <Grid size={{ xs: 12, lg: 6 }}>
          <Section title="Payments" />
          <AppDataTable
            loading={loading}
            rows={data?.payments || []}
            columns={[
              { key: 'plan_name', label: 'Plan' },
              { key: 'amount', label: 'Amount', render: (row) => currency(row.amount) },
              { key: 'status', label: 'Status', render: (row) => <StatusChip value={row.status} /> },
              { key: 'created_at', label: 'Created', render: (row) => formatDate(row.created_at) },
            ]}
          />
        </Grid>
        <Grid size={{ xs: 12, lg: 6 }}>
          <Section title="Daily Activity" />
          <AppDataTable
            loading={loading}
            rows={data?.daily_events || []}
            columns={[
              { key: 'activity_date', label: 'Date', render: (row) => formatDate(row.activity_date) },
              { key: 'activity_type', label: 'Type' },
              { key: 'activity_key', label: 'Key' },
              { key: 'estimated_minutes', label: 'Minutes' },
            ]}
          />
        </Grid>
      </Grid>
    </>
  )
}

function InfoCard({ title, children }) {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Stack spacing={1.4}>
          <Typography variant="h6">{title}</Typography>
          {children}
        </Stack>
      </CardContent>
    </Card>
  )
}

function Info({ label, value }) {
  return (
    <Stack spacing={0.2}>
      <Typography variant="caption" color="text.secondary" fontWeight={700}>
        {label}
      </Typography>
      <Typography fontWeight={700}>{value || '-'}</Typography>
    </Stack>
  )
}

function Section({ title }) {
  return (
    <Typography variant="h6" sx={{ mb: 1.5 }}>
      {title}
    </Typography>
  )
}
