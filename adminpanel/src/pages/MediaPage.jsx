import { CloudUploadRounded, ContentCopyRounded } from '@mui/icons-material'
import { Alert, Avatar, Box, Button } from '@mui/material'
import { useCallback, useState } from 'react'
import toast from 'react-hot-toast'
import AppDataTable from '../components/AppDataTable'
import PageHeader from '../components/PageHeader'
import DataToolbar from '../components/DataToolbar'
import { adminApi } from '../services/adminApi'
import { mediaUrl } from '../services/apiClient'
import { formatDateTime } from '../utils/formatters'
import { useAsyncData } from '../hooks/useAsyncData'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
export default function MediaPage() {
  const [search, setSearch] = useState(''),
    [page, setPage] = useState(1),
    [limit, setLimit] = useState(25),
    [busy, setBusy] = useState(false),
    [failure, setFailure] = useState('')
  const query = useDebouncedValue(search)
  const load = useCallback(
    () => adminApi.media({ page, limit, search: query }),
    [page, limit, query],
  )
  const { data, loading, error, reload } = useAsyncData(load)
  const upload = async (e) => {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file) return
    setBusy(true)
    setFailure('')
    try {
      await adminApi.upload(file)
      toast.success('Media uploaded')
      setPage(1)
      reload()
    } catch (e) {
      setFailure(e.response?.data?.message || 'Upload failed.')
    } finally {
      setBusy(false)
    }
  }
  return (
    <>
      <PageHeader
        title="Media library"
        subtitle="Upload images and audio, then use their paths in your learning content."
      />
      <Button
        component="label"
        variant="contained"
        startIcon={<CloudUploadRounded />}
        disabled={busy}
        sx={{ mb: 2 }}
      >
        {busy ? 'Uploading…' : 'Upload media'}
        <input
          hidden
          type="file"
          accept=".jpg,.jpeg,.png,.webp,.gif,.mp3,.wav,.ogg,.oga,.opus,.m4a,.aac,.flac"
          onChange={upload}
        />
      </Button>
      <Alert severity="info" sx={{ mb: 2 }}>
        Images up to 5 MB; audio up to 20 MB. Uploaded media is public. Use this
        library for learning content.
      </Alert>
      {failure && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {failure}
        </Alert>
      )}
      <DataToolbar
        search={search}
        onSearch={(v) => {
          setSearch(v)
          setPage(1)
        }}
        placeholder="Search uploaded files"
      />
      <AppDataTable
        rows={data?.items || []}
        loading={loading}
        error={error}
        onRetry={reload}
        page={page}
        limit={limit}
        total={data?.total || 0}
        onPageChange={setPage}
        onLimitChange={(v) => {
          setLimit(v)
          setPage(1)
        }}
        emptyMessage="Your uploads will appear here"
        columns={[
          {
            key: 'preview',
            label: 'Preview',
            minWidth: 100,
            render: (r) =>
              r.mime_type.startsWith('image/') ? (
                <Avatar
                  variant="rounded"
                  src={mediaUrl(r.path)}
                  alt={r.original_name}
                  sx={{ width: 64, height: 64 }}
                />
              ) : (
                <Box
                  component="audio"
                  controls
                  preload="none"
                  src={mediaUrl(r.path)}
                  sx={{ width: 220 }}
                />
              ),
          },
          { key: 'original_name', label: 'File', minWidth: 180 },
          { key: 'mime_type', label: 'Type', minWidth: 100 },
          {
            key: 'size_bytes',
            label: 'Size',
            minWidth: 90,
            render: (r) => `${(r.size_bytes / 1024).toFixed(1)} KB`,
          },
          {
            key: 'created_at',
            label: 'Uploaded',
            minWidth: 155,
            render: (r) => formatDateTime(r.created_at),
          },
        ]}
        actions={[
          {
            label: 'Copy path',
            showLabel: true,
            icon: <ContentCopyRounded />,
            onClick: async (r) => {
              try {
                await navigator.clipboard.writeText(r.path)
                toast.success('Path copied')
              } catch {
                toast.error(
                  'Clipboard unavailable. Use the upload field in the content editor.',
                )
              }
            },
          },
        ]}
      />
    </>
  )
}
