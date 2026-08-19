import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { api } from '../api'

export const getFavorites = () => JSON.parse(localStorage.getItem('favorites') || '[]')
export const toggleFavorite = (id) => {
  const favs = getFavorites()
  const idx = favs.indexOf(id)
  if (idx === -1) localStorage.setItem('favorites', JSON.stringify([...favs, id]))
  else localStorage.setItem('favorites', JSON.stringify(favs.filter(f => f !== id)))
}
export const isFavorite = (id) => getFavorites().includes(id)

export default function SavedRestaurantsPage() {
  const navigate = useNavigate()
  const [restaurants, setRestaurants] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const loadSaved = useCallback(async () => {
    const ids = getFavorites()
    if (ids.length === 0) { setRestaurants([]); setLoading(false); return }
    setLoading(true)
    try {
      const results = await Promise.all(ids.map(id => api.restaurants.get(id).catch(() => null)))
      setRestaurants(results.filter(Boolean).reverse())
    } catch (_) {
      setError('저장한 가게를 불러오지 못했어요')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadSaved() }, [loadSaved])

  const handleUnsave = (id) => {
    toggleFavorite(id)
    setRestaurants(prev => prev.filter(r => r.id !== id))
  }

  return (
    <div style={{ height: '100vh', background: '#FFFEFB', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', borderBottom: '1px solid #f0f0f0', background: '#FFFEFB', flexShrink: 0 }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: '#201515', padding: '0 12px 0 0' }}>←</button>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 16, fontWeight: 700, color: '#201515' }}>저장한 가게</p>
      </div>

      {loading ? (
        <Center><Spinner /></Center>
      ) : error ? (
        <Center>
          <p style={{ color: '#999', fontSize: 14, marginBottom: 12 }}>{error}</p>
          <button onClick={loadSaved} style={retryBtn}>다시 시도</button>
        </Center>
      ) : restaurants.length === 0 ? (
        <Center>
          <p style={{ fontSize: 36, marginBottom: 10 }}>🤍</p>
          <p style={{ color: '#999', fontSize: 14 }}>저장한 가게가 없어요</p>
          <p style={{ color: '#bbb', fontSize: 12, marginTop: 4 }}>마음에 드는 가게를 저장해보세요</p>
        </Center>
      ) : (
        <div style={{ flex: 1, overflowY: 'auto' }}>
          <div style={{ padding: '12px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #f0f0f0' }}>
            <p style={{ fontSize: 13, fontWeight: 600, color: '#201515' }}>총 {restaurants.length}개의 저장한 가게</p>
            <p style={{ fontSize: 12, color: '#888' }}>최근 저장순</p>
          </div>
          {restaurants.map((r, i) => (
            <div key={r.id}>
              {i > 0 && <div style={{ height: 1, background: '#f0f0f0' }} />}
              <SavedCard restaurant={r} onTap={() => navigate(`/restaurant/${r.id}`, { state: { restaurant: r } })} onUnsave={() => handleUnsave(r.id)} />
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function SavedCard({ restaurant: r, onTap, onUnsave }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px' }}>
      <button onClick={onTap} style={{ display: 'flex', alignItems: 'center', flex: 1, background: 'none', border: 'none', cursor: 'pointer', textAlign: 'left', gap: 14, minWidth: 0 }}>
        <div style={{ width: 72, height: 72, borderRadius: 10, background: 'rgba(255,79,0,0.07)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontSize: 28 }}>🍴</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 15, fontWeight: 700, color: '#201515', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.name}</p>
          <p style={{ fontSize: 12, color: '#999', marginTop: 3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.address}</p>
          {r.avg_rating != null && (
            <p style={{ fontSize: 12, color: '#999', marginTop: 4 }}>⭐ {r.avg_rating.toFixed(1)} ({r.review_count})</p>
          )}
        </div>
      </button>
      <button onClick={onUnsave} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 8, fontSize: 22, color: '#FF4F00', flexShrink: 0 }}>♥</button>
    </div>
  )
}

function Center({ children }) {
  return <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 24 }}>{children}</div>
}
function Spinner() {
  return <div style={{ width: 28, height: 28, border: '2.5px solid #f0f0f0', borderTop: '2.5px solid #FF4F00', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
}
const retryBtn = { background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 20, padding: '8px 20px', fontSize: 13, cursor: 'pointer' }
