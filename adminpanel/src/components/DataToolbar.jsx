import { FilterAltRounded, SearchRounded } from '@mui/icons-material'
import { Box, MenuItem, Stack, TextField } from '@mui/material'

export default function DataToolbar({
  search,
  onSearch,
  placeholder = 'Search',
  filters = [],
  children,
}) {
  return (
    <Stack
      direction={{ xs: 'column', md: 'row' }}
      spacing={1.5}
      sx={{
        mb: 2,
        alignItems: { xs: 'stretch', md: 'center' },
        justifyContent: 'space-between',
      }}
    >
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} sx={{ flex: 1 }}>
        <TextField
          value={search}
          onChange={(event) => onSearch(event.target.value)}
          placeholder={placeholder}
          size="small"
          slotProps={{
            input: {
              startAdornment: <SearchRounded fontSize="small" sx={{ mr: 1 }} />,
            },
          }}
          sx={{ maxWidth: { sm: 360 } }}
        />
        {filters.map((filter) => (
          <TextField
            key={filter.name}
            select
            size="small"
            value={filter.value || ''}
            label={filter.label}
            onChange={(event) => filter.onChange(event.target.value)}
            slotProps={{
              input: {
                startAdornment: <FilterAltRounded fontSize="small" sx={{ mr: 0.75 }} />,
              },
            }}
            sx={{ minWidth: 170 }}
          >
            <MenuItem value="">All</MenuItem>
            {filter.options.map((option) => (
              <MenuItem key={option.value || option} value={option.value || option}>
                {option.label || option}
              </MenuItem>
            ))}
          </TextField>
        ))}
      </Stack>
      <Box>{children}</Box>
    </Stack>
  )
}
