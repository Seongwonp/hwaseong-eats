import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { api } from '../api'

export default function MyReviewsPage() {
  const navigate = useNavigate()
  const [reviews, setReviews] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    api.reviews.myList()
      .then(async data => {
        const items = data.items || []
        const enriched = await Promise.all(items.map(async r => {
          let restaurant = null
          try { restaurant = await api.restaurants.get(r.restaurant_id) } catch (_) {}
          return { ...r, restaurant }
        }))
        setReviews(enriched)
      })
      .catch(() => setError('식사평을 불러오지 못했어요'))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div style={{ height: '100vh', background: '#fff', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', borderBottom: '1px solid #f0f0f0', flexShrink: 0 }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: '#201515', padding: '0 12px 0 0' }}>←</button>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 16, fontWeight: 700, color: '#201515' }}>내가 쓴 식사평</p>
      </div>

      {loading ? (
        <Center><Spinner /></Center>
      ) : error ? (
        <Center>
          <p style={{ color: '#999', fontSize: 14, marginBottom: 12 }}>{error}</p>
          <button onClick={() => window.location.reload()} style={retryBtn}>다시 시도</button>
        </Center>
      ) : reviews.length === 0 ? (
        <Center>
          <p style={{ fontSize: 32, marginBottom: 12 }}>📝</p>
          <p style={{ color: '#999', fontSize: 14 }}>아직 작성한 식사평이 없어요</p>
          <p style={{ color: '#bbb', fontSize: 12, marginTop: 4 }}>방문한 가게의 식사평을 남겨보세요</p>
        </Center>
      ) : (
        <div style={{ flex: 1, overflowY: 'auto' }}>
          <div style={{ padding: '12px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #f0f0f0' }}>
            <p style={{ fontSize: 13, fontWeight: 600, color: '#201515' }}>총 {reviews.length}개의 식사평</p>
            <p style={{ fontSize: 12, color: '#888' }}>최신순</p>
          </div>
          {reviews.map((r, i) => (
            <div key={r.id}>
              {i > 0 && <div style={{ height: 8, background: '#f5f5f5' }} />}
              <ReviewCard review={r} onTap={() => r.restaurant && navigate(`/restaurant/${r.restaurant_id}`, { state: { restaurant: r.restaurant } })} />
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function ReviewCard({ review: r, onTap }) {
  const d = new Date(r.created_at)
  const dateStr = `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`

  return (
    <button onClick={onTap} style={{ width: '100%', background: 'none', border: 'none', cursor: onTap ? 'pointer' : 'default', textAlign: 'left', padding: '18px 16px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
            <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 15, fontWeight: 700, color: '#201515', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {r.restaurant?.name || `음식점 #${r.restaurant_id}`}
            </p>
            {r.is_hwaseong_certified && (
              <span style={{ flexShrink: 0, background: 'rgba(255,79,0,0.1)', color: '#FF4F00', fontSize: 10, fontWeight: 700, borderRadius: 4, padding: '2px 6px' }}>화성인증</span>
            )}
          </div>
          <p style={{ fontSize: 12, color: '#999', marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.restaurant?.address || ''}</p>
        </div>
        <p style={{ fontSize: 12, color: '#ccc', flexShrink: 0, marginLeft: 8 }}>전체 보기 &gt;</p>
      </div>

      {r.rating != null && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginBottom: 10 }}>
          {[1,2,3,4,5].map(i => (
            <span key={i} style={{ fontSize: 16, color: i <= r.rating ? '#FFBB33' : '#e0e0e0' }}>★</span>
          ))}
          <span style={{ fontSize: 13, fontWeight: 700, color: '#201515', marginLeft: 4 }}>{r.rating}.0</span>
        </div>
      )}

      {r.comment && (
        <div style={{ borderLeft: '3px solid #FF4F00', background: '#FFF9F6', padding: '10px 12px', marginBottom: 10 }}>
          <p style={{ fontSize: 13, color: '#201515', lineHeight: 1.6, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical' }}>{r.comment}</p>
        </div>
      )}

      <p style={{ fontSize: 12, color: '#aaa' }}>{dateStr}</p>

      {r.tags && r.tags.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 10 }}>
          {r.tags.map(tag => (
            <span key={tag} style={{ background: '#FFF3EE', color: '#FF4F00', fontSize: 12, fontWeight: 600, borderRadius: 20, padding: '5px 10px' }}>{tag}</span>
          ))}
        </div>
      )}
    </button>
  )
}

function Center({ children }) {
  return <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 24 }}>{children}</div>
}
function Spinner() {
  return <div style={{ width: 28, height: 28, border: '2.5px solid #f0f0f0', borderTop: '2.5px solid #FF4F00', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
}
const retryBtn = { background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 20, padding: '8px 20px', fontSize: 13, cursor: 'pointer' }
