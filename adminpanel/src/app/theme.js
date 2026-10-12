import { createTheme } from '@mui/material/styles'

const brand = { primary: '#7041CB', secondary: '#277C64' }
export function buildTheme(mode = 'light') {
  const dark = mode === 'dark'
  const line = dark ? '#303443' : '#E6E8EF'
  return createTheme({
    palette: {
      mode,
      primary: {
        main: dark ? '#BC9AFF' : brand.primary,
        contrastText: dark ? '#201333' : '#FFFFFF',
      },
      secondary: { main: dark ? '#78D7B5' : brand.secondary },
      success: { main: dark ? '#78D7B5' : '#237556' },
      warning: { main: dark ? '#EBC176' : '#98600D' },
      error: { main: dark ? '#FF9FAD' : '#BC304B' },
      background: {
        default: dark ? '#11131B' : '#F7F8FC',
        paper: dark ? '#1A1D28' : '#FFFFFF',
      },
      text: {
        primary: dark ? '#F1F2F8' : '#202437',
        secondary: dark ? '#ABB1C5' : '#646C82',
      },
      divider: line,
      action: {
        hover: dark ? '#272B3A' : '#F1EDF9',
        selected: dark ? '#33264C' : '#EEE7FA',
      },
    },
    typography: {
      fontFamily: 'Montserrat, ui-sans-serif, system-ui, sans-serif',
      fontSize: 13,
      h1: { fontWeight: 700 },
      h2: { fontWeight: 700 },
      h3: { fontWeight: 700 },
      h4: { fontWeight: 700, letterSpacing: '-0.7px' },
      h5: { fontWeight: 700 },
      h6: { fontWeight: 700, fontSize: '1rem' },
      body1: { lineHeight: 1.65 },
      body2: { lineHeight: 1.6 },
      button: { textTransform: 'none', fontWeight: 600 },
    },
    shape: { borderRadius: 12 },
    components: {
      MuiCssBaseline: {
        styleOverrides: {
          body: { colorScheme: mode },
          '::-webkit-scrollbar-thumb': {
            backgroundColor: dark ? '#42485C' : '#CFD3E0',
          },
          '*:focus-visible': {
            outline: `3px solid ${dark ? '#BC9AFF' : '#7041CB'}`,
            outlineOffset: 3,
          },
        },
      },
      MuiButton: {
        defaultProps: { disableElevation: true },
        styleOverrides: {
          root: { minHeight: 44, borderRadius: 8, paddingInline: 18 },
        },
      },
      MuiIconButton: {
        styleOverrides: { root: { minWidth: 44, minHeight: 44 } },
      },
      MuiCard: {
        styleOverrides: {
          root: {
            border: `1px solid ${line}`,
            boxShadow: 'none',
            borderRadius: 14,
          },
        },
      },
      MuiCardContent: {
        styleOverrides: {
          root: { padding: 24, '&:last-child': { paddingBottom: 24 } },
        },
      },
      MuiPaper: { styleOverrides: { root: { backgroundImage: 'none' } } },
      MuiOutlinedInput: {
        styleOverrides: {
          root: { borderRadius: 8, minHeight: 44 },
          notchedOutline: { borderColor: line },
        },
      },
      MuiTableCell: {
        styleOverrides: {
          root: { borderColor: line, padding: '14px 18px', fontSize: 13 },
          head: {
            fontWeight: 600,
            color: dark ? '#C2C7D8' : '#555F77',
            backgroundColor: dark ? '#202430' : '#F8F9FC',
            whiteSpace: 'nowrap',
          },
        },
      },
      MuiTablePagination: {
        styleOverrides: {
          toolbar: { flexWrap: 'wrap', paddingBlock: 8 },
          selectLabel: { marginBlock: 4 },
          displayedRows: { marginBlock: 4 },
        },
      },
      MuiTab: {
        styleOverrides: {
          root: { minHeight: 48, textTransform: 'none', fontWeight: 600 },
        },
      },
      MuiDialog: {
        styleOverrides: {
          paper: { border: `1px solid ${line}`, borderRadius: 16 },
        },
      },
      MuiDialogTitle: {
        styleOverrides: { root: { fontSize: 20, padding: '24px 24px 18px' } },
      },
      MuiChip: {
        styleOverrides: { root: { borderRadius: 6, fontWeight: 600 } },
      },
      MuiTooltip: { defaultProps: { arrow: true } },
    },
  })
}
export { brand }
