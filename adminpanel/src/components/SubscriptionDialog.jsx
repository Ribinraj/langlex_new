import {
  Alert,
  Autocomplete,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useCallback, useState } from 'react'
import toast from 'react-hot-toast'
import { adminApi } from '../services/adminApi'
import { useAsyncData } from '../hooks/useAsyncData'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
const localDate = (value) => {
  const d = new Date(value)
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16)
}
export default function SubscriptionDialog({
  user,
  subscription,
  action = 'grant',
  onClose,
  onSaved,
}) {
  const [learner, setLearner] = useState(user || null),
    [search, setSearch] = useState(''),
    [plan, setPlan] = useState(null)
  const [expiry, setExpiry] = useState(
      localDate(subscription?.expires_at || Date.now() + 30 * 86400000),
    ),
    [reason, setReason] = useState(''),
    [saving, setSaving] = useState(false),
    [error, setError] = useState('')
  const query = useDebouncedValue(search)
  const loadUsers = useCallback(
    () =>
      !user && action === 'grant'
        ? adminApi.users({ search: query, limit: 20 })
        : Promise.resolve({ items: [] }),
    [user, action, query],
  )
  const users = useAsyncData(loadUsers)
  const loadPlans = useCallback(async () => {
    if (action !== 'grant') return []
    const all = []
    let page = 1,
      result
    do {
      result = await adminApi.resource('plans', { page, limit: 100 })
      all.push(...result.items)
      page++
    } while (all.length < result.total)
    return all.filter((p) => p.type?.toLowerCase() === 'premium')
  }, [action])
  const plans = useAsyncData(loadPlans)
  const cancel = action === 'cancel'
  const save = async () => {
    if (reason.trim().length < 3) {
      setError('Add a reason with at least 3 characters.')
      return
    }
    if (!cancel && (!expiry || new Date(expiry) <= new Date())) {
      setError('Choose an expiry in the future.')
      return
    }
    if (action === 'grant' && (!learner || !plan)) {
      setError('Choose a learner and a Premium plan.')
      return
    }
    setSaving(true)
    setError('')
    try {
      const body = {
        reason: reason.trim(),
        ...(!cancel ? { expires_at: new Date(expiry).toISOString() } : {}),
      }
      if (action === 'grant')
        await adminApi.grantSubscription(learner.id, {
          ...body,
          plan_id: plan.id,
        })
      else
        await adminApi.manageSubscription(subscription.id, { ...body, action })
      toast.success(cancel ? 'Subscription cancelled' : 'Subscription saved')
      onSaved()
      onClose()
    } catch (e) {
      setError(e.response?.data?.message || 'Could not save subscription.')
    } finally {
      setSaving(false)
    }
  }
  return (
    <Dialog open fullWidth maxWidth="sm" onClose={saving ? undefined : onClose}>
      <DialogTitle>
        {cancel
          ? 'Cancel subscription'
          : action === 'grant'
            ? 'Grant Premium access'
            : 'Change subscription expiry'}
      </DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2}>
          <Typography>
            {user?.full_name ||
              subscription?.full_name ||
              'Choose the learner and access period.'}
          </Typography>
          {Boolean(learner?.is_blocked) && <Alert severity="warning">This account is blocked. The learner must be unblocked before they can use Premium access.</Alert>}
          <Alert severity={cancel ? 'warning' : 'info'}>
            {cancel
              ? 'Premium access ends immediately. Progress and payment records are kept. This does not issue a refund.'
              : action === 'grant'
                ? 'Access starts now and replaces any active or scheduled subscription. No payment is recorded.'
                : 'Only the access expiry changes. Payment records are kept.'}
          </Alert>
          {action === 'grant' && !user && (
            <Autocomplete
              options={users.data?.items || []}
              filterOptions={(x) => x}
              value={learner}
              loading={users.loading}
              isOptionEqualToValue={(a, b) => a.id === b.id}
              getOptionLabel={(u) => `${u.full_name} · ${u.mobile_number}`}
              onInputChange={(_, v, why) => {
                if (why === 'input') setSearch(v)
              }}
              onChange={(_, v) => setLearner(v)}
              renderInput={(p) => <TextField {...p} required label="Learner" />}
            />
          )}
          {action === 'grant' && (
            <Autocomplete
              options={plans.data || []}
              value={plan}
              loading={plans.loading}
              isOptionEqualToValue={(a, b) => a.id === b.id}
              getOptionLabel={(p) => `${p.name} · ${p.plan_timeperiod}`}
              onChange={(_, v) => setPlan(v)}
              renderInput={(p) => (
                <TextField {...p} required label="Premium plan" />
              )}
            />
          )}
          {(users.error || plans.error) && (
            <Alert
              severity="error"
              action={
                <Button
                  onClick={() => {
                    users.reload()
                    plans.reload()
                  }}
                >
                  Retry
                </Button>
              }
            >
              {users.error || plans.error}
            </Alert>
          )}
          {!cancel && (
            <TextField
              required
              type="datetime-local"
              label="Access expires at"
              value={expiry}
              onChange={(e) => setExpiry(e.target.value)}
              slotProps={{ inputLabel: { shrink: true } }}
              helperText="Your local time. Choose a date and time in the future."
            />
          )}
          <TextField
            required
            label="Reason for this change"
            multiline
            minRows={2}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            slotProps={{ htmlInput: { maxLength: 500 } }}
            helperText="Saved in audit history."
          />
          {error && <Alert severity="error">{error}</Alert>}
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button disabled={saving} onClick={onClose}>
          Cancel
        </Button>
        <Button
          variant="contained"
          color={cancel ? 'error' : 'primary'}
          disabled={
            saving || plans.loading || Boolean(plans.error || users.error)
          }
          onClick={save}
        >
          {saving ? 'Saving…' : cancel ? 'End Premium access' : 'Save access'}
        </Button>
      </DialogActions>
    </Dialog>
  )
}
