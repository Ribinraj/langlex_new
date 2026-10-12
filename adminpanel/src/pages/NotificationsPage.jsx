import { SendRounded } from '@mui/icons-material'
import {
  Button,
  Card,
  CardContent,
  Checkbox,
  FormControlLabel,
  Grid,
  MenuItem,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useCallback, useState } from 'react'
import toast from 'react-hot-toast'
import AppDataTable from '../components/AppDataTable'
import DataToolbar from '../components/DataToolbar'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import PageHeader from '../components/PageHeader'
import StatusChip from '../components/StatusChip'
import { adminApi } from '../services/adminApi'
import { formatDateTime } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'

const initialForm = {
  userId: '',
  broadcast: false,
  title: '',
  body: '',
  type: 'info',
  action: 'open_notifications',
}

export default function NotificationsPage() {
  const [search, setSearch] = useState('')
  const query = useDebouncedValue(search)
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [form, setForm] = useState(initialForm)
  const [saving, setSaving] = useState(false)
  const loadNotifications = useCallback(
    () => adminApi.notifications({ page, limit, search: query }),
    [page, limit, query],
  )
  const { data, loading, error, reload } = useAsyncData(loadNotifications)

  const submit = async (event) => {
    event.preventDefault()
    if (
      !form.broadcast &&
      (!Number.isInteger(Number(form.userId)) || Number(form.userId) <= 0)
    ) {
      toast.error('Enter a valid learner ID.')
      return
    }
    if (form.title.trim().length < 2 || form.body.trim().length < 2) {
      toast.error('Title and message must have at least 2 characters.')
      return
    }
    setSaving(true)
    try {
      const payload = {
        ...form,
        userId: form.broadcast || !form.userId ? null : Number(form.userId),
        data: { action: form.action },
      }
      const result = await adminApi.sendNotification(payload)
      const push = result.push
      const pushText = push?.enabled
        ? `Push delivered to ${push.success}/${push.requested} devices`
        : 'Inbox saved; Firebase push is not configured'
      toast.success(
        form.broadcast
          ? `Notification saved for ${result.sent} users. ${pushText}`
          : `Notification saved. ${pushText}`,
      )
      setForm(initialForm)
      reload()
    } catch {
      // The API interceptor displays the server error; preserve the form for retry.
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <PageHeader
        title="Notifications"
        subtitle="Review notification history and send targeted or broadcast messages into the mobile app inbox."
      />

      <Grid container spacing={2.2}>
        <Grid size={{ xs: 12, lg: 4 }}>
          <Card>
            <CardContent>
              <Stack component="form" spacing={2} onSubmit={submit}>
                <Typography variant="h6">Compose Notification</Typography>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={form.broadcast}
                      onChange={(event) =>
                        setForm({ ...form, broadcast: event.target.checked })
                      }
                    />
                  }
                  label="Broadcast to all users"
                />
                {!form.broadcast ? (
                  <TextField
                    label="User ID"
                    type="number"
                    slotProps={{ htmlInput: { min: 1, step: 1 } }}
                    value={form.userId}
                    onChange={(event) =>
                      setForm({ ...form, userId: event.target.value })
                    }
                    required
                  />
                ) : null}
                <TextField
                  label="Type"
                  select
                  value={form.type}
                  onChange={(event) =>
                    setForm({ ...form, type: event.target.value })
                  }
                >
                  {[
                    'info',
                    'welcome',
                    'setup',
                    'practice',
                    'billing',
                    'alert',
                  ].map((item) => (
                    <MenuItem key={item} value={item}>
                      {item}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  label="Tap Action"
                  select
                  value={form.action}
                  onChange={(event) =>
                    setForm({ ...form, action: event.target.value })
                  }
                >
                  {[
                    {
                      value: 'open_notifications',
                      label: 'Open notifications',
                    },
                    { value: 'open_learn', label: 'Open learn' },
                    { value: 'open_quiz', label: 'Open quiz' },
                    {
                      value: 'open_learning_setup',
                      label: 'Open learning setup',
                    },
                  ].map((item) => (
                    <MenuItem key={item.value} value={item.value}>
                      {item.label}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  label="Title"
                  slotProps={{ htmlInput: { maxLength: 160 } }}
                  value={form.title}
                  onChange={(event) =>
                    setForm({ ...form, title: event.target.value })
                  }
                  required
                />
                <TextField
                  label="Message"
                  slotProps={{ htmlInput: { maxLength: 500 } }}
                  value={form.body}
                  onChange={(event) =>
                    setForm({ ...form, body: event.target.value })
                  }
                  multiline
                  minRows={4}
                  required
                />
                <Button
                  type="submit"
                  variant="contained"
                  startIcon={<SendRounded />}
                  disabled={saving}
                >
                  {saving
                    ? 'Sending…'
                    : form.broadcast
                      ? 'Send to all learners'
                      : 'Send notification'}
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, lg: 8 }}>
          <DataToolbar
            search={search}
            onSearch={(value) => {
              setSearch(value)
              setPage(1)
            }}
            placeholder="Search title, body, user"
          />
          <AppDataTable
            error={error}
            onRetry={reload}
            loading={loading}
            rows={data?.items || []}
            page={data?.page || page}
            limit={data?.limit || limit}
            total={data?.total || 0}
            onPageChange={setPage}
            onLimitChange={(value) => {
              setLimit(value)
              setPage(1)
            }}
            columns={[
              {
                key: 'title',
                label: 'Notification',
                minWidth: 280,
                render: (row) => (
                  <Stack>
                    <Typography fontWeight={700}>{row.title}</Typography>
                    <Typography variant="caption" color="text.secondary" noWrap>
                      {row.body}
                    </Typography>
                  </Stack>
                ),
              },
              {
                key: 'type',
                label: 'Type',
                render: (row) => <StatusChip value={row.type} />,
              },
              {
                key: 'full_name',
                label: 'User',
                render: (row) => row.full_name || 'Broadcast/Unknown',
              },
              {
                key: 'is_read',
                label: 'Read',
                render: (row) => (
                  <StatusChip value={row.is_read ? 'read' : 'unread'} />
                ),
              },
              {
                key: 'created_at',
                label: 'Created',
                minWidth: 170,
                render: (row) => formatDateTime(row.created_at),
              },
            ]}
          />
        </Grid>
      </Grid>
    </>
  )
}
