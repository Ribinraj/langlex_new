import { zodResolver } from '@hookform/resolvers/zod'
import {
  Autocomplete,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  TextField,
} from '@mui/material'
import { useEffect } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { z } from 'zod'
import { fixedFieldOptions, humanize, jsonColumns, relationshipFields } from '../services/adminApi'

const schema = z.record(z.string(), z.any())

export default function ResourceDialog({
  open,
  title,
  columns,
  item,
  resource,
  optionSets = {},
  onClose,
  onSubmit,
  saving,
}) {
  const {
    control,
    reset,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
    defaultValues: buildDefaults(columns, item),
  })

  useEffect(() => {
    reset(buildDefaults(columns, item))
  }, [columns, item, reset])

  const submit = (values) => {
    const payload = { ...values }
    for (const column of columns) {
      if (jsonColumns.has(column)) {
        try {
          payload[column] =
            typeof values[column] === 'string' ? JSON.parse(values[column] || '{}') : values[column]
        } catch {
          payload[column] = values[column] || '{}'
        }
      }
    }
    onSubmit(payload)
  }

  return (
    <Dialog open={open} onClose={saving ? undefined : onClose} maxWidth="md" fullWidth>
      <DialogTitle>{title}</DialogTitle>
      <DialogContent dividers>
        <Grid container spacing={2} sx={{ pt: 0.5 }}>
          {columns.map((column) => {
            const large = column === 'text' || column.includes('audio') || column.includes('image')
            return (
              <Grid key={column} size={{ xs: 12, md: large ? 12 : 6 }}>
                <Controller
                  name={column}
                  control={control}
                  render={({ field }) => (
                    <SmartField
                      column={column}
                      field={field}
                      large={large}
                      resource={resource}
                      optionSets={optionSets}
                      error={Boolean(errors[column])}
                      helperText={errors[column]?.message}
                    />
                  )}
                />
              </Grid>
            )
          })}
        </Grid>
      </DialogContent>
      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} disabled={saving}>
          Cancel
        </Button>
        <Button variant="contained" onClick={handleSubmit(submit)} disabled={saving}>
          {saving ? 'Saving...' : 'Save'}
        </Button>
      </DialogActions>
    </Dialog>
  )
}

function SmartField({ column, field, large, resource, optionSets, error, helperText }) {
  const fixedOptions = fixedFieldOptions[column]
  const relationshipOptions = relationshipFields.has(column)
    ? optionsForRelationship(column, resource, optionSets)
    : []
  const label = humanize(column)
  const value = field.value ?? ''

  if (fixedOptions) {
    const options = normalizeOptions(fixedOptions)
    return (
      <Autocomplete
        options={options}
        value={options.find((option) => option.value === value) || null}
        onChange={(_, option) => field.onChange(option?.value || '')}
        isOptionEqualToValue={(option, selected) => option.value === selected.value}
        renderInput={(params) => (
          <TextField
            {...params}
            label={label}
            fullWidth
            error={error}
            helperText={helperText || helperFor(column)}
          />
        )}
      />
    )
  }

  if (relationshipOptions.length > 0) {
    return (
      <Autocomplete
        freeSolo
        options={relationshipOptions}
        value={value}
        onChange={(_, option) => field.onChange(option || '')}
        onInputChange={(_, option) => field.onChange(option || '')}
        renderInput={(params) => (
          <TextField
            {...params}
            label={label}
            fullWidth
            error={error}
            helperText={helperText || 'Pick an existing value to avoid spelling mismatches.'}
          />
        )}
      />
    )
  }

  return (
    <TextField
      label={label}
      fullWidth
      type={fieldType(column)}
      multiline={large || jsonColumns.has(column)}
      minRows={column === 'text' ? 5 : jsonColumns.has(column) ? 4 : 1}
      error={error}
      helperText={helperText || helperFor(column)}
      {...field}
    />
  )
}

function optionsForRelationship(column, resource, optionSets) {
  if (column === 'p_cat' || column === 'category') return optionSets.categories || []
  if (column === 'subcategory') return optionSets.subcategories || []
  if (column === 'course' || column === 'coursename') return optionSets.courses || []
  if (column === 'topic') {
    return [...new Set([...(optionSets.subcategories || []), ...(optionSets.categories || [])])].sort()
  }
  return optionSets[resource] || []
}

function normalizeOptions(options) {
  return options.map((option) =>
    typeof option === 'string' ? { value: option, label: option } : option,
  )
}

function fieldType(column) {
  if (column === 'created') return 'date'
  if (column === 'amount') return 'number'
  return 'text'
}

function helperFor(column) {
  if (column === 'show_plan') return 'Free content is visible without subscription.'
  if (column === 'amount') return 'Subscription amount in INR.'
  if (column.includes('image')) return 'Use /media/... or a full image URL.'
  if (column.includes('audio') || column.includes('sound')) return 'Use /media/... or a full audio URL.'
  if (jsonColumns.has(column)) return 'Stored as JSON. Choose a preset or edit carefully.'
  return ''
}

function buildDefaults(columns, item) {
  return Object.fromEntries(
    columns.map((column) => {
      const value = item?.[column]
      if (jsonColumns.has(column)) {
        return [column, typeof value === 'string' ? value : JSON.stringify(value || {}, null, 2)]
      }
      return [column, value == null ? defaultValue(column) : String(value)]
    }),
  )
}

function defaultValue(column) {
  if (column === 'created') return new Date().toISOString().slice(0, 10)
  if (column === 'show_plan') return '0'
  if (column === 'Language' || column === 'language') return 'English'
  if (column === 'QType') return 'mcq'
  if (column === 'difflvl') return 'easy'
  if (column === 'type') return 'paid'
  if (column === 'amount') return '0'
  if (column === 'plan_timeperiod') return '30 days'
  return ''
}
