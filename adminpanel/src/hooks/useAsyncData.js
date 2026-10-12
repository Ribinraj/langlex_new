import { useCallback, useEffect, useRef, useState } from 'react'

export function useAsyncData(loader) {
  const generation = useRef(0)
  const [state, setState] = useState({
    data: null,
    loading: true,
    error: '',
  })

  const load = useCallback(async () => {
    const request = ++generation.current
    setState((current) => ({ ...current, loading: true, error: '' }))
    try {
      const data = await loader()
      if (request !== generation.current) return null
      setState({ data, loading: false, error: '' })
      return data
    } catch (error) {
      if (request !== generation.current) return null
      setState({
        data: null,
        loading: false,
        error: error.response?.data?.message || error.message || 'Unable to load data',
      })
      return null
    }
  }, [loader])

  const invalidate = useCallback(() => { generation.current++ }, [])
  useEffect(() => {
    load()
    return invalidate
  }, [load, invalidate])

  return { ...state, reload: load }
}
