import {
  Autocomplete,
  Checkbox,
  FormControlLabel,
  Stack,
  TextField,
} from '@mui/material'
export default function StandardsSelect({
  value = [],
  onChange,
  options = [],
  disabled = false,
  label = 'Available for standards',
}) {
  const all = value.includes('*')
  return (
    <Stack spacing={1}>
      <Autocomplete
        multiple
        disableCloseOnSelect
        options={options}
        value={all ? [] : value}
        disabled={disabled || all}
        onChange={(_, next) => onChange(next)}
        renderInput={(params) => (
          <TextField
            {...params}
            label={label}
            placeholder="Select standards"
            helperText="A topic can be available to more than one standard."
          />
        )}
      />
      <FormControlLabel
        control={
          <Checkbox
            checked={all}
            disabled={disabled}
            onChange={(_, checked) => onChange(checked ? ['*'] : [])}
          />
        }
        label="All standards"
      />
    </Stack>
  )
}
