import { AddRounded, DeleteRounded, EditRounded } from '@mui/icons-material'
import { Box, Button, MenuItem, Stack, Tabs, Tab, TextField, Typography } from '@mui/material'
import { useCallback, useMemo, useState } from 'react'
import toast from 'react-hot-toast'
import { useNavigate, useParams } from 'react-router-dom'
import AppDataTable from '../components/AppDataTable'
import ConfirmDialog from '../components/ConfirmDialog'
import DataToolbar from '../components/DataToolbar'
import PageHeader from '../components/PageHeader'
import ResourceDialog from '../components/ResourceDialog'
import StatusChip from '../components/StatusChip'
import { adminApi, humanize, resourceLabels, resourceSchemas } from '../services/adminApi'
import { mediaUrl } from '../services/apiClient'
import { formatDate } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'

const resourceOrder = [
  'categories',
  'subcategories',
  'courses',
  'content',
  'alphabets',
  'quizzes',
  'phonics',
  'stories',
  'plans',
]

export default function ResourcePage() {
  const { resource = 'courses' } = useParams()
  const navigate = useNavigate()
  const safeResource = resourceSchemas[resource] ? resource : 'courses'
  const [search, setSearch] = useState('')
  const [language, setLanguage] = useState('')
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [editing, setEditing] = useState(null)
  const [deleting, setDeleting] = useState(null)
  const [saving, setSaving] = useState(false)
  const columns = resourceSchemas[safeResource]
  const loadResource = useCallback(
    () => adminApi.resource(safeResource, { page, limit, search, language }),
    [safeResource, page, limit, search, language],
  )
  const { data, loading, reload } = useAsyncData(loadResource)
  const loadReferenceData = useCallback(async () => {
    const [categories, subcategories, courses] = await Promise.all([
      adminApi.resource('categories', { limit: 100 }),
      adminApi.resource('subcategories', { limit: 100 }),
      adminApi.resource('courses', { limit: 100 }),
    ])

    return {
      categories: uniqueValues(categories.items, 'title'),
      subcategories: uniqueValues(subcategories.items, 'title'),
      courses: uniqueValues(courses.items, 'title'),
      languages: uniqueValues(
        [...categories.items, ...subcategories.items, ...courses.items],
        'language',
      ),
    }
  }, [])
  const { data: referenceData } = useAsyncData(loadReferenceData)

  const languages = useMemo(() => {
    const set = new Set()
    for (const row of data?.items || []) {
      const value = row.language || row.Language
      if (value) set.add(value)
    }
    for (const value of referenceData?.languages || []) set.add(value)
    return [...set].sort()
  }, [data, referenceData])

  const tableColumns = buildColumns(safeResource, columns)

  const saveResource = async (payload) => {
    setSaving(true)
    try {
      if (editing?.id) {
        await adminApi.updateResource(safeResource, editing.id, payload)
        toast.success(`${resourceLabels[safeResource]} updated`)
      } else {
        await adminApi.createResource(safeResource, payload)
        toast.success(`${resourceLabels[safeResource]} created`)
      }
      setEditing(null)
      reload()
    } finally {
      setSaving(false)
    }
  }

  const deleteResource = async () => {
    setSaving(true)
    try {
      await adminApi.deleteResource(safeResource, deleting.id)
      toast.success('Record deleted')
      setDeleting(null)
      reload()
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <PageHeader
        title="Learning Content"
        subtitle="Manage catalog records used by the Flutter app without changing the student API contract."
        action={{
          label: `Add ${resourceLabels[safeResource].replace(/s$/, '')}`,
          onClick: () => setEditing({}),
        }}
        actionIcon={<AddRounded />}
      />

      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 2 }}>
        <Tabs
          value={safeResource}
          onChange={(_, value) => {
            setPage(1)
            navigate(`/resources/${value}`)
          }}
          variant="scrollable"
          scrollButtons="auto"
        >
          {resourceOrder.map((key) => (
            <Tab key={key} value={key} label={resourceLabels[key]} />
          ))}
        </Tabs>
      </Box>

      <DataToolbar
        search={search}
        onSearch={(value) => {
          setSearch(value)
          setPage(1)
        }}
        placeholder={`Search ${resourceLabels[safeResource].toLowerCase()}`}
      >
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1}>
          <TextField
            select
            size="small"
            value={language}
            label="Language"
            onChange={(event) => {
              setLanguage(event.target.value)
              setPage(1)
            }}
            sx={{ minWidth: 150 }}
          >
            <MenuItem value="">All</MenuItem>
            {languages.map((item) => (
              <MenuItem key={item} value={item}>
                {item}
              </MenuItem>
            ))}
          </TextField>
          <Button variant="outlined" startIcon={<AddRounded />} onClick={() => setEditing({})}>
            Add
          </Button>
        </Stack>
      </DataToolbar>

      <AppDataTable
        columns={tableColumns}
        rows={data?.items || []}
        loading={loading}
        page={data?.page || page}
        limit={data?.limit || limit}
        total={data?.total || 0}
        onPageChange={setPage}
        onLimitChange={(value) => {
          setLimit(value)
          setPage(1)
        }}
        actions={[
          {
            label: 'Edit',
            icon: <EditRounded fontSize="small" />,
            onClick: (row) => setEditing(row),
          },
          {
            label: 'Delete',
            color: 'error',
            icon: <DeleteRounded fontSize="small" />,
            onClick: (row) => setDeleting(row),
          },
        ]}
      />

      <ResourceDialog
        open={Boolean(editing)}
        title={`${editing?.id ? 'Edit' : 'Add'} ${resourceLabels[safeResource]}`}
        columns={columns}
        item={editing}
        resource={safeResource}
        optionSets={referenceData || {}}
        saving={saving}
        onClose={() => setEditing(null)}
        onSubmit={saveResource}
      />
      <ConfirmDialog
        open={Boolean(deleting)}
        title="Delete record"
        body={`Delete this ${resourceLabels[safeResource].toLowerCase()} record?`}
        confirmLabel="Delete"
        loading={saving}
        onClose={() => setDeleting(null)}
        onConfirm={deleteResource}
      />
    </>
  )
}

function uniqueValues(rows = [], key) {
  return [...new Set(rows.map((row) => row[key]).filter(Boolean))].sort()
}

function buildColumns(resource, columns) {
  const display = columns.slice(0, resource === 'stories' ? 5 : 6)
  return [
    {
      key: 'id',
      label: 'ID',
      minWidth: 72,
    },
    ...display.map((column) => ({
      key: column,
      label: humanize(column),
      minWidth: column.includes('image') || column.includes('audio') ? 220 : 150,
      render: (row) => renderValue(column, row[column]),
    })),
  ]
}

function renderValue(column, value) {
  if (column === 'show_plan') return <StatusChip value={value === '1' ? 'premium' : 'free'} />
  if (column === 'created') return formatDate(value)
  if (column.includes('image') && value) {
    return (
      <Stack direction="row" spacing={1} sx={{ minWidth: 0, alignItems: 'center' }}>
        <Box
          component="img"
          src={mediaUrl(value)}
          alt=""
          sx={{ width: 42, height: 42, objectFit: 'cover', borderRadius: 1, border: 1, borderColor: 'divider' }}
        />
        <Typography variant="caption" noWrap sx={{ maxWidth: 170 }}>
          {value}
        </Typography>
      </Stack>
    )
  }
  if (typeof value === 'object') return JSON.stringify(value)
  return value || '-'
}
