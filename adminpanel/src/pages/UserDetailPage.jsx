import { ArrowBackRounded } from '@mui/icons-material'
import {
  Button,
  Alert,
  Card,
  CardContent,
  Skeleton,
  Chip,
  Grid,
  Stack,
  Typography,
} from '@mui/material'
import { useCallback, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import AccountAccessDialog from '../components/AccountAccessDialog'
import SubscriptionDialog from '../components/SubscriptionDialog'
import LearnerProgress from '../components/LearnerProgress'
import AppDataTable from '../components/AppDataTable'
import EmptyState from '../components/EmptyState'
import PageHeader from '../components/PageHeader'
import StatusChip from '../components/StatusChip'
import { adminApi } from '../services/adminApi'
import { currency, formatDate, formatDateTime } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'

export default function UserDetailPage() {
  const { id } = useParams()
  const [accessOpen, setAccessOpen] = useState(false),
    [subscriptionAction, setSubscriptionAction] = useState(null)
  const navigate = useNavigate()
  const loadUser = useCallback(() => adminApi.user(id), [id])
  const { data, loading, error, reload } = useAsyncData(loadUser)
  const user = data?.user

  const currentSubscription = data?.subscriptions?.find(
    (item) =>
      item.status === 'active' &&
      new Date(item.started_at) <= new Date() &&
      (!item.expires_at || new Date(item.expires_at) > new Date()),
  )
  if (error)
    return (
      <>
        <PageHeader
          title="User details"
          action={{ label: 'Back to users', onClick: () => navigate('/users') }}
        />
        <Card>
          <EmptyState error={error} onRetry={reload} />
        </Card>
      </>
    )
  if (loading)
    return (
      <>
        <PageHeader title="User details" subtitle="Loading learner profile…" />
        <Skeleton variant="rounded" height={300} />
        <Skeleton variant="rounded" height={220} sx={{ mt: 3 }} />
      </>
    )

  return (
    <>
      <PageHeader
        title={user?.full_name || 'User Detail'}
        subtitle={
          user
            ? `${user.mobile_number} · ${user.email || 'No email'}`
            : 'Loading account'
        }
        action={{
          label: 'Back to users',
          onClick: () => navigate('/users'),
        }}
        actionIcon={<ArrowBackRounded />}
      />

      {accessOpen && (
        <AccountAccessDialog
          user={user}
          onClose={() => setAccessOpen(false)}
          onSaved={reload}
        />
      )}
      {subscriptionAction && (
        <SubscriptionDialog
          user={user}
          subscription={currentSubscription}
          action={subscriptionAction}
          onClose={() => setSubscriptionAction(null)}
          onSaved={reload}
        />
      )}
      {Boolean(user?.is_blocked) && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          Account blocked: {user.block_reason}
        </Alert>
      )}
      <Grid container spacing={2.2}>
        <Grid size={{ xs: 12, md: 4 }}>
          <InfoCard title="Profile">
            <StatusChip value={user?.is_blocked ? 'blocked' : 'active'} />
            <Button
              variant="outlined"
              color={user?.is_blocked ? 'primary' : 'error'}
              onClick={() => setAccessOpen(true)}
            >
              {user?.is_blocked ? 'Unblock account' : 'Block account'}
            </Button>
            <Info label="Name" value={user?.full_name} />
            <Info label="Mobile" value={user?.mobile_number} />
            <Info label="Email" value={user?.email} />
            <Info label="School" value={user?.school} />
            <Info
              label="Location"
              value={[user?.city, user?.state].filter(Boolean).join(', ')}
            />
            <Info label="Joined" value={formatDateTime(user?.created_at)} />
          </InfoCard>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <InfoCard title="Learning Setup">
            <Info label="Child name" value={data?.learning_setup?.child_name} />
            <Info
              label="Home language"
              value={data?.learning_setup?.primary_language}
            />
            <Info
              label="Learning language"
              value={data?.learning_setup?.learning_language}
            />
            <Info label="Level" value={data?.learning_setup?.level} />
            <Stack direction="row" spacing={0.8} sx={{ flexWrap: 'wrap' }}>
              {(data?.learning_setup?.interests || []).map((interest) => (
                <Chip key={interest} label={interest} size="small" />
              ))}
            </Stack>
          </InfoCard>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <InfoCard title="Current Subscription">
            <Button
              variant="contained"
              onClick={() => setSubscriptionAction('grant')}
            >
              Grant Premium access
            </Button>
            {currentSubscription && (
              <Stack direction="row" spacing={1} sx={{ flexWrap: 'wrap' }}>
                <Button onClick={() => setSubscriptionAction('change_expiry')}>
                  Change expiry
                </Button>
                <Button
                  color="error"
                  onClick={() => setSubscriptionAction('cancel')}
                >
                  Cancel subscription
                </Button>
              </Stack>
            )}
            {currentSubscription ? (
              <>
                <Info label="Plan" value={currentSubscription.plan_name} />
                <Info
                  label="Current plan price"
                  value={currency(currentSubscription.amount)}
                />
                <Info
                  label="Period"
                  value={currentSubscription.plan_timeperiod}
                />
                <StatusChip value={currentSubscription.status} />
                <Info
                  label="Expires"
                  value={formatDateTime(currentSubscription.expires_at)}
                />
              </>
            ) : (
              <Typography color="text.secondary">
                Free access, no active paid subscription.
              </Typography>
            )}
          </InfoCard>
        </Grid>

        <Grid size={{ xs: 12 }}>
          <LearnerProgress key={id} userId={id} />
        </Grid>
        <Grid size={{ xs: 12 }}>
          <Section title="Recent learning sessions (up to 50)" />
          <AppDataTable
            loading={loading}
            rows={data?.progress || []}
            emptyMessage="No learning sessions yet"
            emptyDescription="Lessons will appear here when this learner starts practicing."
            columns={[
              { key: 'content_type', label: 'Type' },
              { key: 'content_key', label: 'Key', minWidth: 180 },
              {
                key: 'status',
                label: 'Status',
                render: (row) => <StatusChip value={row.status} />,
              },
              { key: 'position', label: 'Position' },
              { key: 'total_items', label: 'Items' },
              { key: 'score', label: 'Score' },
              {
                key: 'updated_at',
                label: 'Updated',
                render: (row) => formatDateTime(row.updated_at),
              },
            ]}
          />
        </Grid>

        <Grid size={{ xs: 12 }}>
          <Section title="Payments" />
          <AppDataTable
            loading={loading}
            rows={data?.payments || []}
            emptyMessage="No payments yet"
            emptyDescription="Payment orders for this learner will appear here."
            columns={[
              { key: 'plan_name', label: 'Plan' },
              {
                key: 'amount',
                label: 'Amount',
                render: (row) => currency(row.amount),
              },
              {
                key: 'status',
                label: 'Status',
                render: (row) => <StatusChip value={row.status} />,
              },
              {
                key: 'created_at',
                label: 'Created',
                render: (row) => formatDate(row.created_at),
              },
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
