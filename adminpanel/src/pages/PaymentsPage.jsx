import { Stack, Typography } from '@mui/material'
import { useCallback, useState } from 'react'
import AppDataTable from '../components/AppDataTable'
import DataToolbar from '../components/DataToolbar'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import PageHeader from '../components/PageHeader'
import StatusChip from '../components/StatusChip'
import { adminApi } from '../services/adminApi'
import { currency, formatDateTime } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'

export default function PaymentsPage() {
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const query = useDebouncedValue(search)
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const loadPayments = useCallback(
    () => adminApi.payments({ page, limit, search: query, status }),
    [page, limit, query, status],
  )
  const { data, loading, error, reload } = useAsyncData(loadPayments)

  return (
    <>
      <PageHeader
        title="Payments"
        subtitle="Review payment orders, amounts and payment status."
      />
      <DataToolbar
        search={search}
        onSearch={(value) => {
          setSearch(value)
          setPage(1)
        }}
        placeholder="Search user, mobile, order, plan"
        filters={[
          {
            name: 'status',
            label: 'Status',
            value: status,
            onChange: (value) => {
              setStatus(value)
              setPage(1)
            },
            options: ['created', 'paid', 'failed'],
          },
        ]}
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
          {
            key: 'provider',
            label: 'Provider',
            render: (row) =>
              row.provider === 'dummy' ? 'Test (dummy)' : row.provider,
          },
          { key: 'provider_order_id', label: 'Provider Order', minWidth: 250 },
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
            minWidth: 170,
            render: (row) => formatDateTime(row.created_at),
          },
          {
            key: 'updated_at',
            label: 'Updated',
            minWidth: 170,
            render: (row) => formatDateTime(row.updated_at),
          },
        ]}
      />
    </>
  )
}
