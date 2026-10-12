import { createTheme } from '@mui/material/styles'
import { buildTheme } from './theme'

// The workspace has its own visual theme so the illustrated login stays intact.
export function buildWorkspaceTheme(mode) {
  const dark = mode === 'dark'
  const line = dark ? 'rgba(206,229,255,0.18)' : 'rgba(52,87,121,0.16)'
  const glass = dark ? 'rgba(186,212,255,0.065)' : 'rgba(255,255,255,0.78)'
  const highlight = dark
    ? 'linear-gradient(135deg, rgba(255,255,255,0.055), rgba(255,255,255,0.01))'
    : 'linear-gradient(135deg, rgba(255,255,255,0.85), rgba(255,255,255,0.35))'
  return createTheme(buildTheme(mode), {
    palette: {
      primary: {
        main: dark ? '#DCEFFA' : '#285F83',
        contrastText: dark ? '#10273A' : '#FFFFFF',
      },
      secondary: { main: dark ? '#8CDAD5' : '#287A76' },
      background: {
        default: dark ? '#061725' : '#EDF3F8',
        paper: dark ? '#132B40' : '#FFFFFF',
      },
      text: {
        primary: dark ? '#F2F6FC' : '#183047',
        secondary: dark ? '#B4C5D7' : '#526A80',
      },
      divider: line,
      action: {
        hover: dark ? 'rgba(214,235,255,0.09)' : 'rgba(48,110,150,0.07)',
        selected: dark ? 'rgba(214,235,255,0.13)' : 'rgba(48,110,150,0.12)',
      },
    },
    workspace: {
      background: dark
        ? 'radial-gradient(ellipse at 4% 82%, rgba(0,126,158,0.43), transparent 62%), radial-gradient(ellipse at 96% 3%, rgba(90,64,169,0.48), transparent 58%), linear-gradient(135deg, #03131F, #0B2438 56%, #071725)'
        : 'radial-gradient(ellipse at 4% 82%, rgba(130,213,226,0.32), transparent 62%), radial-gradient(ellipse at 96% 3%, rgba(194,180,236,0.38), transparent 58%), linear-gradient(135deg, #F1F7FB, #EAF3F7)',
      sidebar: dark
        ? 'linear-gradient(165deg, #030E18 0%, #042333 72%, #06354A 100%)'
        : 'linear-gradient(165deg, #FFFFFF 0%, #F2F8FC 72%, #E7F3F8 100%)',
      header: dark ? 'rgba(5,19,34,0.56)' : 'rgba(248,252,255,0.76)',
    },
    components: {
      MuiCard: {
        styleOverrides: {
          root: {
            backgroundColor: glass,
            backgroundImage: highlight,
            border: `1px solid ${line}`,
            borderRadius: 18,
            boxShadow: dark
              ? '0 12px 32px rgba(0,7,18,0.08)'
              : '0 8px 28px rgba(28,66,104,0.04)',
            backdropFilter: 'blur(12px)',
          },
        },
      },
      MuiPaper: {
        styleOverrides: {
          outlined: {
            backgroundColor: glass,
            backgroundImage: highlight,
            borderColor: line,
            borderRadius: 16,
            backdropFilter: 'blur(12px)',
          },
        },
      },
      MuiButton: {
        styleOverrides: {
          root: { borderRadius: 10 },
          containedPrimary: {
            backgroundColor: dark ? '#EAF3FA' : '#285F83',
            color: dark ? '#10273A' : '#FFFFFF',
            '&:hover': { backgroundColor: dark ? '#FFFFFF' : '#204E6C' },
          },
        },
      },
      MuiOutlinedInput: {
        styleOverrides: {
          root: {
            borderRadius: 10,
            backgroundColor: dark
              ? 'rgba(6,23,40,0.24)'
              : 'rgba(255,255,255,0.65)',
            '&:hover .MuiOutlinedInput-notchedOutline': {
              borderColor: dark ? '#93AFC7' : '#819AB0',
            },
          },
          notchedOutline: {
            borderColor: dark ? 'rgba(206,229,255,0.28)' : '#ACBECE',
          },
        },
      },
      MuiTableCell: {
        styleOverrides: {
          root: { borderColor: line },
          head: {
            backgroundColor: dark ? '#173249' : '#EAF2F8',
            color: dark ? '#D6E4F2' : '#35536D',
          },
        },
      },
      // Menus and modal forms use solid surfaces for legibility above the gradient.
      MuiDialog: {
        styleOverrides: {
          paper: {
            backgroundColor: dark ? '#132B40' : '#FFFFFF',
            backgroundImage: 'none',
            borderColor: line,
            borderRadius: 18,
          },
        },
      },
      MuiMenu: {
        styleOverrides: {
          paper: {
            backgroundColor: dark ? '#132B40' : '#FFFFFF',
            border: `1px solid ${line}`,
          },
        },
      },
      MuiAutocomplete: {
        styleOverrides: {
          paper: {
            backgroundColor: dark ? '#132B40' : '#FFFFFF',
            border: `1px solid ${line}`,
          },
        },
      },
      MuiTooltip: {
        styleOverrides: {
          tooltip: {
            backgroundColor: dark ? '#EAF3FA' : '#183047',
            color: dark ? '#10273A' : '#FFFFFF',
          },
        },
      },
    },
  })
}
