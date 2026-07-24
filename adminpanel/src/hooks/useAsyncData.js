import { useCallback, useEffect, useState } from 'react'

export function useAsyncData(loader) {
  const [state, setState] = useState({
    data: null,
    loading: true,
    error: '',
  })

  const load = useCallback(async () => {
    setState((current) => ({ ...current, loading: true, error: '' }))
    try {
      const data = await loader()
      setState({ data, loading: false, error: '' })
      return data
    } catch (error) {
      setState({
        data: null,
        loading: false,
        error: error.response?.data?.message || error.message || 'Unable to load data',
      })
      return null
    }
  }, [loader])

  useEffect(() => {
    load()
  }, [load])

  return { ...state, reload: load }
}
