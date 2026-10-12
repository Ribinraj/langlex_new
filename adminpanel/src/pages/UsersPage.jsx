import {
  ManageAccountsRounded,
  DeleteRounded,
  EditRounded,
  VisibilityRounded,
} from '@mui/icons-material'
import { Avatar, Stack, TextField, Typography } from '@mui/material'
import { useCallback, useState } from 'react'
import toast from 'react-hot-toast'
import { useNavigate } from 'react-router-dom'
import AppDataTable from '../components/AppDataTable'
import ConfirmDialog from '../components/ConfirmDialog'
import DataToolbar from '../components/DataToolbar'
import PageHeader from '../components/PageHeader'
import StatusChip from '../components/StatusChip'
import { adminApi, humanize } from '../services/adminApi'
import { currency, formatDate, number } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import AccountAccessDialog from '../components/AccountAccessDialog'
const fields = ['full_name', 'email', 'school', 'city', 'state']
export default function UsersPage() {
  const navigate = useNavigate()
  const [accessUser, setAccessUser] = useState(null)
  const [account, setAccount] = useState('')
  const [search, setSearch] = useState(''),
    [status, setStatus] = useState('')
  const [page, setPage] = useState(1),
    [limit, setLimit] = useState(10)
  const [editing, setEditing] = useState(null),
    [deleting, setDeleting] = useState(null),
    [saving, setSaving] = useState(false)
  const [formError, setFormError] = useState('')
  const query = useDebouncedValue(search)
  const load = useCallback(
    () => adminApi.users({ page, limit, search: query, status, account }),
    [page, limit, query, status, account],
  )
  const { data, loading, error, reload } = useAsyncData(load)
  const save = async () => {
    if ((editing.full_name || '').trim().length < 2) {
      setFormError('Enter a name with at least 2 characters.')
      return
    }
    if (
      editing.email &&
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(editing.email.trim())
    ) {
      setFormError('Enter a valid email address.')
      return
    }
    setSaving(true)
    try {
      await adminApi.updateUser(
        editing.id,
        Object.fromEntries(
          fields.map((field) => [field, String(editing[field] || '').trim()]),
        ),
      )
      toast.success('Profile updated')
      setEditing(null)
      reload()
    } catch {
      /* Keep the edited values; API displays the failure. */
    } finally {
      setSaving(false)
    }
  }
  const remove = async () => {
    setSaving(true)
    try {
      await adminApi.deleteUser(deleting.id)
      toast.success('User deleted')
      setDeleting(null)
      reload()
    } catch {
      /* Keep the dialog open so the user can retry. */
    } finally {
      setSaving(false)
    }
  }
  return (
    <>
      <PageHeader
        title="Users"
        subtitle="Manage learner accounts, subscriptions and learning activity. New learners register through the app."
      />
      <DataToolbar
        search={search}
        onSearch={(value) => {
          setSearch(value)
          setPage(1)
        }}
        placeholder="Search name, email, mobile or school"
        filters={[
          {
            name: 'account',
            label: 'Account',
            value: account,
            onChange: (v) => {
              setAccount(v)
              setPage(1)
            },
            options: [
              { value: 'active', label: 'Active accounts' },
              { value: 'blocked', label: 'Blocked accounts' },
            ],
          },
          {
            name: 'subscription',
            label: 'Subscription',
            value: status,
            onChange: (value) => {
              setStatus(value)
              setPage(1)
            },
            options: [
              { value: 'active', label: 'Active subscription' },
              { value: 'inactive', label: 'No active subscription' },
            ],
          },
        ]}
      />
      <AppDataTable
        rows={data?.items || []}
        loading={loading}
        error={error}
        onRetry={reload}
        page={page}
        limit={limit}
        total={data?.total || 0}
        onPageChange={setPage}
        onLimitChange={(value) => {
          setLimit(value)
          setPage(1)
        }}
        emptyMessage="No learners found"
        columns={[
          {
            key: 'full_name',
            label: 'Learner',
            minWidth: 240,
            render: (row) => (
              <Stack
                direction="row"
                spacing={1.5}
                sx={{ alignItems: 'center' }}
              >
                <Avatar
                  sx={{
                    width: 36,
                    height: 36,
                    bgcolor: 'action.selected',
                    color: 'primary.main',
                    fontSize: 13,
                  }}
                >
                  {row.full_name?.[0] || 'U'}
                </Avatar>
                <Stack sx={{ minWidth: 0 }}>
                  <Typography variant="body2" fontWeight={600}>
                    {row.full_name || 'Unnamed learner'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {row.email || row.mobile_number}
                  </Typography>
                </Stack>
              </Stack>
            ),
          },
          {
            key: 'is_blocked',
            label: 'Account',
            render: (row) => (
              <StatusChip value={row.is_blocked ? 'blocked' : 'active'} />
            ),
          },
          { key: 'school', label: 'School', minWidth: 140 },
          { key: 'learning_language', label: 'Language' },
          { key: 'level', label: 'Level' },
          {
            key: 'plan_name',
            label: 'Subscription',
            minWidth: 170,
            render: (row) => (
              <Stack spacing={0.5} sx={{ alignItems: 'flex-start' }}>
                <StatusChip
                  value={
                    row.subscription_status === 'active' ? 'active' : 'free'
                  }
                />
                <Typography variant="caption" color="text.secondary">
                  {row.plan_name || 'Free access'}
                </Typography>
              </Stack>
            ),
          },
          {
            key: 'completed_count',
            label: 'Completed sessions',
            render: (row) => number(row.completed_count),
          },
          {
            key: 'total_spent',
            label: 'Paid total',
            render: (row) => currency(row.total_spent),
          },
          {
            key: 'created_at',
            label: 'Joined',
            minWidth: 130,
            render: (row) => formatDate(row.created_at),
          },
        ]}
        actions={[
          {
            label: 'Manage access',
            icon: <ManageAccountsRounded />,
            onClick: setAccessUser,
          },
          {
            label: 'View',
            icon: <VisibilityRounded fontSize="small" />,
            onClick: (row) => navigate(`/users/${row.id}`),
          },
          {
            label: 'Edit',
            icon: <EditRounded fontSize="small" />,
            onClick: (row) => {
              setFormError('')
              setEditing(row)
            },
          },
          {
            label: 'Delete',
            color: 'error',
            icon: <DeleteRounded fontSize="small" />,
            onClick: setDeleting,
          },
        ]}
      />
      {accessUser && (
        <AccountAccessDialog
          user={accessUser}
          onClose={() => setAccessUser(null)}
          onSaved={reload}
        />
      )}
      <ConfirmDialog
        open={Boolean(editing)}
        title="Edit learner profile"
        confirmLabel="Save changes"
        confirmColor="primary"
        loading={saving}
        onClose={() => setEditing(null)}
        onConfirm={save}
        body={
          <Stack spacing={2} sx={{ pt: 1 }}>
            {formError && (
              <Typography role="alert" color="error">
                {formError}
              </Typography>
            )}
            {fields.map((field) => (
              <TextField
                key={field}
                label={humanize(field)}
                value={editing?.[field] || ''}
                type={field === 'email' ? 'email' : 'text'}
                required={field === 'full_name'}
                slotProps={{
                  htmlInput: {
                    maxLength:
                      field === 'school' ? 160 : field === 'email' ? 254 : 120,
                  },
                }}
                onChange={(event) =>
                  setEditing({ ...editing, [field]: event.target.value })
                }
              />
            ))}
          </Stack>
        }
      />
      <ConfirmDialog
        open={Boolean(deleting)}
        title="Delete learner account?"
        body={`Permanently delete ${deleting?.full_name || 'this learner'} and their linked progress, payments, subscriptions and notifications? This cannot be undone.`}
        confirmLabel="Delete account"
        loading={saving}
        onClose={() => setDeleting(null)}
        onConfirm={remove}
      />
    </>
  )
}
