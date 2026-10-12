import { useEffect } from 'react'
import {
  IconButton,
  Button,
  Paper,
  Skeleton,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  Tooltip,
} from '@mui/material'
import EmptyState from './EmptyState'
export default function AppDataTable({
  columns,
  rows = [],
  loading,
  error,
  onRetry,
  emptyMessage = 'No records found',
  emptyDescription,
  page = 1,
  limit = 10,
  total,
  onPageChange,
  onLimitChange,
  actions = [],
  getRowId = (row) => row.id,
}) {
  const lastPage = Math.max(1, Math.ceil((total || 0) / limit))
  useEffect(() => {
    if (!loading && !error && typeof total === 'number' && page > lastPage)
      onPageChange?.(lastPage)
  }, [loading, error, total, page, lastPage, onPageChange])
  const allColumns = actions.length
    ? [...columns, { key: '_actions', label: 'Actions' }]
    : columns
  return (
    <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
      <TableContainer sx={{ maxWidth: '100%' }} aria-busy={Boolean(loading)}>
        <Table size="small" stickyHeader>
          <TableHead>
            <TableRow>
              {allColumns.map((column) => (
                <TableCell
                  key={column.key}
                  align={column.key === '_actions' ? 'right' : undefined}
                  sx={{ minWidth: column.minWidth ?? 120 }}
                >
                  {column.label}
                </TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {loading
              ? Array.from({ length: 5 }, (_, index) => (
                  <TableRow key={index}>
                    {allColumns.map((column) => (
                      <TableCell key={column.key}>
                        <Skeleton
                          animation="wave"
                          height={32}
                          sx={{ minWidth: 70, maxWidth: 210 }}
                        />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              : error || !rows.length
                ? null
                : rows.map((row) => (
                    <TableRow hover key={getRowId(row)}>
                      {columns.map((column) => (
                        <TableCell
                          key={column.key}
                          sx={{
                            maxWidth: column.maxWidth || 360,
                            overflowWrap: 'anywhere',
                          }}
                        >
                          {column.render
                            ? column.render(row)
                            : safeText(row[column.key])}
                        </TableCell>
                      ))}
                      {!!actions.length && (
                        <TableCell align="right">
                          <Stack
                            direction="row"
                            spacing={0.25}
                            sx={{ justifyContent: 'flex-end' }}
                          >
                            {actions.map((action) => (
                              <Tooltip key={action.label} title={action.label}>
                                <span>
                                  {action.showLabel ? (
                                    <Button
                                      size="small"
                                      startIcon={action.icon}
                                      onClick={() => action.onClick(row)}
                                      disabled={action.disabled?.(row)}
                                      sx={{
                                        whiteSpace: 'nowrap',
                                        minHeight: 44,
                                      }}
                                    >
                                      {action.label}
                                    </Button>
                                  ) : (
                                    <IconButton
                                      aria-label={`${action.label} ${row.title || row.full_name || `record ${row.id}`}`}
                                      color={action.color || 'default'}
                                      onClick={() => action.onClick(row)}
                                      disabled={action.disabled?.(row)}
                                    >
                                      {action.icon}
                                    </IconButton>
                                  )}
                                </span>
                              </Tooltip>
                            ))}
                          </Stack>
                        </TableCell>
                      )}
                    </TableRow>
                  ))}
          </TableBody>
        </Table>
      </TableContainer>
      {!loading && (error || !rows.length) && (
        <EmptyState
          title={emptyMessage}
          description={emptyDescription}
          error={error}
          onRetry={error ? onRetry : undefined}
        />
      )}
      {typeof total === 'number' && !error && (
        <TablePagination
          component="div"
          count={total}
          page={Math.min(Math.max(page - 1, 0), lastPage - 1)}
          rowsPerPage={limit}
          onPageChange={(_, next) => onPageChange(next + 1)}
          onRowsPerPageChange={(event) =>
            onLimitChange(Number(event.target.value))
          }
          rowsPerPageOptions={[10, 25, 50, 100]}
        />
      )}
    </Paper>
  )
}
function safeText(value) {
  return value == null || value === ''
    ? '—'
    : typeof value === 'object'
      ? JSON.stringify(value)
      : String(value)
}
