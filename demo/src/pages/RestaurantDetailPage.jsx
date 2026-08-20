import { useState, useEffect } from 'react'
import { useParams, useNavigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'
import { isFavorite, toggleFavorite } from './SavedRestaurantsPage'

const TABS = ['개요', '사진', '리뷰', '정보']

const CDN = 'https://images.unsplash.com/'
const CATEGORY_PHOTOS = {
  restaurant: [
    'photo-1562571708-527276a391ac', // Korean food variety
    'photo-1670819917394-03031b377bea', // chopsticks over food
    'photo-1708388066828-af75608c3b2f', // table with varied dishes
    'photo-1708388064672-6536507fdf6e', // grill with food
  ],
  cafe: [
    'photo-1621343607959-5d11ff0f1e39', // Korean cafe interior
    'photo-1652189684524-4fb0c0a9850b', // cafe drinks
    'photo-1605971981986-e623e8e16f33', // cafe cozy
    'photo-1708388065153-8b8b29c700c3', // dessert cafe
  ],
  convenience: [
    'photo-1758570764602-d57bc2922dea', // GS25 convenience store
    'photo-1683142667313-49cb993d29e2', // 7-Eleven at night
    'photo-1767042384860-bce4f5241639', // Korea storefront
  ],
  mart: [
    'photo-1644501810962-3a7428e1df93', // grocery store display
    'photo-1689751935647-8243f57c0669', // mart storefront
    'photo-1562571708-527276a391ac',    // fallback food photo
  ],
}

function getPhotoCategory(category) {
  if (!category) return 'restaurant'
  if (category.includes('카페') || category.includes('디저트') || category.includes('베이커리')) return 'cafe'
  if (category.includes('편의점')) return 'convenience'
  if (category.includes('마트') || category.includes('슈퍼') || category.includes('할인점')) return 'mart'
  return 'restaurant'
}

function photoUrl(id) {
  return `${CDN}${id}?w=400&q=80&auto=format&fit=crop`
}

const MOCK_REVIEWS = [
  { id: 9001, nickname: '화성맛집탐방', rating: 5, tags: ['가성비', '혼밥'], comment: '혼밥하기 딱 좋아요! 국물이 진하고 양도 넉넉해요. 직원분들도 친절하셨어요.', is_hwaseong_certified: true, created_at: '2026-07-22T12:30:00' },
  { id: 9002, nickname: '동탄주민이', rating: 4, tags: ['가성비'], comment: '가격 대비 맛이 좋아요. 점심 특선도 있어서 자주 올 것 같아요.', is_hwaseong_certified: false, created_at: '2026-07-15T19:05:00' },
  { id: 9003, nickname: '남양읍청년', rating: 5, tags: ['10대 픽'], comment: '친구들이랑 자주 오는 곳! 분위기도 좋고 맛도 정말 있어요.', is_hwaseong_certified: true, created_at: '2026-06-30T13:20:00' },
  { id: 9004, nickname: '볏섬유저', rating: 3, tags: ['혼밥'], comment: null, is_hwaseong_certified: false, created_at: '2026-06-10T18:45:00' },
  { id: 9005, nickname: '화성카공러', rating: 4, tags: ['카공족', '가성비'], comment: '카공하기 좋아요. 음료도 맛있고 조용한 편이에요.', is_hwaseong_certified: true, created_at: '2026-05-28T10:15:00' },
]

export default function RestaurantDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { state } = useLocation()
  const { isLoggedIn } = useAuth()

  const [restaurant, setRestaurant] = useState(state?.restaurant || null)
  const [reviews, setReviews] = useState([])
  const [reviewTotal, setReviewTotal] = useState(0)
  const [tab, setTab] = useState(() => state?.reviewTab ? 2 : 0)
  const [loading, setLoading] = useState(!state?.restaurant)
  const [reviewLoading, setReviewLoading] = useState(true)
  const [selectedTag, setSelectedTag] = useState(null)
  const [saved, setSaved] = useState(() => isFavorite(Number(id)))

  useEffect(() => {
    if (!restaurant) {
      api.restaurants.get(id).then(setRestaurant).catch(() => {}).finally(() => setLoading(false))
    }
    api.reviews.list(id).then(data => {
      const items = data.items || []
      if (items.length === 0) {
        setReviews(MOCK_REVIEWS)
        setReviewTotal(MOCK_REVIEWS.length)
      } else {
        setReviews(items)
        setReviewTotal(data.total || items.length)
      }
    }).catch(() => {
      setReviews(MOCK_REVIEWS)
      setReviewTotal(MOCK_REVIEWS.length)
    }).finally(() => setReviewLoading(false))
  }, [id, restaurant])

  const copy = (text, label) => {
    navigator.clipboard.writeText(text).catch(() => {})
    // simple toast
    const el = document.createElement('div')
    el.textContent = `${label} 복사됨`
    Object.assign(el.style, { position: 'fixed', bottom: '80px', left: '50%', transform: 'translateX(-50%)', background: 'rgba(0,0,0,0.7)', color: '#fff', borderRadius: '20px', padding: '8px 16px', fontSize: '13px', zIndex: 9999 })
    document.body.appendChild(el)
    setTimeout(() => el.remove(), 1500)
  }

  if (loading) {
    return (
      <div style={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#fff' }}>
        <Spinner />
      </div>
    )
  }
  if (!restaurant) {
    return (
      <div style={{ height: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: '#fff', gap: 12 }}>
        <p style={{ fontSize: 14, color: '#999' }}>음식점 정보를 찾을 수 없어요.</p>
        <button onClick={() => navigate(-1)} style={btnOutline}>돌아가기</button>
      </div>
    )
  }

  const tagCounts = {}
  reviews.forEach(r => (r.tags || []).forEach(t => { tagCounts[t] = (tagCounts[t] || 0) + 1 }))
  const visibleReviews = selectedTag ? reviews.filter(r => (r.tags || []).includes(selectedTag)) : reviews

  return (
    <div style={{ height: '100vh', display: 'flex', flexDirection: 'column', background: '#fff' }}>
      {/* 헤더 */}
      <div style={{ padding: '12px 16px 0', flexShrink: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: '#201515', padding: '4px 0' }}>←</button>
          <button
            onClick={() => { toggleFavorite(Number(id)); setSaved(s => !s) }}
            style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 24, color: saved ? '#FF4F00' : '#ccc', padding: '4px 0' }}
          >{saved ? '♥' : '♡'}</button>
        </div>
        <div style={{ padding: '0 0 14px' }}>
          <h1 style={{ fontFamily: '"Noto Serif KR"', fontSize: 22, fontWeight: 700, color: '#201515', marginTop: 4 }}>{restaurant.name}</h1>
          <p style={{ fontSize: 12, color: '#888', marginTop: 5 }}>
            {restaurant.avg_rating == null
              ? '아직 등록된 평점이 없어요'
              : `평점 ${restaurant.avg_rating.toFixed(1)} · 리뷰 ${restaurant.review_count}`}
          </p>
        </div>
      </div>

      {/* 탭바 */}
      <div style={{ display: 'flex', borderBottom: '1px solid #eee', flexShrink: 0 }}>
        {TABS.map((t, i) => (
          <button key={t} onClick={() => setTab(i)} style={{
            flex: 1, padding: '12px 0', background: 'none', border: 'none', cursor: 'pointer',
            fontSize: 14, fontWeight: tab === i ? 700 : 400,
            color: tab === i ? '#FF4F00' : '#999',
            borderBottom: tab === i ? '2px solid #FF4F00' : '2px solid transparent',
          }}>{t}</button>
        ))}
      </div>

      {/* 탭 내용 */}
      <div style={{ flex: 1, overflowY: 'auto' }}>
        {tab === 0 && (
          <div style={{ padding: '16px 16px 28px' }}>
            {/* 액션 버튼 */}
            <div style={{ display: 'flex', gap: 10, marginBottom: 20 }}>
              {[
                { icon: '📞', label: '전화', action: () => restaurant.phone ? copy(restaurant.phone, '전화번호') : null },
                { icon: '🔗', label: '공유', action: () => {} },
              ].map(({ icon, label, action }) => (
                <button key={label} onClick={action} style={{ ...btnOutline, flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, padding: '10px 0' }}>
                  <span style={{ fontSize: 18 }}>{icon}</span>
                  <span style={{ fontSize: 13 }}>{label}</span>
                </button>
              ))}
            </div>

            {/* 정보 행 */}
            <InfoRow label="주소" value={restaurant.address} onTap={() => copy(restaurant.address, '주소')} />
            {restaurant.phone && <InfoRow label="전화" value={restaurant.phone} onTap={() => copy(restaurant.phone, '전화번호')} />}
            {(restaurant.is_konapay || restaurant.is_mobeom) && (
              <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
                {restaurant.is_konapay && <Badge text="💳 화성페이 가맹점" color="#4CAF50" />}
                {restaurant.is_mobeom && <Badge text="🏆 모범음식점" color="#2196F3" />}
              </div>
            )}

            {/* 간단 리뷰 미리보기 */}
            <div style={{ marginTop: 24, borderTop: '1px solid #eee', paddingTop: 20 }}>
              <p style={{ fontSize: 16, fontWeight: 700, color: '#201515', marginBottom: 12 }}>방문자 리뷰</p>
              {reviewLoading ? <Spinner /> : reviews.length === 0 ? (
                <EmptyReviews />
              ) : (
                <>
                  {reviews.slice(0, 2).map(r => <ReviewCard key={r.id} review={r} />)}
                  <button onClick={() => setTab(2)} style={{ ...btnOutline, width: '100%', marginTop: 8 }}>리뷰 전체 보기 ({reviewTotal})</button>
                </>
              )}
            </div>
          </div>
        )}

        {tab === 1 && (
          <div style={{ padding: '12px 12px 32px' }}>
            <p style={{ fontSize: 11, color: '#bbb', textAlign: 'center', marginBottom: 12 }}>음식점 사진 예시 (볏섬 팀 제공)</p>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
              {CATEGORY_PHOTOS[getPhotoCategory(restaurant.category)].map((photoId, i) => (
                <img
                  key={photoId}
                  src={photoUrl(photoId)}
                  alt={`가게 사진 ${i + 1}`}
                  style={{
                    width: '100%', aspectRatio: '1/1', objectFit: 'cover',
                    borderRadius: 10, background: '#f0f0f0', display: 'block',
                  }}
                  loading="lazy"
                />
              ))}
            </div>
          </div>
        )}

        {tab === 2 && (
          <div style={{ padding: '18px 16px 32px' }}>
            <p style={{ fontSize: 16, fontWeight: 700, color: '#201515', marginBottom: 14 }}>방문자 리뷰 {reviewTotal}</p>
            {Object.keys(tagCounts).length > 0 && (
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
                {Object.entries(tagCounts).map(([tag, cnt]) => (
                  <button
                    key={tag}
                    onClick={() => setSelectedTag(selectedTag === tag ? null : tag)}
                    style={{
                      background: selectedTag === tag ? '#FF4F00' : '#f5f5f5',
                      color: selectedTag === tag ? '#fff' : '#555',
                      border: 'none', borderRadius: 50, padding: '6px 12px',
                      fontSize: 12, fontWeight: 600, cursor: 'pointer',
                    }}
                  >
                    {tag} {cnt}
                  </button>
                ))}
              </div>
            )}
            {reviewLoading ? <div style={{ textAlign: 'center', padding: 20 }}><Spinner /></div>
              : visibleReviews.length === 0 ? <EmptyReviews />
              : visibleReviews.map(r => <ReviewCard key={r.id} review={r} />)
            }
            {isLoggedIn && (
              <button
                onClick={() => navigate(`/review/${id}`, { state: { restaurant } })}
                style={{ ...btnPrimary, width: '100%', marginTop: 16 }}
              >식사평 남기기</button>
            )}
          </div>
        )}

        {tab === 3 && (
          <div style={{ padding: '20px 16px 32px' }}>
            <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 12 }}>가게 정보</p>
            <InfoRow label="주소" value={restaurant.address} />
            {restaurant.phone && <InfoRow label="전화" value={restaurant.phone} />}
            {restaurant.category && <InfoRow label="업종" value={restaurant.category} />}
            <div style={{ marginTop: 24, borderTop: '1px solid #eee', paddingTop: 20 }}>
              <p style={{ fontSize: 15, fontWeight: 700, marginBottom: 10 }}>영업시간</p>
              <p style={{ fontSize: 14, color: '#999' }}>영업시간 정보가 없어요.</p>
            </div>
            <div style={{ marginTop: 24, borderTop: '1px solid #eee', paddingTop: 20 }}>
              <p style={{ fontSize: 15, fontWeight: 700, marginBottom: 10 }}>위치</p>
              <div style={{ height: 100, background: '#f5f5f5', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <p style={{ fontSize: 13, color: '#999', textAlign: 'center', padding: '0 20px' }}>{restaurant.address}</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

function InfoRow({ label, value, onTap }) {
  return (
    <button onClick={onTap} style={{ display: 'flex', gap: 0, background: 'none', border: 'none', cursor: onTap ? 'pointer' : 'default', padding: '8px 0', width: '100%', textAlign: 'left' }}>
      <span style={{ width: 52, fontSize: 14, color: '#999', flexShrink: 0 }}>{label}</span>
      <span style={{ fontSize: 14, color: '#201515', flex: 1 }}>{value}</span>
    </button>
  )
}

function ReviewCard({ review: r }) {
  const date = new Date(r.created_at).toLocaleDateString('ko-KR').replace(/\. /g, '.').replace(/\.$/, '')
  return (
    <div style={{ padding: '14px 0', borderBottom: '1px solid #f5f5f5' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
        <span style={{ fontWeight: 700, fontSize: 14 }}>{r.nickname}</span>
        {r.is_hwaseong_certified && <span style={{ fontSize: 12, color: '#FF4F00', fontWeight: 600 }}>화성인증</span>}
      </div>
      {r.rating != null && (
        <div style={{ display: 'flex', gap: 1, margin: '6px 0 0' }}>
          {[1,2,3,4,5].map(i => <span key={i} style={{ color: i <= r.rating ? '#FFBB33' : '#ddd', fontSize: 15 }}>{i <= r.rating ? '★' : '☆'}</span>)}
        </div>
      )}
      {r.comment && <p style={{ fontSize: 14, color: '#201515', marginTop: 8, lineHeight: 1.6 }}>{r.comment}</p>}
      {r.tags?.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 8 }}>
          {r.tags.map(t => <span key={t} style={{ background: '#f5f5f5', borderRadius: 50, padding: '4px 10px', fontSize: 11, color: '#666' }}>{t}</span>)}
        </div>
      )}
      <p style={{ fontSize: 12, color: '#aaa', marginTop: 8 }}>{date}</p>
    </div>
  )
}

function EmptyReviews() {
  return (
    <div style={{ padding: '28px 0', textAlign: 'center', color: '#aaa' }}>
      <p style={{ fontSize: 32, marginBottom: 8 }}>📝</p>
      <p style={{ fontSize: 14 }}>아직 등록된 리뷰가 없어요.</p>
    </div>
  )
}

function Badge({ text, color }) {
  return <span style={{ background: `${color}1a`, color, fontSize: 12, fontWeight: 700, borderRadius: 8, padding: '4px 10px' }}>{text}</span>
}

function Spinner() {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', padding: 20 }}>
      <div style={{ width: 28, height: 28, border: '3px solid #f0f0f0', borderTop: '3px solid #FF4F00', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
    </div>
  )
}

const btnOutline = { background: 'none', border: '1px solid #ddd', borderRadius: 10, cursor: 'pointer', fontSize: 13, color: '#201515', padding: '10px 14px', fontFamily: '"Noto Sans KR"' }
const btnPrimary = { background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 10, cursor: 'pointer', fontSize: 14, fontWeight: 700, padding: '14px', fontFamily: '"Noto Serif KR"' }
