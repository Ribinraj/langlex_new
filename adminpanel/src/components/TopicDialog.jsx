import { Dialog, DialogContent, DialogTitle, Skeleton } from '@mui/material'
import { useCallback } from 'react'
import { useAsyncData } from '../hooks/useAsyncData'
import { adminApi } from '../services/adminApi'
import ResourceDialog from './ResourceDialog'
import EmptyState from './EmptyState'

import { topicFields } from '../services/adminApi'
export default function TopicDialog({
  resource,
  topic,
  saving,
  onClose,
  onSubmit,
}) {
  const load = useCallback(
    () => adminApi.groupItems(resource, topic.id, { limit: 1 }),
    [resource, topic.id],
  )
  const { data, loading, error, reload } = useAsyncData(load)
  if (!data || loading || error)
    return (
      <Dialog open fullWidth maxWidth="md" onClose={onClose}>
        <DialogTitle>Edit topic</DialogTitle>
        <DialogContent>
          {error ? (
            <EmptyState error={error} onRetry={reload} />
          ) : (
            <Skeleton variant="rounded" height={260} />
          )}
        </DialogContent>
      </Dialog>
    )
  return (
    <ResourceDialog
      open
      resource={resource}
      title="Edit topic"
      columns={topicFields[resource]}
      primaryField={topicFields[resource][0]}
      item={data.group}
      saving={saving}
      onClose={onClose}
      onSubmit={onSubmit}
      description="Changes apply to every item in this topic."
    />
  )
}
