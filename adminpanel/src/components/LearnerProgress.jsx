import {
  AutoStoriesRounded,
  CheckCircleOutlineRounded,
  LockOutlined,
} from '@mui/icons-material'
import {
  Box,
  Card,
  CardContent,
  Chip,
  Grid,
  LinearProgress,
  MenuItem,
  Skeleton,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useCallback, useMemo, useState } from 'react'
import { adminApi } from '../services/adminApi'
import { useAsyncData } from '../hooks/useAsyncData'
import AppDataTable from './AppDataTable'
import EmptyState from './EmptyState'
import StatCard from './StatCard'
export default function LearnerProgress({ userId }) {
  const [language, setLanguage] = useState(''),
    [filter, setFilter] = useState(''),
    [page, setPage] = useState(1),
    [limit, setLimit] = useState(10)
  const load = useCallback(
    () => adminApi.learningProgress(userId, language),
    [userId, language],
  )
  const { data, loading, error, reload } = useAsyncData(load)
  const progress = data?.progress
  const topics = useMemo(
    () =>
      (progress?.topics || []).filter(
        (topic) => !filter || topic.content_type === filter,
      ),
    [progress, filter],
  )
  if (error)
    return (
      <Card>
        <EmptyState error={error} onRetry={reload} />
      </Card>
    )
  if (loading && !progress) return <Skeleton variant="rounded" height={320} />
  if (data?.configured === false)
    return (
      <Card>
        <EmptyState
          title="Learning setup not completed"
          description="Progress becomes available after this learner chooses their three languages in the app."
        />
      </Card>
    )
  return (
    <Stack spacing={2.5}>
      <Stack
        direction={{ xs: 'column', sm: 'row' }}
        spacing={2}
        sx={{ justifyContent: 'space-between', alignItems: { sm: 'center' } }}
      >
        <Box>
          <Typography variant="h6">Learning progress</Typography>
          <Typography variant="body2" color="text.secondary">
            Same earned-item totals and access rules as the app.
          </Typography>
        </Box>
        <TextField
          select
          size="small"
          label="Learning language"
          value={language || progress?.language || ''}
          onChange={(event) => {
            setLanguage(event.target.value)
            setPage(1)
          }}
          sx={{ minWidth: 170 }}
        >
          {(progress?.selected_languages || []).map((value) => (
            <MenuItem key={value} value={value}>
              {value}
            </MenuItem>
          ))}
        </TextField>
      </Stack>
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, md: 4 }}>
          <StatCard
            title="Overall completion"
            value={`${progress?.percent || 0}%`}
            helper={`${progress?.completed_items || 0} of ${progress?.total_items || 0} currently accessible items`}
            icon={<CheckCircleOutlineRounded />}
            loading={loading}
          />
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <StatCard
            title="Completed topics"
            value={`${progress?.completed_topics || 0} / ${progress?.total_topics || 0}`}
            helper={`${progress?.level || '—'} · ${progress?.has_premium ? 'Premium access' : 'Free access'}`}
            icon={<AutoStoriesRounded />}
            loading={loading}
          />
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <StatCard
            title="Locked topics"
            value={progress?.locked_topics || 0}
            helper={`${progress?.saved_locked_items || 0} previously completed items retained behind the lock`}
            icon={<LockOutlined />}
            loading={loading}
          />
        </Grid>
      </Grid>
      <Card>
        <CardContent>
          <Typography variant="body2" color="text.secondary">
            Overall completion counts distinct accessible items in this
            language. A subscription or catalog change can change the total;
            earned work is retained. Restarting practice does not erase earned
            progress.
          </Typography>
        </CardContent>
      </Card>
      <TextField
        select
        size="small"
        label="Activity type"
        value={filter}
        onChange={(event) => {
          setFilter(event.target.value)
          setPage(1)
        }}
        sx={{ width: { xs: '100%', sm: 220 } }}
      >
        <MenuItem value="">All activities</MenuItem>
        {[
          ['course', 'Knowledge'],
          ['alphabet', 'Letters'],
          ['quiz', 'Quizzes'],
          ['phonics', 'Sounds'],
          ['story', 'Stories'],
        ].map(([value, label]) => (
          <MenuItem key={value} value={value}>
            {label}
          </MenuItem>
        ))}
      </TextField>
      <AppDataTable
        columns={[
          { key: 'title', label: 'Topic', minWidth: 220 },
          {
            key: 'content_type',
            label: 'Activity',
            render: (row) =>
              ({
                course: 'Knowledge',
                alphabet: 'Letters',
                quiz: 'Quiz',
                phonics: 'Sounds',
                story: 'Story',
              })[row.content_type],
          },
          {
            key: 'percent',
            label: 'Earned completion',
            minWidth: 220,
            render: (row) => (
              <Stack spacing={0.5}>
                <Typography variant="body2">
                  {row.completed_items} / {row.total_items} · {row.percent}%
                </Typography>
                <LinearProgress
                  variant="determinate"
                  value={row.percent}
                  color={row.accessible ? 'primary' : 'inherit'}
                  sx={{ height: 6, borderRadius: 1 }}
                />
              </Stack>
            ),
          },
          {
            key: 'accessible',
            label: 'Access',
            render: (row) => (
              <Chip
                size="small"
                variant="outlined"
                color={row.accessible ? 'success' : 'default'}
                label={
                  row.accessible
                    ? 'Available'
                    : row.completed_items > 0
                      ? 'Locked · progress saved'
                      : 'Premium locked'
                }
              />
            ),
          },
          {
            key: 'correct_items',
            label: 'Quiz accuracy',
            render: (row) =>
              row.content_type === 'quiz'
                ? `${row.correct_items} / ${row.completed_items} answered`
                : '—',
          },
        ]}
        rows={topics.slice((page - 1) * limit, page * limit)}
        getRowId={(row) => row.content_key}
        loading={loading}
        page={page}
        limit={limit}
        total={topics.length}
        onPageChange={setPage}
        onLimitChange={(value) => {
          setLimit(value)
          setPage(1)
        }}
        emptyMessage="No activities for this selection"
        emptyDescription="Progress will appear when matching content is available."
      />
    </Stack>
  )
}
