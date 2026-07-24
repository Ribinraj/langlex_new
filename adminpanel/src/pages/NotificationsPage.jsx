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
import PageHeader from '../components/PageHeader'
import StatusChip from '../components/StatusChip'
import { adminApi } from '../services/adminApi'
import { formatDateTime } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'

const initialForm = {
  userId: '',
  broadcast: true,
  title: '',
  body: '',
  type: 'info',
}

export default function NotificationsPage() {
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [form, setForm] = useState(initialForm)
  const [saving, setSaving] = useState(false)
  const loadNotifications = useCallback(
    () => adminApi.notifications({ page, limit, search }),
    [page, limit, search],
  )
  const { data, loading, reload } = useAsyncData(loadNotifications)

  const submit = async (event) => {
    event.preventDefault()
    setSaving(true)
    try {
      const payload = {
        ...form,
        userId: form.broadcast || !form.userId ? null : Number(form.userId),
      }
      const result = await adminApi.sendNotification(payload)
      toast.success(form.broadcast ? `Notification sent to ${result.sent} users` : 'Notification sent')
      setForm(initialForm)
      reload()
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
                      onChange={(event) => setForm({ ...form, broadcast: event.target.checked })}
                    />
                  }
                  label="Broadcast to all users"
                />
                {!form.broadcast ? (
                  <TextField
                    label="User ID"
                    value={form.userId}
                    onChange={(event) => setForm({ ...form, userId: event.target.value })}
                    required
                  />
                ) : null}
                <TextField
                  label="Type"
                  select
                  value={form.type}
                  onChange={(event) => setForm({ ...form, type: event.target.value })}
                >
                  {['info', 'welcome', 'setup', 'practice', 'billing', 'alert'].map((item) => (
                    <MenuItem key={item} value={item}>
                      {item}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  label="Title"
                  value={form.title}
                  onChange={(event) => setForm({ ...form, title: event.target.value })}
                  required
                />
                <TextField
                  label="Body"
                  value={form.body}
                  onChange={(event) => setForm({ ...form, body: event.target.value })}
                  multiline
                  minRows={4}
                  required
                />
                <Button type="submit" variant="contained" startIcon={<SendRounded />} disabled={saving}>
                  {saving ? 'Sending...' : 'Send'}
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
              { key: 'type', label: 'Type', render: (row) => <StatusChip value={row.type} /> },
              { key: 'full_name', label: 'User', render: (row) => row.full_name || 'Broadcast/Unknown' },
              { key: 'is_read', label: 'Read', render: (row) => <StatusChip value={row.is_read ? 'read' : 'unread'} /> },
              { key: 'created_at', label: 'Created', minWidth: 170, render: (row) => formatDateTime(row.created_at) },
            ]}
          />
        </Grid>
      </Grid>
    </>
  )
}
