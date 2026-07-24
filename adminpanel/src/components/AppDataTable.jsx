import {
  Box,
  CircularProgress,
  IconButton,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  Tooltip,
  Typography,
} from '@mui/material'

export default function AppDataTable({
  columns,
  rows = [],
  loading,
  emptyMessage = 'No records found',
  page,
  limit,
  total,
  onPageChange,
  onLimitChange,
  actions = [],
  getRowId = (row) => row.id,
}) {
  return (
    <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
      <TableContainer sx={{ maxWidth: '100%', minHeight: loading ? 360 : 0 }}>
        <Table size="small" stickyHeader>
          <TableHead>
            <TableRow>
              {columns.map((column) => (
                <TableCell key={column.key} sx={{ minWidth: column.minWidth }}>
                  {column.label}
                </TableCell>
              ))}
              {actions.length ? <TableCell align="right">Actions</TableCell> : null}
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={columns.length + (actions.length ? 1 : 0)}>
                  <Stack sx={{ py: 8, alignItems: 'center', justifyContent: 'center' }}>
                    <CircularProgress size={32} />
                  </Stack>
                </TableCell>
              </TableRow>
            ) : rows.length ? (
              rows.map((row) => (
                <TableRow hover key={getRowId(row)}>
                  {columns.map((column) => (
                    <TableCell key={column.key}>
                      {column.render ? column.render(row) : safeText(row[column.key])}
                    </TableCell>
                  ))}
                  {actions.length ? (
                    <TableCell align="right">
                      <Stack direction="row" spacing={0.5} sx={{ justifyContent: 'flex-end' }}>
                        {actions.map((action) => (
                          <Tooltip title={action.label} key={action.label}>
                            <span>
                              <IconButton
                                size="small"
                                color={action.color || 'default'}
                                onClick={() => action.onClick(row)}
                                disabled={action.disabled?.(row)}
                              >
                                {action.icon}
                              </IconButton>
                            </span>
                          </Tooltip>
                        ))}
                      </Stack>
                    </TableCell>
                  ) : null}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={columns.length + (actions.length ? 1 : 0)}>
                  <Box sx={{ py: 8, textAlign: 'center' }}>
                    <Typography fontWeight={700}>{emptyMessage}</Typography>
                    <Typography color="text.secondary" variant="body2">
                      Adjust filters or create a new record.
                    </Typography>
                  </Box>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
      {typeof total === 'number' ? (
        <TablePagination
          component="div"
          count={total}
          page={Math.max(page - 1, 0)}
          rowsPerPage={limit}
          onPageChange={(_, nextPage) => onPageChange(nextPage + 1)}
          onRowsPerPageChange={(event) => onLimitChange(Number(event.target.value))}
          rowsPerPageOptions={[10, 25, 50, 100]}
        />
      ) : null}
    </Paper>
  )
}

function safeText(value) {
  if (value == null || value === '') return '-'
  if (typeof value === 'object') return JSON.stringify(value)
  return String(value)
}
