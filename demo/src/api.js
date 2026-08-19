const BASE = import.meta.env.VITE_API_URL

const token = () => localStorage.getItem('token')

const h = (json = false) => ({
  ...(json ? { 'Content-Type': 'application/json' } : {}),
  ...(token() ? { Authorization: `Bearer ${token()}` } : {}),
})

async function req(url, opts = {}) {
  const r = await fetch(url, opts)
  if (!r.ok) throw await r.json().catch(() => ({ detail: '오류가 발생했어요' }))
  return r.json()
}

export const api = {
  restaurants: {
    list: (params = {}) => {
      const q = new URLSearchParams()
      Object.entries(params).forEach(([k, v]) => {
        if (v != null && v !== '') q.append(k, v)
      })
      return req(`${BASE}/restaurants?${q}`, { headers: h() })
    },
    get: (id) => req(`${BASE}/restaurants/${id}`, { headers: h() }),
  },
  auth: {
    login: (email, password) => req(`${BASE}/auth/login`, {
      method: 'POST', headers: h(true),
      body: JSON.stringify({ email, password }),
    }),
    signup: (email, password, nickname) => req(`${BASE}/auth/signup`, {
      method: 'POST', headers: h(true),
      body: JSON.stringify({ email, password, nickname }),
    }),
    kakaoLogin: (access_token) => req(`${BASE}/auth/kakao`, {
      method: 'POST', headers: h(true),
      body: JSON.stringify({ access_token }),
    }),
    me: () => req(`${BASE}/auth/me`, { headers: h() }),
    points: () => req(`${BASE}/auth/me/points`, { headers: h() }),
  },
  reviews: {
    list: (restaurantId) => req(`${BASE}/reviews?restaurant_id=${restaurantId}`, { headers: h() }),
    create: (data) => req(`${BASE}/reviews`, {
      method: 'POST', headers: h(true),
      body: JSON.stringify(data),
    }),
  },
  festivals: {
    list: () => req(`${BASE}/festivals`, { headers: h() }),
  },
}
