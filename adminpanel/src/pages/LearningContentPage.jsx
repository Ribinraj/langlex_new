import { useCallback, useState } from 'react'
import { Link, useParams, useSearchParams, useNavigate } from 'react-router-dom'
import {
  AddRounded,
  ArrowBackRounded,
  AutoStoriesRounded,
  DeleteRounded,
  EditRounded,
  FolderOpenRounded,
  HearingRounded,
  QuizRounded,
  SchoolRounded,
  SpellcheckRounded,
  VisibilityRounded,
} from '@mui/icons-material'
import {
  Alert,
  Box,
  Breadcrumbs,
  Button,
  Card,
  CardActionArea,
  CardContent,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  Grid,
  MenuItem,
  Stack,
  Switch,
  Tab,
  Tabs,
  TextField,
  Typography,
} from '@mui/material'
import toast from 'react-hot-toast'
import PageHeader from '../components/PageHeader'
import AppDataTable from '../components/AppDataTable'
import ResourceDialog from '../components/ResourceDialog'
import BulkDialog from '../components/BulkDialog'
import ConfirmDialog from '../components/ConfirmDialog'
import EmptyState from '../components/EmptyState'
import CurriculumTopicDialog from '../components/CurriculumTopicDialog'
import StandardsSelect from '../components/StandardsSelect'
import { useAsyncData } from '../hooks/useAsyncData'
import {
  curriculumApi,
  sections,
  sounds,
  standardsLabel,
} from '../services/curriculumApi'
import { humanize } from '../services/adminApi'
import { mediaUrl } from '../services/apiClient'
const icons = {
  knowledge: <SchoolRounded />,
  alphabets: <SpellcheckRounded />,
  stories: <AutoStoriesRounded />,
  quizzes: <QuizRounded />,
}
const columns = {
  courses: ['content', 'content_image', 'content_audio', 'word_audio'],
  alphabets: [
    'ill_word',
    'ill_image',
    'letter_sound',
    'word_audio',
    'letter_type',
  ],
  stories: ['text', 'image', 'audio', 'audio_text_map'],
  quizzes: [
    'Question',
    'ca',
    'o1',
    'o2',
    'o3',
    'Instruction',
    'audio',
    'image',
    'RAFeed',
    'WAFeed',
    'QType',
    'q_audio',
    'raf_audio',
    'waf_audio',
  ],
  phonics: ['word', 'sentence', 'image', 'sentence_sound', 'word_audio'],
}
const headline = {
  courses: 'content',
  alphabets: 'ill_word',
  stories: 'text',
  quizzes: 'Question',
  phonics: 'word',
}
export default function LearningContentPage() {
  const { section, topicId } = useParams()
  const loader = useCallback(() => curriculumApi.options(), [])
  const options = useAsyncData(loader)
  if (options.loading || options.error)
    return (
      <>
        <PageHeader
          title="Learning content"
          subtitle="Organized just like the student app."
        />
        {options.error ? (
          <EmptyState error={options.error} onRetry={options.reload} />
        ) : (
          <Typography>Loading your catalog…</Typography>
        )}
      </>
    )
  if (!section)
    return (
      <>
        <PageHeader
          title="Learning content"
          subtitle="Choose a section, then manage its topics and student standards."
        />
        <Grid container spacing={2.5}>
          {Object.entries(sections).map(([key, s]) => (
            <Grid key={key} size={{ xs: 12, sm: 6 }}>
              <Card variant="outlined" sx={{ height: '100%' }}>
                <CardActionArea
                  component={Link}
                  to={`/learning/${key}`}
                  sx={{ p: 1, minHeight: 185 }}
                >
                  <CardContent>
                    <Box sx={{ color: 'primary.main', mb: 2 }}>
                      {icons[key]}
                    </Box>
                    <Typography variant="h5" gutterBottom>
                      {s.label}
                    </Typography>
                    <Typography color="text.secondary">
                      {s.description}
                    </Typography>
                  </CardContent>
                </CardActionArea>
              </Card>
            </Grid>
          ))}
        </Grid>
      </>
    )
  if (!sections[section])
    return (
      <EmptyState
        title="Section not found"
        description="Choose Learning content from the navigation."
      />
    )
  return (
    <Workspace
      key={`${section}-${topicId || ''}`}
      sectionKey={section}
      topicId={topicId}
      options={options.data}
    />
  )
}
function Workspace({ sectionKey, topicId, options }) {
  const [params, setParams] = useSearchParams(),
    navigate = useNavigate()
  const isSounds =
    sectionKey === 'knowledge' && params.get('activity') === 'sounds'
  const section = isSounds ? sounds : sections[sectionKey]
  const language = params.get('language') || '',
    standard = params.get('standard') || '',
    search = params.get('search') || ''
  const preview = params.get('preview') === '1',
    page = Number(params.get('page')) || 1,
    limit = Number(params.get('limit')) || 10
  const [topicEditing, setTopicEditing] = useState(null),
    [editing, setEditing] = useState(null),
    [deleting, setDeleting] = useState(null),
    [saving, setSaving] = useState(false),
    [viewing, setViewing] = useState(null)
  const [bulkOpen, setBulkOpen] = useState(false)
  const [deleteTopicOpen, setDeleteTopicOpen] = useState(false)
  const [inherit, setInherit] = useState(true),
    [override, setOverride] = useState([])
  const changeParams = (patch) => {
    const next = new URLSearchParams(params)
    next.delete('page')
    for (const [k, v] of Object.entries(patch)) {
      if (v) next.set(k, String(v))
      else next.delete(k)
    }
    setParams(next)
  }
  const load = useCallback(
    () =>
      topicId
        ? curriculumApi.detail(topicId, {
            page,
            limit,
            ...(preview ? { standard } : {}),
          })
        : curriculumApi.list({
            resource: section.resource,
            language,
            standard,
            search,
            page,
            limit,
          }),
    [
      topicId,
      section.resource,
      language,
      standard,
      search,
      page,
      limit,
      preview,
    ],
  )
  const { data, loading, error, reload } = useAsyncData(load)
  const topic = data?.topic
  const actualSection = topic
    ? Object.values({ ...sections, sounds }).find(
        (s) => s.resource === topic.resource,
      )
    : section
  const s = actualSection || section
  const backUrl = `/learning/${sectionKey}?${params.toString()}`
  const openTopic = (row) =>
    navigate(`/learning/${sectionKey}/${row.id}?${params.toString()}`)
  const editItem = (row) => {
    setEditing(row || {})
    setInherit(row?.standard_override == null)
    setOverride(row?.standard_override || [])
  }
  const saveTopic = async (payload, apply) => {
    setSaving(true)
    try {
      if (topicEditing.id)
        await curriculumApi.update(topicEditing.id, {
          ...payload,
          apply_to_items: apply,
        })
      else
        await curriculumApi.create({ ...payload, resource: section.resource })
      setTopicEditing(null)
      await reload()
      toast.success('Topic saved')
    } finally {
      setSaving(false)
    }
  }
  const saveItem = async (payload) => {
    if (!inherit && !override.length) {
      toast.error('Choose standards or use the topic defaults.')
      return
    }
    setSaving(true)
    try {
      await curriculumApi.saveItem(topicId, editing.id, {
        ...payload,
        standard_override: inherit ? null : override,
      })
      setEditing(null)
      await reload()
      toast.success(`${s.item} saved`)
    } catch {
      /* API displays error; keep form open. */
    } finally {
      setSaving(false)
    }
  }
  const remove = async () => {
    setSaving(true)
    try {
      await curriculumApi.deleteItem(topicId, deleting.id)
      setDeleting(null)
      await reload()
      toast.success('Item deleted')
    } catch {
      /* Keep confirmation open. */
    } finally {
      setSaving(false)
    }
  }
  const standardsCell = (row) => (
    <Stack direction="row" useFlexGap flexWrap="wrap" gap={0.5}>
      <Chip
        size="small"
        color={row.standards?.length ? 'default' : 'warning'}
        label={standardsLabel(row.standards)}
      />
      {row.override_count > 0 && (
        <Chip size="small" variant="outlined" label="Varies by item" />
      )}
      {row.review_count > 0 && (
        <Chip
          size="small"
          color="warning"
          variant="outlined"
          label={`${row.review_count} need review`}
        />
      )}
    </Stack>
  )
  return (
    <>
      <Breadcrumbs sx={{ mb: 2, overflowWrap: 'anywhere' }}>
        <Button component={Link} to="/learning" size="small">
          Learning content
        </Button>
        {topicId ? (
          <Button component={Link} to={backUrl} size="small">
            {s.label}
          </Button>
        ) : (
          <Typography color="text.primary">{s.label}</Typography>
        )}
        {topic && (
          <Typography>
            {topic.language} · {topic.title}
          </Typography>
        )}
      </Breadcrumbs>
      <PageHeader
        title={topicId ? topic?.title || 'Topic' : s.label}
        subtitle={
          topicId ? `${topic?.language || ''} · ${s.plural}` : s.description
        }
        action={
          !preview
            ? {
                label: topicId ? `Add ${s.item}` : 'Add topic',
                onClick: () =>
                  topicId
                    ? editItem(null)
                    : setTopicEditing({
                        language,
                        standards:
                          standard && standard !== 'review' ? [standard] : [],
                      }),
                disabled: loading || Boolean(error),
              }
            : undefined
        }
        actionIcon={<AddRounded />}
      />
      {!topicId && (
        <Tabs
          value={sectionKey}
          variant="scrollable"
          scrollButtons="auto"
          allowScrollButtonsMobile
          sx={{ mb: 3, borderBottom: 1, borderColor: 'divider' }}
          onChange={(_, key) =>
            navigate(
              `/learning/${key}?${new URLSearchParams({ language, standard, ...(preview ? { preview: '1' } : {}) })}`,
            )
          }
        >
          {Object.entries(sections).map(([key, item]) => (
            <Tab
              key={key}
              value={key}
              label={item.label}
              icon={icons[key]}
              iconPosition="start"
            />
          ))}
        </Tabs>
      )}
      {!topicId && sectionKey === 'knowledge' && (
        <Stack direction="row" spacing={1} sx={{ mb: 2 }}>
          <Button
            variant={!isSounds ? 'contained' : 'outlined'}
            onClick={() => changeParams({ activity: '' })}
          >
            Topics
          </Button>
          <Button
            startIcon={<HearingRounded />}
            variant={isSounds ? 'contained' : 'outlined'}
            onClick={() => changeParams({ activity: 'sounds' })}
          >
            Sounds
          </Button>
        </Stack>
      )}
      <Stack
        direction={{ xs: 'column', md: 'row' }}
        spacing={2}
        sx={{ mb: 2, alignItems: { md: 'center' } }}
      >
        {!topicId && (
          <TextField
            label="Search topics"
            value={search}
            onChange={(e) => changeParams({ search: e.target.value })}
            size="small"
            sx={{ flex: 1, minWidth: 150 }}
          />
        )}
        {!topicId && (
          <TextField
            select
            size="small"
            label="Language"
            slotProps={{
              select: { displayEmpty: true },
              inputLabel: { shrink: true },
            }}
            value={language}
            sx={{ minWidth: 160 }}
            onChange={(e) => changeParams({ language: e.target.value })}
          >
            {!preview && <MenuItem value="">All languages</MenuItem>}
            {options.languages.map((l) => (
              <MenuItem key={l} value={l}>
                {l}
              </MenuItem>
            ))}
          </TextField>
        )}
        {(!topicId || preview) && (
          <TextField
            select
            size="small"
            label={preview ? 'Student standard' : 'Standard'}
            slotProps={{
              select: { displayEmpty: true },
              inputLabel: { shrink: true },
            }}
            value={standard}
            sx={{ minWidth: 180 }}
            onChange={(e) => changeParams({ standard: e.target.value })}
          >
            {!preview && <MenuItem value="">All assignments</MenuItem>}
            {options.standards.map((level) => (
              <MenuItem key={level} value={level}>
                {level}
              </MenuItem>
            ))}
            {!preview && <MenuItem value="review">Needs review</MenuItem>}
          </TextField>
        )}
        <FormControlLabel
          control={
            <Switch
              checked={preview}
              onChange={(_, checked) =>
                changeParams({
                  preview: checked ? '1' : '',
                  language: language || topic?.language || 'English',
                  standard:
                    checked && (!standard || standard === 'review')
                      ? 'Nursery'
                      : standard,
                })
              }
            />
          }
          label="Student preview"
        />
      </Stack>
      {preview && (
        <Alert icon={<VisibilityRounded />} severity="info" sx={{ mb: 2 }}>
          Preview for {topic?.language || language} · {standard}. Only assigned
          content is shown. Premium topics still require an active subscription.
        </Alert>
      )}
      {topic && (
        <Stack
          direction={{ xs: 'column', sm: 'row' }}
          spacing={1}
          sx={{ mb: 2, alignItems: { xs: 'flex-start', sm: 'center' } }}
        >
          <Button
            startIcon={<ArrowBackRounded />}
            component={Link}
            to={backUrl}
          >
            Back to {s.label}
          </Button>
          {standardsCell(topic)}
          <Chip size="small" label={topic.access} />
          {!preview && (
            <Button
              startIcon={<EditRounded />}
              onClick={() => setTopicEditing(topic)}
            >
              Edit topic & standards
            </Button>
          )}
        </Stack>
      )}
      {topic?.review_count > 0 && !preview && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          Some original records have no recognized standard. Review their
          assignments before students can see them.
        </Alert>
      )}
      {topic && !preview && topic.item_count === 0 && (
        <Button
          color="error"
          onClick={() => setDeleteTopicOpen(true)}
          sx={{ mb: 2 }}
        >
          Delete empty topic
        </Button>
      )}
      {topic && !preview && (
        <Button
          variant="outlined"
          onClick={() => setBulkOpen(true)}
          disabled={loading || Boolean(error)}
          sx={{ mb: 2 }}
        >
          Import / bulk edit {s.plural.toLowerCase()}
        </Button>
      )}
      {bulkOpen && topic && (
        <BulkDialog
          resource={s.resource === 'courses' ? 'content' : s.resource}
          scopeTopic={topic}
          columnsOverride={columns[s.resource]}
          rows={data?.items || []}
          onClose={() => setBulkOpen(false)}
          onSaved={reload}
        />
      )}
      <AppDataTable
        loading={loading}
        error={error}
        onRetry={reload}
        rows={data?.items || []}
        page={page}
        limit={limit}
        total={data?.total || 0}
        onPageChange={(v) => {
          const next = new URLSearchParams(params)
          next.set('page', v)
          setParams(next)
        }}
        onLimitChange={(v) => changeParams({ limit: v })}
        emptyMessage={
          preview
            ? 'No content for this student'
            : topicId
              ? `No ${s.plural.toLowerCase()} yet`
              : 'No topics found'
        }
        emptyDescription={
          preview
            ? 'Choose another standard, or switch off preview to review assignments.'
            : topicId
              ? `Use Add ${s.item} to build this topic.`
              : 'Adjust the filters or add a topic.'
        }
        columns={
          topicId
            ? [
                {
                  key: headline[s.resource],
                  label: s.item[0].toUpperCase() + s.item.slice(1),
                  minWidth: 180,
                  render: (row) => (
                    <Typography
                      sx={{
                        display: '-webkit-box',
                        WebkitLineClamp: 3,
                        WebkitBoxOrient: 'vertical',
                        overflow: 'hidden',
                      }}
                    >
                      {row[headline[s.resource]] || '—'}
                    </Typography>
                  ),
                },
                ...(s.resource === 'quizzes'
                  ? [{ key: 'ca', label: 'Correct answer' }]
                  : []),
                {
                  key: 'effective_standards',
                  label: 'Standards',
                  render: (row) => (
                    <Stack>
                      <Typography variant="body2">
                        {standardsLabel(row.effective_standards)}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {row.standard_override == null
                          ? 'Uses topic standards'
                          : 'Item-specific assignment'}
                      </Typography>
                    </Stack>
                  ),
                },
              ]
            : [
                {
                  key: 'title',
                  label:
                    s.resource === 'alphabets' ? 'Letter / lesson' : 'Topic',
                  minWidth: 180,
                  render: (row) => (
                    <Stack>
                      <Button
                        onClick={() => openTopic(row)}
                        sx={{
                          justifyContent: 'flex-start',
                          textAlign: 'left',
                          p: 0,
                          minHeight: 44,
                        }}
                      >
                        {row.title}
                      </Button>
                      {row.group_name && (
                        <Typography variant="caption" color="text.secondary">
                          {row.group_name}
                        </Typography>
                      )}
                    </Stack>
                  ),
                },
                { key: 'language', label: 'Language', minWidth: 90 },
                {
                  key: 'standards',
                  label: 'Available for',
                  minWidth: 160,
                  render: standardsCell,
                },
                {
                  key: preview ? 'eligible_count' : 'item_count',
                  label: s.plural,
                  minWidth: 65,
                },
                {
                  key: 'access',
                  label: 'Access',
                  minWidth: 105,
                  render: (row) => (
                    <Chip
                      size="small"
                      variant="outlined"
                      label={
                        row.access === 'Login' ? 'Login required' : row.access
                      }
                    />
                  ),
                },
              ]
        }
        actions={
          topicId
            ? [
                {
                  label: 'View',
                  icon: <VisibilityRounded />,
                  onClick: setViewing,
                },
                ...(!preview
                  ? [
                      {
                        label: 'Edit',
                        icon: <EditRounded />,
                        onClick: editItem,
                      },
                      {
                        label: 'Delete',
                        icon: <DeleteRounded />,
                        color: 'error',
                        onClick: setDeleting,
                      },
                    ]
                  : []),
              ]
            : [
                {
                  label: 'Open',
                  icon: <FolderOpenRounded />,
                  showLabel: true,
                  onClick: openTopic,
                },
                ...(!preview
                  ? [
                      {
                        label: 'Edit topic',
                        icon: <EditRounded />,
                        onClick: setTopicEditing,
                      },
                    ]
                  : []),
              ]
        }
      />
      {topicEditing && (
        <CurriculumTopicDialog
          topic={topicEditing}
          section={s}
          options={options}
          saving={saving}
          onClose={() => setTopicEditing(null)}
          onSave={saveTopic}
        />
      )}
      {editing && (
        <ResourceDialog
          key={editing.id || 'new'}
          open
          resource={s.resource === 'courses' ? 'content' : s.resource}
          title={`${editing.id ? 'Edit' : 'Add'} ${s.item} · ${topic.title}`}
          columns={columns[s.resource]}
          primaryField={headline[s.resource]}
          item={{
            ...editing,
            language: topic.language,
            Language: topic.language,
          }}
          saving={saving}
          onClose={() => setEditing(null)}
          onSubmit={saveItem}
          description={`${s.label} → ${topic.language} → ${topic.title}. New items inherit the topic’s standards.`}
          extraContent={
            <Stack spacing={1}>
              <FormControlLabel
                control={
                  <Switch
                    checked={inherit}
                    onChange={(_, v) => setInherit(v)}
                    disabled={saving}
                  />
                }
                label={`Use topic standards: ${standardsLabel(topic.standards)}`}
              />
              {!inherit && (
                <StandardsSelect
                  value={override}
                  onChange={setOverride}
                  options={options.standards}
                  disabled={saving}
                />
              )}
            </Stack>
          }
        />
      )}
      <ConfirmDialog
        open={deleteTopicOpen}
        title="Delete this empty topic?"
        body="This topic has no content. Deleting it leaves other topics and learning history unchanged."
        confirmLabel="Delete topic"
        loading={saving}
        onClose={() => setDeleteTopicOpen(false)}
        onConfirm={async () => {
          setSaving(true)
          try {
            await curriculumApi.deleteTopic(topic.id)
            navigate(backUrl)
            toast.success('Empty topic deleted')
          } catch {
          } finally {
            setSaving(false)
          }
        }}
      />
      <ConfirmDialog
        open={Boolean(deleting)}
        title={`Delete this ${s.item}?`}
        body="This removes the content record. Previously earned learning history is retained."
        confirmLabel="Delete"
        loading={saving}
        onClose={() => setDeleting(null)}
        onConfirm={remove}
      />
      {viewing && (
        <Dialog open maxWidth="md" fullWidth onClose={() => setViewing(null)}>
          <DialogTitle>
            {topic.title} · {s.item}
          </DialogTitle>
          <DialogContent dividers>
            <Stack spacing={2}>
              {columns[s.resource]
                .filter((k) => viewing[k])
                .map((k) => (
                  <Box key={k}>
                    <Typography variant="caption" color="text.secondary">
                      {humanize(k)}
                    </Typography>
                    {/image/.test(k) ? (
                      <Box
                        component="img"
                        src={mediaUrl(viewing[k])}
                        alt={topic.title}
                        sx={{
                          display: 'block',
                          maxWidth: '100%',
                          maxHeight: 250,
                          objectFit: 'contain',
                        }}
                      />
                    ) : /audio|sound/.test(k) && k !== 'audio_text_map' ? (
                      <Box
                        component="audio"
                        controls
                        preload="none"
                        src={mediaUrl(viewing[k])}
                        sx={{ display: 'block', maxWidth: '100%' }}
                      />
                    ) : (
                      <Typography
                        sx={{
                          whiteSpace: 'pre-wrap',
                          overflowWrap: 'anywhere',
                        }}
                      >
                        {viewing[k]}
                      </Typography>
                    )}
                  </Box>
                ))}
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setViewing(null)}>Close</Button>
          </DialogActions>
        </Dialog>
      )}
    </>
  )
}
