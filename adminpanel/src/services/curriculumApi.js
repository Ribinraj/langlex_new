import { apiClient } from './apiClient'
export const sections = {
  knowledge: {
    label: 'Knowledge',
    resource: 'courses',
    item: 'word',
    plural: 'Words',
    description: 'Vocabulary topics and sounds for each student standard.',
  },
  alphabets: {
    label: 'Alphabets',
    resource: 'alphabets',
    item: 'example',
    plural: 'Examples',
    description: 'Letters, lesson groups and their example words.',
  },
  stories: {
    label: 'Stories',
    resource: 'stories',
    item: 'passage',
    plural: 'Passages',
    description: 'Story titles and the passages students read.',
  },
  quizzes: {
    label: 'Quizzes',
    resource: 'quizzes',
    item: 'question',
    plural: 'Questions',
    description: 'Quiz topics, questions and answer choices.',
  },
}
export const sounds = {
  label: 'Sounds',
  resource: 'phonics',
  item: 'sound',
  plural: 'Sounds',
  description: 'Listening and pronunciation activities inside Knowledge.',
}
export const standardsLabel = (values) =>
  values?.includes('*')
    ? 'All standards'
    : values?.length
      ? values.join(', ')
      : 'Needs review'
const base = '/admin/curriculum'
export const curriculumApi = {
  options: () => apiClient.get(`${base}/options`).then((r) => r.data),
  list: (params) => apiClient.get(base, { params }).then((r) => r.data),
  detail: (id, params) =>
    apiClient.get(`${base}/${id}`, { params }).then((r) => r.data),
  create: (body) => apiClient.post(base, body).then((r) => r.data),
  update: (id, body) =>
    apiClient.put(`${base}/${id}`, body).then((r) => r.data),
  saveItem: (id, itemId, body) =>
    (itemId
      ? apiClient.put(`${base}/${id}/items/${itemId}`, body)
      : apiClient.post(`${base}/${id}/items`, body)
    ).then((r) => r.data),
  deleteTopic: (id) => apiClient.delete(`${base}/${id}`).then((r) => r.data),
  deleteItem: (id, itemId) =>
    apiClient.delete(`${base}/${id}/items/${itemId}`).then((r) => r.data),
}
