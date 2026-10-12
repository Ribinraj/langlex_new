import { createAsyncThunk, createSlice } from '@reduxjs/toolkit'
import { apiClient } from '../../services/apiClient'

let savedAdmin = null
try {
  savedAdmin = JSON.parse(localStorage.getItem('langlex_admin_user') || 'null')
} catch {
  localStorage.removeItem('langlex_admin_user')
}

export const loginAdmin = createAsyncThunk(
  'auth/loginAdmin',
  async (payload, { rejectWithValue }) => {
    try {
      const { data } = await apiClient.post('/admin/auth/login', payload)
      localStorage.setItem('langlex_admin_token', data.token)
      localStorage.setItem('langlex_admin_user', JSON.stringify(data.admin))
      return data
    } catch (error) {
      return rejectWithValue(
        error.response?.data?.message ||
          'Unable to sign in. Check your connection and try again.',
      )
    }
  },
)

export const restoreAdmin = createAsyncThunk('auth/restoreAdmin', async () => {
  const { data } = await apiClient.get('/admin/auth/me', { silent: true })
  localStorage.setItem('langlex_admin_user', JSON.stringify(data.admin))
  return data.admin
})

const authSlice = createSlice({
  name: 'auth',
  initialState: {
    token: localStorage.getItem('langlex_admin_token') || '',
    admin: savedAdmin,
    status: 'idle',
    error: '',
  },
  reducers: {
    logout(state) {
      state.token = ''
      state.admin = null
      state.status = 'idle'
      state.error = ''
      localStorage.removeItem('langlex_admin_token')
      localStorage.removeItem('langlex_admin_user')
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(loginAdmin.pending, (state) => {
        state.status = 'loading'
        state.error = ''
      })
      .addCase(loginAdmin.fulfilled, (state, action) => {
        state.status = 'authenticated'
        state.token = action.payload.token
        state.admin = action.payload.admin
      })
      .addCase(loginAdmin.rejected, (state, action) => {
        state.status = 'error'
        state.error = action.payload || 'Unable to sign in'
      })
      .addCase(restoreAdmin.pending, (state) => {
        state.status = 'checking'
      })
      .addCase(restoreAdmin.fulfilled, (state, action) => {
        state.status = 'authenticated'
        state.admin = action.payload
      })
      .addCase(restoreAdmin.rejected, (state) => {
        state.status = 'idle'
        state.token = ''
        state.admin = null
      })
  },
})

export const { logout } = authSlice.actions
export default authSlice.reducer
