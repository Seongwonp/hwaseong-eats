import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

export default function HomePage() {
  const navigate = useNavigate()
  const { isLoggedIn, user } = useAuth()
  const [konapay, setKonapay] = useState([])
  const [mobeom, setMobeom] = useState([])
  const [festivals, setFestivals] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.restaurants.list({ is_konapay: true, limit: 5, food_only: false }),
      api.restaurants.list({ is_mobeom: true, limit: 3, food_only: false }),
      api.festivals.list().catch(() => ({ items: [] })),
    ]).then(([k, m, f]) => {
      setKonapay(k.items || [])
      setMobeom(m.items || [])
      const items = f.items || f || []
      setFestivals(items.filter(e => (e.d_day ?? 0) >= -3).sort((a, b) => a.d_day - b.d_day))
    }).finally(() => setLoading(false))
  }, [])

  const upcomingFestival = festivals[0] || null

  return (
    <div style={{ height: '100%', overflowY: 'auto', background: '#FFFEFB' }}>
      <div style={{ padding: '20px 20px 36px' }}>

        {/* 헤더 */}
        <p style={{ fontSize: 13, color: 'rgba(32,21,21,0.5)', marginBottom: 2 }}>안녕하세요,</p>
        {isLoggedIn ? (
          <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 22, fontWeight: 700, color: '#201515', marginBottom: 20 }}>
            {user?.nickname}님 · 효행구 봉담읍
          </p>
        ) : (
          <button onClick={() => navigate('/login')} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, textAlign: 'left', marginBottom: 20 }}>
            <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 24, fontWeight: 700, color: '#201515' }}>로그인 해주세요.</p>
          </button>
        )}

        {/* 키워드 추천 */}
        <Section title="키워드 추천" action="더 많은 키워드 보기 >" onAction={() => navigate('/map')}>
          <div style={cardBox}>
            {loading ? <LoadingBox /> : konapay.length === 0 ? <EmptyBox msg="표시할 가게가 없어요." /> : (
              konapay.slice(0, 2).map((r, i) => (
                <div key={r.id}>
                  {i > 0 && <div style={divider} />}
                  <RestaurantCard r={r} tags={['오늘의 추천', r.is_konapay ? '화성페이' : '']} onTap={() => navigate(`/restaurant/${r.id}`, { state: { restaurant: r } })} />
                </div>
              ))
            )}
          </div>
        </Section>

        <div style={{ height: 20 }} />

        {/* 우리집 근처 새로 오픈 */}
        <Section title="우리집 근처 새로 오픈" action="더보기 >" onAction={() => navigate('/map')}>
          <div style={cardBox}>
            {loading ? <LoadingBox /> : mobeom.length === 0 ? <EmptyBox msg="표시할 가게가 없어요." /> : (
              mobeom.slice(0, 2).map((r, i) => (
                <div key={r.id}>
                  {i > 0 && <div style={divider} />}
                  <RestaurantCard r={r} tags={[r.category || '음식점']} badge="NEW" onTap={() => navigate(`/restaurant/${r.id}`, { state: { restaurant: r } })} />
                </div>
              ))
            )}
          </div>
        </Section>

        <div style={{ height: 20 }} />

        {/* 화성 먹거리 행사 */}
        <Section title="화성 먹거리 행사" action="전체 보기 >" onAction={() => navigate('/calendar')}>
          {upcomingFestival ? (
            <FestivalBanner festival={upcomingFestival} onClick={() => navigate('/calendar')} />
          ) : (
            <div style={{ ...cardBox, padding: 24, textAlign: 'center' }}>
              <p style={{ color: '#999', fontSize: 14 }}>현재 진행 중인 행사가 없어요</p>
            </div>
          )}
        </Section>

        {/* 식사평 남기기 */}
        {isLoggedIn && (
          <>
            <div style={{ height: 20 }} />
            <div style={{
              display: 'flex', alignItems: 'center', gap: 14,
              background: '#fff', borderRadius: 16,
              boxShadow: '0 2px 10px rgba(0,0,0,0.06)',
              padding: '14px 16px',
            }}>
              <div style={{ width: 48, height: 48, borderRadius: 12, background: 'rgba(255,79,0,0.08)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, flexShrink: 0 }}>🍽</div>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 13, fontWeight: 700, color: '#201515' }}>식사평 남기기</p>
                <p style={{ fontSize: 12, color: '#888', marginTop: 2 }}>오늘 다녀온 가게의 식사평을 남겨보세요</p>
              </div>
              <button onClick={() => navigate('/map')} style={{ background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 14px', fontSize: 13, fontWeight: 700, cursor: 'pointer', flexShrink: 0 }}>
                작성하기
              </button>
            </div>
          </>
        )}

        {/* 화성시 로고 */}
        <div style={{ marginTop: 36, paddingTop: 24, borderTop: '1px solid #f0ede9', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
          <img src={`${import.meta.env.BASE_URL}hwaseong.png`} alt="화성시" style={{ width: '60%', maxWidth: 200, opacity: 0.75 }} />
          <p style={{ fontSize: 11, color: 'rgba(32,21,21,0.35)', textAlign: 'center' }}>볏섬은 화성시와 함께합니다</p>
        </div>

      </div>
    </div>
  )
}

function Section({ title, action, onAction, children }) {
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 15, fontWeight: 700, color: '#201515' }}>{title}</p>
        {action && <button onClick={onAction} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 12, color: 'rgba(32,21,21,0.4)' }}>{action}</button>}
      </div>
      {children}
    </div>
  )
}

function RestaurantCard({ r, tags = [], badge, onTap }) {
  const dist = r.distance_km
  const distText = dist != null ? (dist < 1 ? `${Math.round(dist * 1000)}m` : `${dist.toFixed(1)}km`) : null

  return (
    <button onClick={onTap} style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', padding: '12px 16px', display: 'flex', gap: 12, alignItems: 'center', textAlign: 'left' }}>
      {/* 음식 이미지 자리 */}
      <div style={{ width: 64, height: 64, borderRadius: 10, background: '#f0ede9', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontSize: 26 }}>🍴</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 14, fontWeight: 700, color: '#201515', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.name}</p>
        <p style={{ fontSize: 11, color: '#FF4F00', marginTop: 2 }}>
          {tags.filter(Boolean).join(' | ')}
          {badge && <span style={{ marginLeft: 6, background: '#FF4F00', color: '#fff', borderRadius: 4, padding: '1px 5px', fontSize: 10, fontWeight: 700 }}>{badge}</span>}
        </p>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
          {distText && <span style={{ fontSize: 11, color: '#aaa' }}>📍 {distText}</span>}
          {r.avg_rating != null && <span style={{ fontSize: 11, color: '#888' }}>⭐ {r.avg_rating.toFixed(1)} ({r.review_count})</span>}
          <span style={{ marginLeft: 'auto', fontSize: 11, color: 'rgba(32,21,21,0.35)', fontWeight: 600 }}>바로가기 &gt;</span>
        </div>
      </div>
    </button>
  )
}

function FestivalBanner({ festival: f, onClick }) {
  const isFest = f.event_type === '축제'
  const accent = isFest ? '#9C27B0' : '#FF4F00'
  const start = new Date(f.start_date)
  const end = new Date(f.end_date)
  const dDay = f.d_day ?? 0
  const dLabel = dDay > 0 ? `D-${dDay}` : dDay === 0 ? 'D-Day' : `D+${-dDay}`
  const dateStr = `${start.getFullYear()}.${String(start.getMonth()+1).padStart(2,'0')}.${String(start.getDate()).padStart(2,'0')} (${['일','월','화','수','목','금','토'][start.getDay()]}) ~ ${end.getFullYear()}.${String(end.getMonth()+1).padStart(2,'0')}.${String(end.getDate()).padStart(2,'0')} (${['일','월','화','수','목','금','토'][end.getDay()]})`

  return (
    <button onClick={onClick} style={{
      width: '100%', background: `rgba(${isFest ? '156,39,176' : '255,79,0'},0.06)`,
      border: `1px solid rgba(${isFest ? '156,39,176' : '255,79,0'},0.15)`,
      borderRadius: 16, padding: 20, cursor: 'pointer', textAlign: 'left',
      display: 'flex', gap: 16, alignItems: 'center',
    }}>
      <div style={{ width: 72, height: 72, borderRadius: '50%', background: `rgba(${isFest ? '156,39,176' : '255,79,0'},0.1)`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 34, flexShrink: 0 }}>
        {isFest ? '🎪' : '🍽'}
      </div>
      <div style={{ flex: 1 }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 36, fontWeight: 700, color: accent, lineHeight: 1, marginBottom: 6 }}>{dLabel}</p>
        <p style={{ fontSize: 14, fontWeight: 700, color: '#201515', marginBottom: 4 }}>{f.name}</p>
        <p style={{ fontSize: 12, color: '#888' }}>📅 {dateStr}</p>
        {f.location && <p style={{ fontSize: 12, color: '#888', marginTop: 2 }}>📍 {f.location}</p>}
      </div>
    </button>
  )
}

function LoadingBox() {
  return <div style={{ height: 80, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Spinner /></div>
}
function EmptyBox({ msg }) {
  return <p style={{ padding: 24, textAlign: 'center', color: '#999', fontSize: 14 }}>{msg}</p>
}
function Spinner() {
  return <div style={{ width: 24, height: 24, border: '2.5px solid #f0f0f0', borderTop: '2.5px solid #FF4F00', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
}

const cardBox = { background: '#fff', borderRadius: 16, boxShadow: '0 2px 10px rgba(0,0,0,0.06)', overflow: 'hidden' }
const divider = { height: 1, background: '#f5f5f5', margin: '0 16px' }
