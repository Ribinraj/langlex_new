import { createTheme } from '@mui/material/styles'

const brand = {
  primary: '#8E5CE6',
  primaryDark: '#58369F',
  secondary: '#5C9B81',
  ink: '#1E1B29',
  muted: '#716981',
  paper: '#FFFFFF',
  canvas: '#FBFAFE',
  line: '#E8E3F0',
  warning: '#B7782E',
  danger: '#C93C4D',
}

export function buildTheme(mode = 'light') {
  const dark = mode === 'dark'

  return createTheme({
    palette: {
      mode,
      primary: {
        main: brand.primary,
        dark: brand.primaryDark,
      },
      secondary: {
        main: brand.secondary,
      },
      success: {
        main: brand.secondary,
      },
      warning: {
        main: brand.warning,
      },
      error: {
        main: brand.danger,
      },
      background: {
        default: dark ? '#111018' : brand.canvas,
        paper: dark ? '#191722' : brand.paper,
      },
      text: {
        primary: dark ? '#F4F1FA' : brand.ink,
        secondary: dark ? '#B8B0C7' : brand.muted,
      },
      divider: dark ? '#292637' : brand.line,
    },
    typography: {
      fontFamily: 'Montserrat, Inter, ui-sans-serif, system-ui, sans-serif',
      h1: { letterSpacing: 0, fontWeight: 700 },
      h2: { letterSpacing: 0, fontWeight: 700 },
      h3: { letterSpacing: 0, fontWeight: 700 },
      h4: { letterSpacing: 0, fontWeight: 700 },
      h5: { letterSpacing: 0, fontWeight: 700 },
      h6: { letterSpacing: 0, fontWeight: 700 },
      button: { textTransform: 'none', fontWeight: 700, letterSpacing: 0 },
    },
    shape: {
      borderRadius: 8,
    },
    components: {
      MuiButton: {
        styleOverrides: {
          root: {
            minHeight: 42,
            borderRadius: 8,
          },
          containedPrimary: {
            backgroundImage: 'linear-gradient(135deg, #8E5CE6 0%, #7B3FE7 100%)',
            boxShadow: '0 12px 28px rgba(126, 72, 224, 0.28)',
          },
        },
      },
      MuiCard: {
        styleOverrides: {
          root: {
            border: `1px solid ${dark ? '#292637' : brand.line}`,
            boxShadow: dark
              ? '0 18px 40px rgba(0,0,0,0.28)'
              : '0 18px 46px rgba(48,34,75,0.07)',
            borderRadius: 8,
          },
        },
      },
      MuiDrawer: {
        styleOverrides: {
          paper: {
            backgroundImage: 'none',
          },
        },
      },
      MuiPaper: {
        styleOverrides: {
          root: {
            backgroundImage: 'none',
          },
        },
      },
      MuiTableCell: {
        styleOverrides: {
          head: {
            fontWeight: 700,
            color: dark ? '#DCD5EA' : '#4A4357',
            backgroundColor: dark ? '#1F1C2A' : '#F0ECF7',
          },
        },
      },
    },
  })
}

export { brand }
