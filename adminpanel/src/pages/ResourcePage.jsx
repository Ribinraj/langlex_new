import {
  FileUploadRounded,
  AddRounded,
  ArrowBackRounded,
  DeleteRounded,
  EditRounded,
  FolderOpenRounded,
  ImageOutlined,
} from '@mui/icons-material'
import {
  Alert,
  Avatar,
  Button,
  Chip,
  MenuItem,
  Stack,
  Tabs,
  Tab,
  TextField,
  ToggleButton,
  ToggleButtonGroup,
  Typography,
} from '@mui/material'
import { useCallback, useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import { Navigate, useNavigate, useParams } from 'react-router-dom'
import AppDataTable from '../components/AppDataTable'
import ConfirmDialog from '../components/ConfirmDialog'
import DataToolbar from '../components/DataToolbar'
import PageHeader from '../components/PageHeader'
import ResourceDialog from '../components/ResourceDialog'
import BulkDialog from '../components/BulkDialog'
import TopicDialog from '../components/TopicDialog'
import { topicFields } from '../services/adminApi'
import EmptyState from '../components/EmptyState'
import StatusChip from '../components/StatusChip'
import {
  adminApi,
  humanize,
  resourceLabels,
  resourceSchemas,
} from '../services/adminApi'
import { apiClient, mediaUrl } from '../services/apiClient'
import { formatDate } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
const grouped = new Set([
  'courses',
  'alphabets',
  'quizzes',
  'phonics',
  'stories',
])
const singular = {
  categories: 'category',
  subcategories: 'subcategory',
  courses: 'course',
  content: 'word',
  alphabets: 'example',
  quizzes: 'question',
  phonics: 'sound',
  stories: 'passage',
  plans: 'plan',
}
export default function ResourcePage() {
  const { resource = 'courses' } = useParams()
  const destination = {courses:'knowledge',content:'knowledge',alphabets:'alphabets',stories:'stories',quizzes:'quizzes',phonics:'knowledge?activity=sounds'}[resource]
  if(destination)return <Navigate to={`/learning/${destination}`} replace/>
  if(['categories','subcategories'].includes(resource))return <Navigate to="/learning" replace/>
  return Object.hasOwn(resourceSchemas, resource) ? (
    <CatalogWorkspace key={resource} resource={resource} />
  ) : (
    <EmptyState
      title="Catalog not found"
      description="Choose Learning content from the navigation to return to the catalog."
    />
  )
}
function CatalogWorkspace({ resource }) {
  const navigate = useNavigate()
  const [bulkOpen, setBulkOpen] = useState(false)
  const [view, setView] = useState(
    grouped.has(resource) ? 'activities' : 'records',
  )
  const [group, setGroup] = useState(null),
    [groupEditing, setGroupEditing] = useState(null)
  const [search, setSearch] = useState(''),
    [language, setLanguage] = useState('')
  const query = useDebouncedValue(search)
  const [page, setPage] = useState(1),
    [limit, setLimit] = useState(10)
  const [editing, setEditing] = useState(null),
    [deleting, setDeleting] = useState(null),
    [saving, setSaving] = useState(false)
  const activities = view === 'activities' && !group
  const recordResource = group && resource === 'courses' ? 'content' : resource
  const load = useCallback(
    () =>
      group
        ? adminApi.groupItems(resource, group.id, { page, limit })
        : activities
          ? adminApi.catalog(resource, { page, limit, language, search: query })
          : adminApi.resource(resource, {
              page,
              limit,
              language,
              search: query,
            }),
    [group, resource, page, limit, language, query, activities],
  )
  const { data, loading, error, reload } = useAsyncData(load)
  const loadLanguages = useCallback(
    async () => (await apiClient.get('/languages')).data.languages,
    [],
  )
  const { data: languages } = useAsyncData(loadLanguages)
  const openGroup = (row) => {
    setGroup(row)
    setSearch('')
    setPage(1)
  }
  const newRecord = () =>
    setEditing({
      ...data?.defaults,
      ...(group
        ? { show_plan: group.show_plan || data?.group?.show_plan || 'Free' }
        : { language: language || '', Language: language || '' }),
    })
  const save = async (payload) => {
    setSaving(true)
    try {
      if (editing?.id)
        await adminApi.updateResource(recordResource, editing.id, payload)
      else
        await adminApi.createResource(
          recordResource,
          Object.fromEntries(
            resourceSchemas[recordResource]
              .filter((key) => Object.hasOwn({ ...editing, ...payload }, key))
              .map((key) => [key, { ...editing, ...payload }[key]]),
          ),
        )
      toast.success(editing?.id ? 'Record updated' : 'Record created')
      setEditing(null)
      reload()
    } catch {
      /* API feedback preserves the form. */
    } finally {
      setSaving(false)
    }
  }
  const saveGroup = async (payload) => {
    setSaving(true)
    try {
      const result = await adminApi.updateGroup(
        resource,
        groupEditing.id,
        payload,
      )
      if (group)
        setGroup({
          ...group,
          ...payload,
          ...(resource === 'courses' && group.virtual && result?.id
            ? { id: result.id, virtual: false }
            : {}),
          language: payload.language || payload.Language || group.language,
          title:
            (resource === 'alphabets' ? payload.letter : null) ||
            payload.title ||
            payload.topic ||
            payload.coursename ||
            payload.letter ||
            group.title,
        })
      setGroupEditing(null)
      reload()
      toast.success('Topic updated')
    } catch {
      /* Preserve entered values for retry. */
    } finally {
      setSaving(false)
    }
  }
  const remove = async () => {
    setSaving(true)
    try {
      await adminApi.deleteResource(recordResource, deleting.id)
      setDeleting(null)
      toast.success('Record deleted')
      if (group && Number(deleting.id) === Number(group.id)) {
        setGroup(null)
        setPage(1)
      } else reload()
    } catch {
      /* API feedback */
    } finally {
      setSaving(false)
    }
  }
  useEffect(() => {
    setPage(1)
  }, [query, language])
  return (
    <>
      <PageHeader
        title={
          group
            ? group.title
            : resource === 'stories'
              ? 'Stories'
              : resource === 'plans' ? 'Subscription plans' : 'Learning content'
        }
        subtitle={
          group
            ? 'Manage the records that make up this activity in the app.'
            : activities
              ? 'Browse activities as learners see them, then open one to manage its content.'
              : 'Manage the original catalog records used by the app.'
        }
        action={{
          label: `Add ${singular[recordResource]}`,
          onClick: newRecord,
          disabled: Boolean(group && (loading || error || !data?.group)),
        }}
        actionIcon={<AddRounded />}
      />
      <Tabs
        value={resource}
        onChange={(_, value) => navigate(`/resources/${value}`)}
        variant="scrollable"
        scrollButtons="auto"
        allowScrollButtonsMobile
        sx={{ mb: 3, borderBottom: 1, borderColor: 'divider' }}
      >
        {Object.entries(resourceLabels).filter(([key])=>key==='plans').map(([key, label]) => (
          <Tab
            key={key}
            value={key}
            label={key === 'phonics' ? 'Sounds' : label}
          />
        ))}
      </Tabs>
      {group ? (
        <Stack
          direction={{ xs: 'column', sm: 'row' }}
          spacing={1}
          sx={{ mb: 2, alignItems: { sm: 'center' } }}
        >
          <Button
            startIcon={<ArrowBackRounded />}
            onClick={() => {
              setGroup(null)
              setPage(1)
            }}
          >
            Back to topics
          </Button>
          <Chip label={group.language} />
          {group.grade && <Chip label={group.grade} />}
          {['courses', 'stories', 'quizzes'].includes(resource) &&
            accessChip(data?.group?.show_plan || group.show_plan)}
          <Button
            startIcon={<EditRounded />}
            variant="outlined"
            disabled={!data?.group || loading}
            onClick={() => setGroupEditing(group)}
          >
            Edit topic
          </Button>
        </Stack>
      ) : (
        <>
          {grouped.has(resource) && (
            <ToggleButtonGroup
              value={view}
              exclusive
              size="small"
              aria-label="Catalog view"
              onChange={(_, value) => {
                if (value) {
                  setView(value)
                  setPage(1)
                }
              }}
              sx={{ mb: 2 }}
            >
              <ToggleButton value="activities">Topics</ToggleButton>
              <ToggleButton value="records">All records</ToggleButton>
            </ToggleButtonGroup>
          )}
          <DataToolbar
            search={search}
            onSearch={setSearch}
            placeholder={`Search ${resourceLabels[resource].toLowerCase()}`}
          >
            <TextField
              select
              size="small"
              label="Language"
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              sx={{ minWidth: 160 }}
            >
              <MenuItem value="">All languages</MenuItem>
              {(languages || []).map((value) => (
                <MenuItem key={value} value={value}>
                  {value}
                </MenuItem>
              ))}
            </TextField>
          </DataToolbar>
        </>
      )}
      {group?.virtual && (
        <Alert severity="info" sx={{ mb: 2 }}>
          This activity is built from word records. Use “Edit topic” to save a
          course and set its access.
        </Alert>
      )}
      {resource === 'plans' && (
        <Alert severity="info" sx={{ mb: 2 }}>
          Plan type controls access: an active Premium subscription unlocks
          Premium content. Existing subscriptions keep their expiry date when
          plan pricing changes.
        </Alert>
      )}
      <Button
        startIcon={<FileUploadRounded />}
        variant="outlined"
        sx={{ mb: 2 }}
        disabled={loading || Boolean(error)}
        onClick={() => setBulkOpen(true)}
      >
        {activities ? 'Bulk edit topics' : 'Import / bulk edit'}
      </Button>
      {bulkOpen && (
        <BulkDialog
          resource={recordResource}
          topics={activities}
          rows={data?.items || []}
          onClose={() => setBulkOpen(false)}
          onSaved={reload}
        />
      )}
      <AppDataTable
        columns={
          activities
            ? [
                {
                  key: 'title',
                  label: resource === 'quizzes' ? 'Quiz topic' : 'Activity',
                  minWidth: 240,
                  render: (row) => (
                    <Stack>
                      <Typography fontWeight={600}>
                        {row.title || 'Unnamed activity'}
                      </Typography>
                      {row.course && (
                        <Typography variant="caption" color="text.secondary">
                          {row.course}
                        </Typography>
                      )}
                    </Stack>
                  ),
                },
                { key: 'language', label: 'Language' },
                ...(resource === 'stories'
                  ? [{ key: 'grade', label: 'Grade' }]
                  : []),
                {
                  key: 'item_count',
                  label: {
                    courses: 'Words',
                    alphabets: 'Examples',
                    quizzes: 'Questions',
                    phonics: 'Sounds',
                    stories: 'Passages',
                  }[resource],
                },
                ...(['courses', 'stories', 'quizzes'].includes(resource)
                  ? [
                      {
                        key: 'show_plan',
                        label: 'Access',
                        render: (row) => accessChip(row.show_plan),
                      },
                    ]
                  : []),
              ]
            : buildColumns(recordResource)
        }
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
        actions={
          activities
            ? [
                {
                  label: 'Open content',
                  showLabel: true,
                  icon: <FolderOpenRounded />,
                  onClick: openGroup,
                },
                {
                  label: 'Edit topic',
                  showLabel: true,
                  icon: <EditRounded />,
                  onClick: setGroupEditing,
                },
              ]
            : [
                {
                  label: 'Edit',
                  icon: <EditRounded fontSize="small" />,
                  onClick:
                    resource === 'courses' && !group
                      ? setGroupEditing
                      : setEditing,
                },
                {
                  label: 'Delete',
                  color: 'error',
                  icon: <DeleteRounded fontSize="small" />,
                  onClick: setDeleting,
                },
              ]
        }
      />
      <ResourceDialog
        open={Boolean(editing)}
        resource={recordResource}
        title={`${editing?.id ? 'Edit' : 'Add'} ${singular[recordResource]}`}
        columns={resourceSchemas[recordResource]}
        item={editing}
        lockedFields={
          group
            ? [
                ...(data?.identity_fields || []),
                ...(topicFields[recordResource] || []),
              ]
            : editing?.id && grouped.has(recordResource)
              ? topicFields[recordResource]
              : []
        }
        onEditTopic={
          group || (editing?.id && grouped.has(resource))
            ? () => {
                setGroupEditing(group || editing)
                setEditing(null)
              }
            : undefined
        }
        saving={saving}
        onClose={() => setEditing(null)}
        onSubmit={save}
      />
      {groupEditing && (
        <TopicDialog
          resource={resource}
          topic={groupEditing}
          saving={saving}
          onClose={() => setGroupEditing(null)}
          onSubmit={saveGroup}
        />
      )}
      <ConfirmDialog
        open={Boolean(deleting)}
        title="Delete record?"
        body="This permanently removes this record. Linked parent records cannot be deleted until their content is moved or removed."
        confirmLabel="Delete record"
        loading={saving}
        onClose={() => setDeleting(null)}
        onConfirm={remove}
      />
    </>
  )
}
function accessChip(value) {
  return (
    <StatusChip
      value={
        ['1', 'premium', 'paid'].includes(String(value).trim().toLowerCase())
          ? 'premium'
          : String(value).trim().toLowerCase() === 'login'
            ? 'login required'
            : 'free'
      }
    />
  )
}
function buildColumns(resource) {
  const visible = {
    categories: ['title', 'language', 'image'],
    subcategories: ['title', 'p_cat', 'language'],
    courses: ['title', 'language', 'show_plan'],
    content: ['content', 'course', 'category', 'language', 'word_audio'],
    alphabets: ['letter', 'ill_word', 'coursename', 'letter_type', 'language'],
    quizzes: ['Question', 'topic', 'difflvl', 'ca', 'Language'],
    phonics: ['word', 'sentence', 'coursename', 'language'],
    stories: ['title', 'text', 'grade', 'show_plan', 'language'],
    plans: ['name', 'type', 'amount', 'plan_timeperiod'],
  }[resource]
  return [
    { key: 'id', label: 'ID', minWidth: 60 },
    ...visible.map((column) => ({
      key: column,
      label: humanize(column),
      minWidth: column === 'text' || column === 'Question' ? 260 : 130,
      render: (row) => render(column, row[column]),
    })),
  ]
}
function render(column, value) {
  if (column === 'show_plan') return accessChip(value)
  if (column === 'created') return formatDate(value)
  if (column.includes('image') && value)
    return (
      <Avatar
        variant="rounded"
        src={mediaUrl(value)}
        alt=""
        sx={{ bgcolor: 'action.selected', color: 'primary.main' }}
      >
        <ImageOutlined />
      </Avatar>
    )
  return (
    <Typography
      variant="body2"
      sx={{
        display: '-webkit-box',
        WebkitLineClamp: 2,
        WebkitBoxOrient: 'vertical',
        overflow: 'hidden',
      }}
    >
      {typeof value === 'object' ? JSON.stringify(value) : value || '—'}
    </Typography>
  )
}
