import { VisibilityRounded } from '@mui/icons-material'
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Stack,
  Typography,
} from '@mui/material'
import { useCallback, useState } from 'react'
import AppDataTable from '../components/AppDataTable'
import PageHeader from '../components/PageHeader'
import DataToolbar from '../components/DataToolbar'
import { adminApi, humanize } from '../services/adminApi'
import { formatDateTime } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
const parse = (v) => (typeof v === 'string' ? JSON.parse(v) : v)
export default function AuditPage() {
  const [search, setSearch] = useState(''),
    [page, setPage] = useState(1),
    [limit, setLimit] = useState(25),
    [detail, setDetail] = useState(null)
  const query = useDebouncedValue(search)
  const load = useCallback(
    () => adminApi.audit({ page, limit, search: query }),
    [page, limit, query],
  )
  const { data, loading, error, reload } = useAsyncData(load)
  return (
    <>
      <PageHeader
        title="Audit history"
        subtitle="Review who changed data, what changed and why. History starts when auditing is enabled."
      />
      <DataToolbar
        search={search}
        onSearch={(v) => {
          setSearch(v)
          setPage(1)
        }}
        placeholder="Search admin, action, record ID or reason"
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
        onLimitChange={(v) => {
          setLimit(v)
          setPage(1)
        }}
        emptyMessage="No changes recorded yet"
        columns={[
          {
            key: 'created_at',
            label: 'When',
            minWidth: 180,
            render: (r) => formatDateTime(r.created_at),
          },
          {
            key: 'admin_name',
            label: 'Administrator',
            minWidth: 200,
            render: (r) => (
              <Stack>
                <Typography fontWeight={600}>{r.admin_name}</Typography>
                <Typography variant="caption" color="text.secondary">
                  {r.admin_email}
                </Typography>
              </Stack>
            ),
          },
          { key: 'action', label: 'Action', render: (r) => humanize(r.action) },
          {
            key: 'entity',
            label: 'Record',
            render: (r) => `${humanize(r.entity)} #${r.entity_id || '—'}`,
          },
          { key: 'reason', label: 'Reason', minWidth: 240 },
        ]}
        actions={[
          {
            label: 'View changes',
            showLabel: true,
            icon: <VisibilityRounded />,
            onClick: setDetail,
          },
        ]}
      />
      <Dialog
        open={Boolean(detail)}
        onClose={() => setDetail(null)}
        fullWidth
        maxWidth="md"
      >
        <DialogTitle>Change details</DialogTitle>
        <DialogContent dividers>
          {detail && (
            <Stack spacing={2}>
              <Typography>
                {humanize(detail.action)} · {humanize(detail.entity)} #
                {detail.entity_id} · {formatDateTime(detail.created_at)}
              </Typography>
              {detail.reason && <Typography>{detail.reason}</Typography>}
              <AppDataTable
                rows={changes(detail)}
                columns={[
                  { key: 'field', label: 'Field', minWidth: 160 },
                  { key: 'before', label: 'Before', minWidth: 220 },
                  { key: 'after', label: 'After', minWidth: 220 },
                ]}
                emptyMessage="No field differences"
              />
              <Box component="details">
                <Box component="summary" sx={{ cursor: 'pointer', py: 1 }}>
                  View full snapshots
                </Box>
                <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
                  {[
                    ['Before', detail.before_data],
                    ['After', detail.after_data],
                  ].map(([label, value]) => (
                    <Box key={label} sx={{ flex: 1, minWidth: 0 }}>
                      <Typography variant="subtitle2">{label}</Typography>
                      <Box
                        component="pre"
                        sx={{
                          fontSize: 12,
                          whiteSpace: 'pre-wrap',
                          overflowWrap: 'anywhere',
                          bgcolor: 'action.hover',
                          p: 2,
                          borderRadius: 2,
                          maxHeight: 440,
                          overflow: 'auto',
                        }}
                      >
                        {JSON.stringify(parse(value), null, 2)}
                      </Box>
                    </Box>
                  ))}
                </Stack>
              </Box>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetail(null)}>Close</Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

function changes(detail) {
  const normalize = (value) => {
    const parsed = parse(value)
    return parsed?.group || parsed || {}
  }
  const before = normalize(detail.before_data),
    after = normalize(detail.after_data)
  const display = (key, value) =>
    value == null
      ? '—'
      : key === 'is_blocked'
        ? value
          ? 'Blocked'
          : 'Active'
        : typeof value === 'object'
          ? JSON.stringify(value)
          : String(value)
  return [...new Set([...Object.keys(before), ...Object.keys(after)])]
    .filter((k) => JSON.stringify(before[k]) !== JSON.stringify(after[k]))
    .map((key) => ({
      id: key,
      field: humanize(key),
      before: display(key, before[key]),
      after: display(key, after[key]),
    }))
}
