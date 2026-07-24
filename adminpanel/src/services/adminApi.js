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
  plans: ['name', 'type', 'amount', 'permission', 'plan_timeperiod'],
}

export const jsonColumns = new Set(['permission', 'audio_text_map', 'metadata', 'data'])

export const fixedFieldOptions = {
  language: ['English', 'Hindi', 'Kannada', 'Maithili'],
  Language: ['English', 'Hindi', 'Kannada', 'Maithili'],
  show_plan: [
    { value: '0', label: 'Free' },
    { value: '1', label: 'Requires Subscription' },
  ],
  type: [
    { value: 'free', label: 'Free' },
    { value: 'paid', label: 'Paid' },
  ],
  plan_timeperiod: ['7 days', '30 days', '90 days', '180 days', '365 days'],
  permission: [
    { value: '{"courses":"limited"}', label: 'Limited courses' },
    { value: '{"courses":"all"}', label: 'All courses' },
    { value: '{"courses":"all","stories":"all"}', label: 'All courses + stories' },
    {
      value: '{"courses":"all","stories":"all","quizzes":"all"}',
      label: 'All courses + stories + quizzes',
    },
  ],
  level: ['Beginner', 'Nursery', 'LKG', 'UKG', 'Class 1', 'Class 2'],
  grade: ['Beginner', 'Nursery', 'LKG', 'UKG', 'Class 1', 'Class 2'],
  difflvl: [
    { value: 'easy', label: 'Easy' },
    { value: 'medium', label: 'Medium' },
    { value: 'hard', label: 'Hard' },
  ],
  QType: [
    { value: 'mcq', label: 'Multiple Choice' },
    { value: 'image_mcq', label: 'Image Multiple Choice' },
    { value: 'audio_mcq', label: 'Audio Multiple Choice' },
  ],
  letter_type: ['Vowel', 'Consonant'],
}

export const relationshipFields = new Set([
  'p_cat',
  'category',
  'subcategory',
  'course',
  'coursename',
  'topic',
])

export const adminApi = {
  overview: () => apiClient.get('/admin/overview').then((res) => res.data),
  users: (params) => apiClient.get('/admin/users', { params }).then((res) => res.data),
  user: (id) => apiClient.get(`/admin/users/${id}`).then((res) => res.data),
  updateUser: (id, payload) => apiClient.put(`/admin/users/${id}`, payload).then((res) => res.data),
  deleteUser: (id) => apiClient.delete(`/admin/users/${id}`).then((res) => res.data),
  payments: (params) => apiClient.get('/admin/payments', { params }).then((res) => res.data),
  subscriptions: (params) =>
    apiClient.get('/admin/subscriptions', { params }).then((res) => res.data),
  notifications: (params) =>
    apiClient.get('/admin/notifications', { params }).then((res) => res.data),
  sendNotification: (payload) =>
    apiClient.post('/admin/notifications', payload).then((res) => res.data),
  resource: (resource, params) =>
    apiClient.get(`/admin/resources/${resource}`, { params }).then((res) => res.data),
  createResource: (resource, payload) =>
    apiClient.post(`/admin/resources/${resource}`, payload).then((res) => res.data),
  updateResource: (resource, id, payload) =>
    apiClient.put(`/admin/resources/${resource}/${id}`, payload).then((res) => res.data),
  deleteResource: (resource, id) =>
    apiClient.delete(`/admin/resources/${resource}/${id}`).then((res) => res.data),
}

export function humanize(key) {
  return key
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
    .replace('Ca', 'Correct Answer')
}
