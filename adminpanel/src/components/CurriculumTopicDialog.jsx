import { useState } from 'react'
import {
  Alert,
  Button,
  Checkbox,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  MenuItem,
  Stack,
  TextField,
} from '@mui/material'
import StandardsSelect from './StandardsSelect'
import MediaField from './MediaField'
export default function CurriculumTopicDialog({
  topic,
  section,
  options,
  onClose,
  onSave,
  saving,
}) {
  const [value, setValue] = useState({
    title: '',
    language: '',
    group_name: 'Alphabets',
    standards: [],
    access: 'Free',
    image: '',
    audio: '',
    ...topic,
  })
  const [apply, setApply] = useState(false),
    [error, setError] = useState(''),
    [uploads, setUploads] = useState(0)
  const change = (key, next) => setValue((v) => ({ ...v, [key]: next }))
  const submit = async () => {
    if (!value.title.trim() || !value.language || !value.standards.length) {
      setError(
        'Enter a title, select a language and choose at least one standard.',
      )
      return
    }
    setError('')
    try {
      await onSave(
        Object.fromEntries(
          [
            'title',
            'language',
            'group_name',
            'standards',
            'access',
            'image',
            'audio',
            'revision',
          ]
            .filter((k) => value[k] !== undefined)
            .map((k) => [k, value[k]]),
        ),
        apply,
      )
    } catch (e) {
      setError(e.response?.data?.message || 'Unable to save topic.')
    }
  }
  const gated = ['courses', 'stories', 'quizzes'].includes(section.resource)
  return (
    <Dialog
      open
      fullWidth
      maxWidth="sm"
      onClose={saving || uploads ? undefined : onClose}
    >
      <DialogTitle>
        {topic?.id ? 'Edit' : 'Add'}{' '}
        {section.resource === 'alphabets' ? 'letter / lesson' : 'topic'} ·{' '}
        {section.label}
      </DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2.5}>
          {error && <Alert severity="error">{error}</Alert>}
          <TextField
            autoFocus
            label={section.resource === 'alphabets' ? 'Letter' : 'Topic title'}
            value={value.title}
            onChange={(e) => change('title', e.target.value)}
            disabled={saving}
            inputProps={{ maxLength: 255 }}
          />
          <TextField
            select
            label="Language"
            value={value.language}
            onChange={(e) => change('language', e.target.value)}
            disabled={saving || Boolean(topic?.id)}
          >
            {options.languages.map((l) => (
              <MenuItem key={l} value={l}>
                {l}
              </MenuItem>
            ))}
          </TextField>
          {section.resource === 'alphabets' && (
            <TextField
              label="Lesson group"
              value={value.group_name}
              onChange={(e) => change('group_name', e.target.value)}
              disabled={saving}
            />
          )}
          <StandardsSelect
            value={value.standards}
            onChange={(v) => change('standards', v)}
            options={options.standards}
            disabled={saving}
          />
          {topic?.override_count > 0 && (
            <Alert severity="info">
              {topic.override_count} items have their own standard assignments.
              These are preserved unless you select the option below.
            </Alert>
          )}
          {topic?.id && (
            <FormControlLabel
              control={
                <Checkbox
                  checked={apply}
                  onChange={(_, v) => setApply(v)}
                  disabled={saving}
                />
              }
              label="Apply these standards to every existing item"
            />
          )}
          {gated && (
            <TextField
              select
              label="Access"
              value={value.access}
              onChange={(e) => change('access', e.target.value)}
              disabled={saving}
            >
              {(section.resource === 'quizzes'
                ? ['Free', 'Premium']
                : ['Free', 'Login', 'Premium']
              ).map((a) => (
                <MenuItem key={a} value={a}>
                  {a === 'Login' ? 'Login required' : a}
                </MenuItem>
              ))}
            </TextField>
          )}
          {['courses', 'stories', 'phonics'].includes(section.resource) && (
            <MediaField
              field={{
                value: value.image,
                onChange: (v) => change('image', v?.target?.value ?? v),
                onBlur: () => {},
              }}
              label="Topic image"
              image
              disabled={saving}
              onBusy={(busy) =>
                setUploads((n) => Math.max(0, n + (busy ? 1 : -1)))
              }
            />
          )}
          {section.resource === 'stories' && (
            <MediaField
              field={{
                value: value.audio,
                onChange: (v) => change('audio', v?.target?.value ?? v),
                onBlur: () => {},
              }}
              label="Title audio"
              image={false}
              disabled={saving}
              onBusy={(busy) =>
                setUploads((n) => Math.max(0, n + (busy ? 1 : -1)))
              }
            />
          )}
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving || uploads > 0}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={submit}
          disabled={saving || uploads > 0}
        >
          {saving ? 'Saving…' : 'Save topic'}
        </Button>
      </DialogActions>
    </Dialog>
  )
}
