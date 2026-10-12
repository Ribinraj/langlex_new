import { Alert, Stack, TextField } from '@mui/material'
import { useState } from 'react'
import toast from 'react-hot-toast'
import ConfirmDialog from './ConfirmDialog'
import { adminApi } from '../services/adminApi'
export default function AccountAccessDialog({ user, onClose, onSaved }) {
  const [reason, setReason] = useState(''),
    [saving, setSaving] = useState(false),
    [error, setError] = useState('')
  const blocked = !user.is_blocked
  const save = async () => {
    if (reason.trim().length < 3) {
      setError('Add a reason with at least 3 characters.')
      return
    }
    setSaving(true)
    try {
      await adminApi.setAccess(user.id, { blocked, reason: reason.trim() })
      toast.success(blocked ? 'Account blocked' : 'Account unblocked')
      onSaved()
      onClose()
    } catch (e) {
      setError(e.response?.data?.message || 'Could not update account.')
    } finally {
      setSaving(false)
    }
  }
  return (
    <ConfirmDialog
      open
      title={`${blocked ? 'Block' : 'Unblock'} ${user.full_name}?`}
      confirmLabel={blocked ? 'Block account' : 'Unblock account'}
      confirmColor={blocked ? 'error' : 'primary'}
      loading={saving}
      onClose={onClose}
      onConfirm={save}
      body={
        <Stack spacing={2}>
          <Alert severity={blocked ? 'warning' : 'info'}>
            {blocked
              ? 'This learner will lose access on their next app request. Their progress and subscription dates will be kept.'
              : 'This learner can sign in again. Their existing subscription dates remain unchanged.'}
          </Alert>
          {user.block_reason && (
            <Alert severity="info">Previous reason: {user.block_reason}</Alert>
          )}
          <TextField
            label="Reason for this change"
            multiline
            minRows={2}
            required
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            error={Boolean(error)}
            helperText={error || 'Saved in audit history.'}
            slotProps={{ htmlInput: { maxLength: 500 } }}
          />
        </Stack>
      }
    />
  )
}
