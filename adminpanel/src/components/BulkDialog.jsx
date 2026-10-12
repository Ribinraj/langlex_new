import { DownloadRounded, UploadFileRounded } from '@mui/icons-material'
import {
  Alert,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  MenuItem,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useState } from 'react'
import Papa from 'papaparse'
import toast from 'react-hot-toast'
import {
  adminApi,
  resourceSchemas,
  topicFields,
  humanize,
} from '../services/adminApi'
import AppDataTable from './AppDataTable'
const editableColumns = (resource, operation) =>
  operation === 'topics'
    ? topicFields[resource]
    : resourceSchemas[resource].filter(
        (key) =>
          operation === 'import' || !topicFields[resource]?.includes(key),
      )
function downloadCsv(name, rows) {
  const csv = Papa.unparse(rows, { escapeFormulae: true })
  const url = URL.createObjectURL(
    new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' }),
  )
  const a = document.createElement('a')
  a.href = url
  a.download = name
  a.click()
  URL.revokeObjectURL(url)
}
const compact = (value) =>
  value == null || value === ''
    ? '—'
    : typeof value === 'object'
      ? JSON.stringify(value)
      : String(value)
export default function BulkDialog({
  resource,
  topics,
  rows,
  onClose,
  onSaved,
  scopeTopic,
  columnsOverride,
}) {
  const [operation, setOperation] = useState(topics ? 'topics' : 'import'),
    [csv, setCsv] = useState(''),
    [preview, setPreview] = useState(null),
    [busy, setBusy] = useState(false),
    [error, setError] = useState('')
  const columns = columnsOverride || editableColumns(resource, operation)
  const reset = (v) => {
    setOperation(v)
    setCsv('')
    setPreview(null)
    setError('')
  }
  const download = async () => {
    setBusy(true)
    setError('')
    try {
      if (operation === 'import')
        downloadCsv(`${resource}-import-template.csv`, {
          fields: columns,
          data: [],
        })
      else {
        let source = rows
        if (operation === 'topics') {
          source = []
          for (const row of rows) {
            const data = await adminApi.groupItems(resource, row.id, {
              limit: 1,
            })
            source.push({ ...data.group, id: row.id })
          }
        }
        downloadCsv(
          `${resource}-${operation}-page.csv`,
          source.map((r) =>
            Object.fromEntries(['id', ...columns].map((k) => [k, r[k] ?? ''])),
          ),
        )
      }
    } catch (e) {
      setError(e.response?.data?.message || 'Could not export this page.')
    } finally {
      setBusy(false)
    }
  }
  const read = async (e) => {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file) return
    if (file.size > 1024 * 1024) {
      setError('CSV files can be up to 1 MB.')
      return
    }
    setCsv(await file.text())
    setPreview(null)
    setError('')
  }
  const validate = async () => {
    const parsed = Papa.parse(csv.trim(), {
      header: true,
      skipEmptyLines: 'greedy',
      transformHeader: (h) => h.trim(),
    })
    if (parsed.errors.length) {
      setError(`CSV error: ${parsed.errors[0].message}`)
      return
    }
    if (!parsed.data.length || parsed.data.length > 100) {
      setError('Include between 1 and 100 rows.')
      return
    }
    setBusy(true)
    setError('')
    try {
      setPreview(
        await adminApi.previewBulk(
          scopeTopic ? `topic:${scopeTopic.id}` : resource,
          { operation, rows: parsed.data },
        ),
      )
    } catch (e) {
      setError(
        e.response?.data?.message ||
          'Could not validate CSV. No changes saved.',
      )
    } finally {
      setBusy(false)
    }
  }
  const apply = async () => {
    setBusy(true)
    setError('')
    try {
      const result = await adminApi.applyBulk(preview.id)
      toast.success(
        `${result.count} ${operation === 'import' ? 'records imported' : 'changes saved'}`,
      )
      onSaved()
      onClose()
    } catch (e) {
      setError(
        e.response?.data?.message ||
          'Could not apply this batch. No partial changes were saved.',
      )
    } finally {
      setBusy(false)
    }
  }
  return (
    <Dialog open maxWidth="md" fullWidth onClose={busy ? undefined : onClose}>
      <DialogTitle>
        Bulk tools · {scopeTopic?.title || humanize(resource)}
      </DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2}>
          {scopeTopic && (
            <Alert severity="info">
              New items inherit this topic’s language and standards. Existing
              item assignments are preserved.
            </Alert>
          )}
          {!preview ? (
            <>
              <TextField
                select
                label="Action"
                value={operation}
                onChange={(e) => reset(e.target.value)}
                disabled={busy}
              >
                {topics ? (
                  <MenuItem value="topics">Edit entire topics</MenuItem>
                ) : (
                  [
                    <MenuItem key="import" value="import">
                      Import new records
                    </MenuItem>,
                    <MenuItem key="edit" value="edit">
                      Edit existing records
                    </MenuItem>,
                  ]
                )}
              </TextField>
              <Typography variant="body2" color="text.secondary">
                {operation === 'import'
                  ? 'Download the template, fill it in and upload your CSV. Imports add new records.'
                  : 'Download this page, keep the IDs and change the values you need. Remove rows or columns you do not want to change.'}{' '}
                Up to 100 rows per batch.{' '}
                {operation === 'edit'
                  ? 'Shared titles, languages and access are edited in Topics view.'
                  : ''}
              </Typography>
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1}>
                <Button
                  startIcon={<DownloadRounded />}
                  onClick={download}
                  disabled={busy}
                >
                  {operation === 'import'
                    ? 'Download template'
                    : 'Download current page'}
                </Button>
                <Button
                  component="label"
                  startIcon={<UploadFileRounded />}
                  disabled={busy}
                >
                  Choose CSV
                  <input
                    type="file"
                    hidden
                    accept=".csv,text/csv"
                    onChange={read}
                  />
                </Button>
              </Stack>
              <TextField
                multiline
                minRows={8}
                maxRows={16}
                label="CSV contents"
                value={csv}
                onChange={(e) => {
                  setCsv(e.target.value)
                  setError('')
                }}
                disabled={busy}
                slotProps={{ htmlInput: { maxLength: 1048576 } }}
                helperText="Blank cells clear values. Remove a column to leave it unchanged when editing."
              />
              <Alert severity="info">
                All rows are validated together. Nothing is saved until you
                review the preview and apply it.
              </Alert>
            </>
          ) : (
            <>
              <Alert severity="success">
                {preview.count} rows validated. Review the changes before
                applying. This preview expires in 15 minutes.
              </Alert>
              <AppDataTable
                rows={preview.changes}
                getRowId={(r) => r.row}
                columns={[
                  { key: 'row', label: 'CSV row', minWidth: 80 },
                  {
                    key: 'id',
                    label: 'Record ID',
                    minWidth: 90,
                    render: (r) => (operation === 'import' ? 'New' : r.id),
                  },
                  {
                    key: 'after',
                    label: 'Changes',
                    minWidth: 300,
                    render: (r) => {
                      const before = r.before?.group || r.before || {},
                        after = r.after?.group || r.after || {}
                      return (
                        <Stack spacing={1}>
                          {Object.keys(after)
                            .filter(
                              (k) =>
                                k !== 'id' &&
                                compact(before[k]) !== compact(after[k]),
                            )
                            .map((k) => (
                              <Box key={k}>
                                <Typography variant="caption" fontWeight={700}>
                                  {humanize(k)}
                                </Typography>
                                <Typography
                                  variant="body2"
                                  sx={{ overflowWrap: 'anywhere' }}
                                >
                                  {compact(before[k])} → {compact(after[k])}
                                </Typography>
                              </Box>
                            ))}
                        </Stack>
                      )
                    },
                  },
                ]}
              />
            </>
          )}
          {error && <Alert severity="error">{error}</Alert>}
        </Stack>
      </DialogContent>
      <DialogActions sx={{ flexWrap: 'wrap', gap: 1 }}>
        <Button disabled={busy} onClick={onClose}>
          Cancel
        </Button>
        {preview ? (
          <>
            <Button disabled={busy} onClick={() => setPreview(null)}>
              Back to CSV
            </Button>
            <Button variant="contained" disabled={busy} onClick={apply}>
              {busy
                ? 'Applying…'
                : `Apply ${preview.count} ${operation === 'import' ? 'new records' : 'changes'}`}
            </Button>
          </>
        ) : (
          <Button
            variant="contained"
            disabled={busy || !csv.trim()}
            onClick={validate}
          >
            {busy ? 'Validating…' : 'Preview changes'}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  )
}
