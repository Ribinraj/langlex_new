import {
  Alert,
  Autocomplete,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useCallback, useEffect, useState } from 'react'
import { Controller, useForm, useWatch } from 'react-hook-form'
import MediaField from './MediaField'
import { apiClient } from '../services/apiClient'
import { useAsyncData } from '../hooks/useAsyncData'
import { adminApi, humanize, relationshipFields } from '../services/adminApi'

const databaseChoices = new Set([
  'language',
  'Language',
  'show_plan',
  'level',
  'grade',
  'difflvl',
  'letter_type',
  'QType',
  'type',
  'plan_timeperiod',
])
const optionLabel = (value) =>
  value === 'Login'
    ? 'Login required'
    : value === 'MCQ'
      ? 'Multiple choice (MCQ)'
      : value
export default function ResourceDialog({
  open,
  title,
  columns,
  item,
  resource,
  onClose,
  onSubmit,
  saving,
  lockedFields = [],
  primaryField,
  description,
  extraContent,
  onEditTopic,
}) {
  const [uploads, setUploads] = useState(0)
  const uploadBusy = useCallback(
    (busy) => setUploads((n) => Math.max(0, n + (busy ? 1 : -1))),
    [],
  )
  const {
    control,
    reset,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm({ defaultValues: defaults(columns, item) })
  useEffect(() => {
    reset(defaults(columns, item))
  }, [columns, item, reset])
  const language =
    useWatch({
      control,
      name: columns.includes('Language') ? 'Language' : 'language',
    }) ||
    item?.language ||
    item?.Language ||
    ''
  const loader = useCallback(
    () =>
      open
        ? adminApi.formOptions(resource, language)
        : Promise.resolve({ options: {} }),
    [open, resource, language],
  )
  const { data, loading, error, reload } = useAsyncData(loader)
  const submit = async (values) => {
    const primary =
      primaryField ||
      {
        content: 'content',
        alphabets: 'letter',
        quizzes: 'Question',
        phonics: 'word',
        plans: 'name',
      }[resource] ||
      'title'
    if (
      columns.includes(primary) &&
      !lockedFields.includes(primary) &&
      !String(values[primary] || '').trim()
    ) {
      setError(primary, { message: 'This field is required.' })
      return
    }
    if (
      resource === 'quizzes' &&
      columns.includes('Question') &&
      (!values.ca?.trim() ||
        new Set(
          [values.ca, values.o1, values.o2, values.o3]
            .map((value) => value?.trim())
            .filter(Boolean),
        ).size < 2)
    ) {
      setError('ca', {
        message: 'Add a correct answer and at least one different alternative.',
      })
      return
    }
    return onSubmit(
      Object.fromEntries(
        Object.entries(values).filter(([key]) => !lockedFields.includes(key)),
      ),
    )
  }
  return (
    <Dialog
      open={open}
      onClose={saving || uploads ? undefined : onClose}
      maxWidth="md"
      fullWidth
    >
      <DialogTitle>{title}</DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2} sx={{ pt: 0.5 }}>
          {resource === 'plans' && (
            <Alert severity="info">
              Free plans provide free content. Premium plans unlock all content
              marked Premium. Access is based on an active subscription; there
              are no separate course or quiz permissions.
            </Alert>
          )}
          {description && (
            <Typography variant="body2" color="text.secondary">
              {description}
            </Typography>
          )}
          {lockedFields.length > 0 && (
            <Alert
              severity="info"
              action={
                onEditTopic && (
                  <Button
                    disabled={saving || uploads > 0}
                    onClick={onEditTopic}
                  >
                    Edit topic
                  </Button>
                )
              }
            >
              Title, language and access are managed for the whole topic.
            </Alert>
          )}
          {error && (
            <Alert
              severity="error"
              action={<Button onClick={reload}>Retry</Button>}
            >
              {error}
            </Alert>
          )}
          {extraContent}
          <Grid container spacing={2}>
            {columns
              .filter((column) => !lockedFields.includes(column))
              .map((column) => (
                <Grid
                  key={column}
                  size={{
                    xs: 12,
                    md: [
                      'text',
                      'Question',
                      'sentence',
                      'audio_text_map',
                    ].includes(column)
                      ? 12
                      : 6,
                  }}
                >
                  <Controller
                    name={column}
                    control={control}
                    render={({ field }) => (
                      <SmartField
                        onBusy={uploadBusy}
                        field={field}
                        plainText={column === primaryField}
                        column={column}
                        resource={resource}
                        language={language}
                        options={data?.options?.[column] || []}
                        loading={loading}
                        disabled={saving || lockedFields.includes(column)}
                        error={errors[column]?.message}
                      />
                    )}
                  />
                </Grid>
              ))}
          </Grid>
        </Stack>
      </DialogContent>
      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} disabled={saving || uploads > 0}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit(submit)}
          disabled={saving || uploads > 0 || loading || Boolean(error)}
        >
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </DialogActions>
    </Dialog>
  )
}
function SmartField({
  onBusy,
  plainText,
  field,
  column,
  resource,
  language,
  options,
  loading,
  disabled,
  error,
}) {
  const label = humanize(column),
    value = field.value ?? ''
  if (column !== 'audio_text_map' && /image|audio|sound/.test(column))
    return (
      <MediaField
        field={field}
        label={label}
        disabled={disabled}
        error={error}
        image={column.includes('image')}
        onBusy={onBusy}
      />
    )
  if (databaseChoices.has(column)) {
    const choices = [...new Set([...options, ...(value ? [value] : [])])]
    return (
      <Autocomplete
        options={choices}
        disableClearable={['show_plan', 'language', 'Language'].includes(
          column,
        )}
        value={value || null}
        disabled={disabled}
        loading={loading}
        getOptionLabel={optionLabel}
        onChange={(_, next) => field.onChange(next || '')}
        onBlur={field.onBlur}
        renderInput={(params) => (
          <TextField
            {...params}
            label={label}
            inputRef={field.ref}
            error={Boolean(error)}
            helperText={
              error ||
              (column === 'difflvl'
                ? 'Original academic level, as used by the app.'
                : 'Available values from the database.')
            }
          />
        )}
      />
    )
  }
  if (!plainText && relationshipFields.has(column))
    return (
      <ReferenceField
        field={field}
        resource={resource}
        column={column}
        language={language}
        disabled={disabled}
        error={error}
      />
    )
  return (
    <TextField
      {...field}
      label={label}
      fullWidth
      disabled={disabled}
      type={
        column === 'amount'
          ? 'number'
          : column === 'created' && /^\d{4}-\d{2}-\d{2}$/.test(value)
            ? 'date'
            : 'text'
      }
      slotProps={{
        inputLabel: column === 'created' ? { shrink: true } : undefined,
        htmlInput: column === 'amount' ? { min: 0, step: 0.01 } : undefined,
      }}
      multiline={[
        'text',
        'Question',
        'sentence',
        'audio_text_map',
        'Instruction',
        'RAFeed',
        'WAFeed',
      ].includes(column)}
      minRows={column === 'text' ? 5 : undefined}
      error={Boolean(error)}
      helperText={
        error ||
        (column.includes('image')
          ? 'Image URL or /media/ path.'
          : column.includes('audio') || column.includes('sound')
            ? 'Audio URL or /media/ path.'
            : column === 'amount'
              ? 'Price in INR. Free plans must be ₹0.'
              : '')
      }
    />
  )
}
function ReferenceField({
  field,
  resource,
  column,
  language,
  disabled,
  error,
}) {
  const [search, setSearch] = useState(''),
    [query, setQuery] = useState(''),
    [page, setPage] = useState(1)
  useEffect(() => {
    const timer = setTimeout(() => {
      setQuery(search)
      setPage(1)
    }, 300)
    return () => clearTimeout(timer)
  }, [search, language])
  const loader = useCallback(
    async () =>
      disabled
        ? { items: [], pagination: {} }
        : (
            await apiClient.get(
              `/admin/reference-options/${resource}/${column}`,
              { params: { language, search: query, page, limit: 20 } },
            )
          ).data,
    [resource, column, language, query, page, disabled],
  )
  const { data, loading, error: loadError, reload } = useAsyncData(loader)
  return (
    <Stack spacing={0.5}>
      <Autocomplete
        freeSolo
        disabled={disabled}
        options={data?.items || []}
        filterOptions={(options) => options}
        value={field.value || ''}
        loading={loading}
        onBlur={field.onBlur}
        onChange={(_, value) => field.onChange(value || '')}
        onInputChange={(_, value, reason) => {
          if (reason === 'input' || reason === 'clear') {
            setSearch(value)
            field.onChange(value)
          }
        }}
        renderInput={(params) => (
          <TextField
            {...params}
            inputRef={field.ref}
            label={humanize(column)}
            error={Boolean(error || loadError)}
            helperText={
              error || loadError || 'Choose a matching name or enter a new one.'
            }
          />
        )}
      />
      {loadError ? (
        <Button onClick={reload}>Retry</Button>
      ) : (
        !disabled &&
        (data?.pagination?.total > 20 || page > 1) && (
          <Stack
            direction="row"
            sx={{ alignItems: 'center', justifyContent: 'space-between' }}
          >
            <Button
              disabled={loading || page <= 1}
              onClick={() => setPage(page - 1)}
            >
              Previous
            </Button>
            <Typography variant="caption">Page {page}</Typography>
            <Button
              disabled={loading || !data?.pagination?.has_more}
              onClick={() => setPage(page + 1)}
            >
              Next
            </Button>
          </Stack>
        )
      )}
    </Stack>
  )
}
function defaults(columns, item) {
  return Object.fromEntries(
    columns.map((column) => [
      column,
      item?.[column] == null
        ? column === 'created'
          ? new Date().toISOString().slice(0, 10)
          : column === 'show_plan'
            ? 'Free'
            : column === 'amount'
              ? '0'
              : ''
        : String(item[column]),
    ]),
  )
}
