import {
  AddRounded,
  DeleteRounded,
  EditRounded,
  FilterAltOutlined,
  SearchRounded,
  VisibilityRounded,
} from '@mui/icons-material'
import {
  Avatar,
  Box,
  Button,
  CircularProgress,
  IconButton,
  InputAdornment,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material'
import { useCallback, useMemo, useState } from 'react'
import toast from 'react-hot-toast'
import { useNavigate } from 'react-router-dom'
import ConfirmDialog from '../components/ConfirmDialog'
import { adminApi } from '../services/adminApi'
import { currency, formatDate, number } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'

const statusFilters = [
  { value: '', label: 'All Users' },
  { value: 'active', label: 'Active', dot: '#55B778' },
  { value: 'inactive', label: 'Inactive', dot: '#A8AEBB' },
]

export default function UsersPage() {
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [editing, setEditing] = useState(null)
  const [deleting, setDeleting] = useState(null)
  const [saving, setSaving] = useState(false)
  const loadUsers = useCallback(
    () => adminApi.users({ page, limit, search, status }),
    [page, limit, search, status],
  )
  const { data, loading, reload } = useAsyncData(loadUsers)
  const rows = data?.items || []
  const total = data?.total || 0
  const tablePage = data?.page || page
  const tableLimit = data?.limit || limit
  const showingFrom = total ? (tablePage - 1) * tableLimit + 1 : 0
  const showingTo = Math.min(tablePage * tableLimit, total)
  const filterLabel = useMemo(
    () => statusFilters.find((item) => item.value === status)?.label || 'All Users',
    [status],
  )

  const updateUser = async () => {
    setSaving(true)
    try {
      await adminApi.updateUser(editing.id, editing)
      toast.success('User updated')
      setEditing(null)
      reload()
    } finally {
      setSaving(false)
    }
  }

  const deleteUser = async () => {
    setSaving(true)
    try {
      await adminApi.deleteUser(deleting.id)
      toast.success('User deleted')
      setDeleting(null)
      reload()
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <Stack spacing={3}>
        <Stack
          direction={{ xs: 'column', sm: 'row' }}
          spacing={2}
          sx={{ justifyContent: 'space-between', alignItems: { xs: 'stretch', sm: 'flex-start' } }}
        >
          <Box>
            <Typography variant="h3" sx={{ fontSize: { xs: 30, md: 36 }, lineHeight: 1.05 }}>
              Users
            </Typography>
            <Typography color="text.secondary" sx={{ mt: 1, maxWidth: 680 }}>
              View students, accounts, plan status, learning setup, and engagement signals.
            </Typography>
          </Box>
          <Button
            variant="contained"
            startIcon={<AddRounded />}
            onClick={() => toast('User creation is not connected yet.')}
            sx={{ minWidth: 142, alignSelf: { xs: 'stretch', sm: 'center' } }}
          >
            Add User
          </Button>
        </Stack>

        <Paper
          variant="outlined"
          sx={{
            overflow: 'hidden',
            borderColor: 'divider',
            boxShadow: (theme) =>
              theme.palette.mode === 'dark'
                ? '0 18px 44px rgba(0,0,0,0.24)'
                : '0 22px 60px rgba(64, 52, 92, 0.10)',
          }}
        >
          <Stack
            direction={{ xs: 'column', lg: 'row' }}
            spacing={1.5}
            sx={{ p: 2, alignItems: { xs: 'stretch', lg: 'center' } }}
          >
            <TextField
              value={search}
              onChange={(event) => {
                setSearch(event.target.value)
                setPage(1)
              }}
              placeholder="Search by name, email, or mobile"
              size="small"
              fullWidth
              slotProps={{
                input: {
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchRounded fontSize="small" />
                    </InputAdornment>
                  ),
                },
              }}
              sx={{
                flex: 1,
                '& .MuiOutlinedInput-root': {
                  minHeight: 46,
                  borderRadius: 1.5,
                },
              }}
            />
            <Stack direction="row" spacing={1} sx={{ flexWrap: 'wrap', rowGap: 1 }}>
              {statusFilters.map((filter) => (
                <Button
                  key={filter.label}
                  variant="outlined"
                  onClick={() => {
                    setStatus(filter.value)
                    setPage(1)
                  }}
                  startIcon={
                    filter.dot ? (
                      <Box
                        component="span"
                        sx={{
                          width: 8,
                          height: 8,
                          borderRadius: '50%',
                          bgcolor: filter.dot,
                        }}
                      />
                    ) : null
                  }
                  sx={{
                    minHeight: 46,
                    px: 2,
                    borderColor: status === filter.value ? 'primary.main' : 'divider',
                    bgcolor: (theme) =>
                      status === filter.value
                        ? theme.palette.mode === 'dark'
                          ? 'rgba(142,92,230,0.14)'
                          : '#FBF8FF'
                        : 'transparent',
                  }}
                >
                  {filter.label}
                </Button>
              ))}
              <Button
                variant="outlined"
                startIcon={<FilterAltOutlined />}
                onClick={() => toast(`${filterLabel} filter applied`)}
                sx={{ minHeight: 46, px: 2, borderColor: 'divider', color: 'text.primary' }}
              >
                Filters
              </Button>
            </Stack>
          </Stack>

          <TableContainer sx={{ minHeight: loading ? 360 : 0 }}>
            <Table sx={{ minWidth: 1080 }}>
              <TableHead>
                <TableRow
                  sx={{
                    '& th': {
                      bgcolor: (theme) =>
                        theme.palette.mode === 'dark' ? '#211E2C' : '#F4F1FA',
                      color: 'text.primary',
                      fontSize: 13,
                      fontWeight: 800,
                      py: 2,
                    },
                  }}
                >
                  <TableCell>Student</TableCell>
                  <TableCell>School</TableCell>
                  <TableCell>Language</TableCell>
                  <TableCell>Level</TableCell>
                  <TableCell>Plan</TableCell>
                  <TableCell align="center">Completed</TableCell>
                  <TableCell>Spend</TableCell>
                  <TableCell>Joined</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={9}>
                      <Stack sx={{ py: 8, alignItems: 'center' }}>
                        <CircularProgress size={32} />
                      </Stack>
                    </TableCell>
                  </TableRow>
                ) : rows.length ? (
                  rows.map((row, index) => (
                    <TableRow
                      hover
                      key={row.id}
                      sx={{
                        '& td': {
                          py: 2.1,
                          borderColor: 'divider',
                        },
                      }}
                    >
                      <TableCell>
                        <Stack direction="row" spacing={1.5} sx={{ alignItems: 'center' }}>
                          <Avatar sx={avatarSx(index, row.full_name)}>
                            {initials(row.full_name)}
                          </Avatar>
                          <Box sx={{ minWidth: 0 }}>
                            <Typography fontWeight={800} noWrap>
                              {row.full_name || 'Unnamed student'}
                            </Typography>
                            <Typography variant="caption" color="text.secondary" noWrap>
                              {row.email || row.mobile_number || '-'}
                            </Typography>
                          </Box>
                        </Stack>
                      </TableCell>
                      <TableCell>{safeText(row.school)}</TableCell>
                      <TableCell>{safeText(row.learning_language)}</TableCell>
                      <TableCell>{safeText(row.level)}</TableCell>
                      <TableCell>
                        <Stack spacing={0.7} sx={{ alignItems: 'flex-start' }}>
                          <PlanPill active={row.subscription_status === 'active'} />
                          <Typography variant="caption" color="text.secondary">
                            {row.plan_name || 'Free Trial'}
                          </Typography>
                        </Stack>
                      </TableCell>
                      <TableCell align="center">{number(row.completed_count)}</TableCell>
                      <TableCell>{currency(row.total_spent)}</TableCell>
                      <TableCell>{formatDate(row.created_at)}</TableCell>
                      <TableCell align="right">
                        <Stack direction="row" spacing={0.75} sx={{ justifyContent: 'flex-end' }}>
                          <ActionButton label="View" onClick={() => navigate(`/users/${row.id}`)}>
                            <VisibilityRounded fontSize="small" />
                          </ActionButton>
                          <ActionButton label="Edit" onClick={() => setEditing(row)}>
                            <EditRounded fontSize="small" />
                          </ActionButton>
                          <ActionButton
                            label="Delete"
                            color="error.main"
                            onClick={() => setDeleting(row)}
                          >
                            <DeleteRounded fontSize="small" />
                          </ActionButton>
                        </Stack>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={9}>
                      <Box sx={{ py: 8, textAlign: 'center' }}>
                        <Typography fontWeight={800}>No users found</Typography>
                        <Typography color="text.secondary" variant="body2">
                          Try another search or status filter.
                        </Typography>
                      </Box>
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>

          <TablePagination
            component="div"
            count={total}
            page={Math.max(tablePage - 1, 0)}
            rowsPerPage={tableLimit}
            labelDisplayedRows={() => `${showingFrom}-${showingTo} of ${total}`}
            onPageChange={(_, nextPage) => setPage(nextPage + 1)}
            onRowsPerPageChange={(event) => {
              setLimit(Number(event.target.value))
              setPage(1)
            }}
            rowsPerPageOptions={[10, 25, 50, 100]}
          />
        </Paper>
      </Stack>

      {editing ? (
        <ConfirmEdit
          user={editing}
          saving={saving}
          onChange={setEditing}
          onClose={() => setEditing(null)}
          onSave={updateUser}
        />
      ) : null}
      <ConfirmDialog
        open={Boolean(deleting)}
        title="Delete user"
        body={`Delete ${deleting?.full_name || 'this user'} and all linked progress, OTPs, subscriptions, and notifications?`}
        confirmLabel="Delete"
        loading={saving}
        onClose={() => setDeleting(null)}
        onConfirm={deleteUser}
      />
    </>
  )
}

function PlanPill({ active }) {
  return (
    <Box
      component="span"
      sx={{
        display: 'inline-flex',
        justifyContent: 'center',
        minWidth: 96,
        px: 1.5,
        py: 0.45,
        borderRadius: 1.2,
        bgcolor: active ? '#4FB878' : '#E8E8EA',
        color: active ? '#FFFFFF' : '#171923',
        fontSize: 13,
        fontWeight: 800,
        lineHeight: 1.25,
      }}
    >
      {active ? 'Active' : 'Free'}
    </Box>
  )
}

function ActionButton({ label, color = 'text.secondary', onClick, children }) {
  return (
    <Tooltip title={label}>
      <IconButton
        size="small"
        onClick={onClick}
        sx={{
          width: 34,
          height: 34,
          color,
          '&:hover': {
            bgcolor: (theme) =>
              theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : '#F4F1FA',
          },
        }}
      >
        {children}
      </IconButton>
    </Tooltip>
  )
}

function safeText(value) {
  if (value == null || value === '') return '-'
  return String(value)
}

function initials(name = '') {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  if (!parts.length) return 'U'
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase()
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase()
}

function avatarSx(index, name) {
  const palette = [
    { bg: '#DED0FF', color: '#754EE8' },
    { bg: '#CDEFD7', color: '#288A4F' },
    { bg: '#FFE9B8', color: '#D78116' },
    { bg: '#D9CDFF', color: '#7355E9' },
    { bg: '#D8ECFF', color: '#2578B8' },
  ]
  const picked = palette[(name?.length || index) % palette.length]
  return {
    width: 42,
    height: 42,
    bgcolor: picked.bg,
    color: picked.color,
    fontSize: 14,
    fontWeight: 800,
  }
}

function ConfirmEdit({ user, saving, onChange, onClose, onSave }) {
  return (
    <ConfirmDialog
      open
      title="Edit user profile"
      body={
        <Stack spacing={1.5} sx={{ pt: 1 }}>
          {['full_name', 'email', 'school', 'city', 'state'].map((field) => (
            <TextField
              key={field}
              size="small"
              label={field.replace(/_/g, ' ')}
              value={user[field] || ''}
              onChange={(event) => onChange({ ...user, [field]: event.target.value })}
              fullWidth
            />
          ))}
        </Stack>
      }
      confirmLabel="Save"
      loading={saving}
      onClose={onClose}
      onConfirm={onSave}
    />
  )
}
