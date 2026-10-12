import { CloudUploadRounded } from '@mui/icons-material'
import { Alert, Box, Button, Stack, TextField } from '@mui/material'
import { useState } from 'react'
import { adminApi } from '../services/adminApi'
import { mediaUrl } from '../services/apiClient'
export default function MediaField({
  field,
  label,
  disabled,
  error,
  image,
  onBusy,
}) {
  const [uploading, setUploading] = useState(false),
    [failure, setFailure] = useState('')
  const upload = async (event) => {
    const file = event.target.files?.[0]
    event.target.value = ''
    if (!file) return
    if (file.size > (image ? 5 : 20) * 1024 * 1024) {
      setFailure(`Choose a file smaller than ${image ? 5 : 20} MB.`)
      return
    }
    setUploading(true)
    onBusy?.(true)
    setFailure('')
    try {
      const item = await adminApi.upload(file)
      if (image !== item.mime_type.startsWith('image/')) {
        setFailure(`Choose an ${image ? 'image' : 'audio'} file.`)
        return
      }
      field.onChange(item.path)
    } catch (e) {
      setFailure(e.response?.data?.message || 'Upload failed. Please retry.')
    } finally {
      setUploading(false)
      onBusy?.(false)
    }
  }
  return (
    <Stack spacing={1}>
      <TextField
        {...field}
        label={label}
        disabled={disabled || uploading}
        fullWidth
        error={Boolean(error)}
        helperText={error || 'Paste a URL or upload a file.'}
      />
      <Stack direction="row" spacing={1} sx={{ alignItems: 'center' }}>
        <Button
          component="label"
          startIcon={<CloudUploadRounded />}
          disabled={disabled || uploading}
          sx={{ minHeight: 44 }}
        >
          {uploading ? 'Uploading…' : 'Upload ' + (image ? 'image' : 'audio')}
          <input
            type="file"
            hidden
            accept={
              image
                ? '.jpg,.jpeg,.png,.webp,.gif'
                : '.mp3,.wav,.ogg,.oga,.opus,.m4a,.aac,.flac'
            }
            onChange={upload}
          />
        </Button>
        {image && field.value && (
          <Box
            component="img"
            src={mediaUrl(field.value)}
            alt={`${label} preview`}
            sx={{
              width: 48,
              height: 48,
              objectFit: 'contain',
              borderRadius: 1,
            }}
          />
        )}
      </Stack>
      {!image && field.value && (
        <Box
          component="audio"
          src={mediaUrl(field.value)}
          controls
          preload="none"
          sx={{ width: '100%' }}
        />
      )}
      {failure && <Alert severity="error">{failure}</Alert>}
    </Stack>
  )
}
