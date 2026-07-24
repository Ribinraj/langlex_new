import { Stack, Typography } from '@mui/material'
import { useCallback, useState } from 'react'
import AppDataTable from '../components/AppDataTable'
import DataToolbar from '../components/DataToolbar'
import PageHeader from '../components/PageHeader'
import StatusChip from '../components/StatusChip'
import { adminApi } from '../services/adminApi'
import { currency, formatDateTime } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'

export default function SubscriptionsPage() {
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const loadSubscriptions = useCallback(
    () => adminApi.subscriptions({ page, limit, search, status }),
    [page, limit, search, status],
  )
  const { data, loading } = useAsyncData(loadSubscriptions)

  return (
    <>
      <PageHeader
        title="Subscriptions"
        subtitle="Monitor active, expired, and historical plan access for student accounts."
      />
      <DataToolbar
        search={search}
        onSearch={(value) => {
          setSearch(value)
          setPage(1)
        }}
        placeholder="Search user, mobile, plan"
        filters={[
          {
            name: 'status',
            label: 'Status',
            value: status,
            onChange: (value) => {
              setStatus(value)
              setPage(1)
            },
            options: ['active', 'expired', 'cancelled'],
          },
        ]}
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
            key: 'full_name',
            label: 'User',
            minWidth: 210,
            render: (row) => (
              <Stack>
                <Typography fontWeight={700}>{row.full_name}</Typography>
                <Typography variant="caption" color="text.secondary">
                  {row.mobile_number}
                </Typography>
              </Stack>
            ),
          },
          { key: 'plan_name', label: 'Plan', minWidth: 170 },
          { key: 'amount', label: 'Amount', render: (row) => currency(row.amount) },
          { key: 'plan_timeperiod', label: 'Period' },
          { key: 'status', label: 'Status', render: (row) => <StatusChip value={row.status} /> },
          { key: 'started_at', label: 'Started', minWidth: 170, render: (row) => formatDateTime(row.started_at) },
          { key: 'expires_at', label: 'Expires', minWidth: 170, render: (row) => formatDateTime(row.expires_at) },
        ]}
      />
    </>
  )
}
