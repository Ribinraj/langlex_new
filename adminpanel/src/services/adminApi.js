import { apiClient } from './apiClient'

export const resourceLabels = {
  categories: 'Categories',
  subcategories: 'Subcategories',
  courses: 'Courses',
  content: 'Words',
  alphabets: 'Alphabets',
  quizzes: 'Quizzes',
  phonics: 'Phonics',
  stories: 'Stories',
  plans: 'Plans',
}

export const resourceSchemas = {
  categories: ['title', 'created', 'image', 'language'],
  subcategories: ['title', 'created', 'image', 'p_cat', 'language'],
  courses: ['title', 'created', 'image', 'language', 'show_plan'],
  content: [
    'content',
    'created',
    'content_image',
    'content_audio',
    'word_audio',
    'course',
    'subcategory',
    'category',
    'language',
  ],
  alphabets: [
    'letter',
    'ill_word',
    'ill_image',
    'letter_sound',
    'word_audio',
    'letter_type',
    'coursename',
    'subcategory',
    'category',
    'language',
    'title_image',
    'level',
    'created',
  ],
  quizzes: [
    'Question',
    'ca',
    'o1',
    'o2',
    'o3',
    'Instruction',
    'audio',
    'image',
    'RAFeed',
    'WAFeed',
    'difflvl',
    'topic',
    'QType',
    'created',
    'Language',
    'q_audio',
    'raf_audio',
    'waf_audio',
  ],
  phonics: [
    'sentence',
    'word',
    'image',
    'sentence_sound',
    'word_audio',
    'coursename',
    'language',
    'category',
    'subcategory',
    'created',
    'title_image',
    'level',
  ],
  stories: [
    'title',
    'text',
    'created',
    'language',
    'image',
    'audio',
    'title_image',
    'grade',
    'audio_text_map',
    'show_plan',
    'title_audio',
  ],
  plans: ['name', 'type', 'amount', 'plan_timeperiod'],
}

export const jsonColumns = new Set(['permission', 'metadata', 'data'])

export const relationshipFields = new Set([
  'p_cat',
  'category',
  'subcategory',
  'course',
  'coursename',
  'topic',
])

export const adminApi = {
  setAccess: (id, payload) =>
    apiClient.put(`/admin/users/${id}/access`, payload).then((r) => r.data),
  grantSubscription: (id, payload) =>
    apiClient
      .post(`/admin/users/${id}/subscriptions`, payload)
      .then((r) => r.data),
  manageSubscription: (id, payload) =>
    apiClient.put(`/admin/subscriptions/${id}`, payload).then((r) => r.data),
  audit: (params) =>
    apiClient.get('/admin/audit', { params }).then((r) => r.data),
  media: (params) =>
    apiClient.get('/admin/media', { params }).then((r) => r.data),
  upload: (file) =>
    apiClient
      .post('/admin/media', file, {
        headers: {
          'Content-Type': 'application/octet-stream',
          'X-File-Name': encodeURIComponent(file.name),
        },
        timeout: 120000,
      })
      .then((r) => r.data.item),
  previewBulk: (resource, payload) =>
    apiClient
      .post(`/admin/bulk/${resource}/preview`, payload, { timeout: 120000 })
      .then((r) => r.data),
  applyBulk: (id) =>
    apiClient
      .post(`/admin/bulk/${id}/apply`, {}, { timeout: 120000 })
      .then((r) => r.data),
  formOptions: (resource, language) =>
    apiClient
      .get(`/admin/resource-form-options/${resource}`, { params: { language } })
      .then((res) => res.data),
  catalog: (resource, params) =>
    apiClient
      .get(`/admin/catalog/${resource}`, { params })
      .then((res) => res.data),
  groupItems: (resource, id, params) =>
    apiClient
      .get(`/admin/catalog/${resource}/${id}/items`, { params })
      .then((res) => res.data),
  updateGroup: (resource, id, payload) =>
    apiClient
      .put(`/admin/catalog/${resource}/${id}`, payload)
      .then((res) => res.data),
  learningProgress: (id, language) =>
    apiClient
      .get(`/admin/users/${id}/learning-progress`, { params: { language } })
      .then((res) => res.data),
  overview: () => apiClient.get('/admin/overview').then((res) => res.data),
  users: (params) =>
    apiClient.get('/admin/users', { params }).then((res) => res.data),
  user: (id) => apiClient.get(`/admin/users/${id}`).then((res) => res.data),
  updateUser: (id, payload) =>
    apiClient.put(`/admin/users/${id}`, payload).then((res) => res.data),
  deleteUser: (id) =>
    apiClient.delete(`/admin/users/${id}`).then((res) => res.data),
  payments: (params) =>
    apiClient.get('/admin/payments', { params }).then((res) => res.data),
  subscriptions: (params) =>
    apiClient.get('/admin/subscriptions', { params }).then((res) => res.data),
  notifications: (params) =>
    apiClient.get('/admin/notifications', { params }).then((res) => res.data),
  sendNotification: (payload) =>
    apiClient.post('/admin/notifications', payload).then((res) => res.data),
  resource: (resource, params) =>
    apiClient
      .get(`/admin/resources/${resource}`, { params })
      .then((res) => res.data),
  createResource: (resource, payload) =>
    apiClient
      .post(`/admin/resources/${resource}`, payload)
      .then((res) => res.data),
  updateResource: (resource, id, payload) =>
    apiClient
      .put(`/admin/resources/${resource}/${id}`, payload)
      .then((res) => res.data),
  deleteResource: (resource, id) =>
    apiClient
      .delete(`/admin/resources/${resource}/${id}`)
      .then((res) => res.data),
}

export function humanize(key) {
  const labels = {
    difflvl: 'Academic level',
    QType: 'Question format',
    ca: 'Correct answer',
    o1: 'Alternative 1',
    o2: 'Alternative 2',
    o3: 'Alternative 3',
    RAFeed: 'Correct-answer feedback',
    WAFeed: 'Wrong-answer feedback',
    show_plan: 'Access',
    coursename: 'Activity name',
    p_cat: 'Parent category',
    ill_word: 'Example word',
    ill_image: 'Example image',
    plan_timeperiod: 'Subscription period',
    q_audio: 'Question audio',
    raf_audio: 'Correct-answer audio',
    waf_audio: 'Wrong-answer audio',
  }
  if (labels[key]) return labels[key]
  return key
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
}

export const topicFields = {
  courses: ['title', 'language', 'image', 'show_plan'],
  alphabets: ['letter', 'coursename', 'language'],
  quizzes: ['topic', 'Language', 'show_plan'],
  phonics: ['coursename', 'language', 'title_image'],
  stories: [
    'title',
    'language',
    'grade',
    'show_plan',
    'title_image',
    'title_audio',
  ],
}
