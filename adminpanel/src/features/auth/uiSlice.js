import { createSlice } from '@reduxjs/toolkit'

const initialState = {
  mode:
    localStorage.getItem('langlex_admin_mode') === 'light' ? 'light' : 'dark',
}

const uiSlice = createSlice({
  name: 'ui',
  initialState,
  reducers: {
    toggleMode(state) {
      state.mode = state.mode === 'light' ? 'dark' : 'light'
      localStorage.setItem('langlex_admin_mode', state.mode)
    },
  },
})

export const { toggleMode } = uiSlice.actions
export default uiSlice.reducer
