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
      api.restaurants.list({ is_konapay: true, limit: 10, food_only: false }),
      api.restaurants.list({ is_mobeom: true, limit: 10, food_only: false }),
      api.festivals.list().catch(() => ({ items: [] })),
    ]).then(([k, m, f]) => {
      setKonapay(k.items || [])
      setMobeom(m.items || [])
      setFestivals(f.items || f || [])
    }).finally(() => setLoading(false))
  }, [])

  const upcomingFestival = festivals[0] || null

  return (
    <div style={{ height: '100%', overflowY: 'auto', background: '#FFFEFB' }}>
      <div style={{ padding: '24px 20px 36px' }}>

        {/* Header */}
        <div style={{ marginBottom: 28 }}>
          <p style={{ fontSize: 13, color: 'rgba(32,21,21,0.5)' }}>안녕하세요,</p>
          {isLoggedIn ? (
            <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 22, fontWeight: 700, color: '#201515', marginTop: 2 }}>{user?.nickname || '사용자'}님</p>
          ) : (
            <button onClick={() => navigate('/login')} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, textAlign: 'left' }}>
              <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 24, fontWeight: 700, color: '#201515', marginTop: 2 }}>로그인 해주세요.</p>
            </button>
          )}
        </div>

        {/* 화성페이 가맹점 */}
        <Section
          title="화성페이 가맹점"
          action="지도에서 보기 >"
          onAction={() => navigate('/map')}
        >
          <RestaurantListCard
            items={konapay}
            loading={loading}
            emptyMsg="표시할 화성페이 가맹점이 없어요."
            badge="💳 화성페이"
            onTap={(r) => navigate(`/restaurant/${r.id}`)}
          />
        </Section>

        <div style={{ height: 20 }} />

        {/* 모범음식점 */}
        <Section title="화성시 모범음식점">
          <RestaurantListCard
            items={mobeom}
            loading={loading}
            emptyMsg="표시할 모범음식점이 없어요."
            badge="🏆 모범음식점"
            onTap={(r) => navigate(`/restaurant/${r.id}`)}
          />
        </Section>

        <div style={{ height: 20 }} />

        {/* 화성 먹거리 행사 */}
        <Section title="화성 먹거리 행사" action="전체 보기 >" onAction={() => navigate('/calendar')}>
          {upcomingFestival ? (
            <FestivalBanner festival={upcomingFestival} onClick={() => navigate('/calendar')} />
          ) : (
            <div style={{ background: 'rgba(255,79,0,0.04)', borderRadius: 16, padding: 24, textAlign: 'center' }}>
              <p style={{ color: '#999', fontSize: 14 }}>현재 진행 중인 행사가 없어요</p>
            </div>
          )}
        </Section>

        {/* 식사평 남기기 (로그인 시) */}
        {isLoggedIn && (
          <>
            <div style={{ height: 20 }} />
            <div style={{
              display: 'flex', alignItems: 'center', gap: 14,
              background: 'rgba(255,79,0,0.07)',
              border: '1px solid rgba(255,79,0,0.15)',
              borderRadius: 16, padding: '18px 20px',
            }}>
              <div style={{
                width: 52, height: 52, borderRadius: '50%',
                background: 'rgba(255,79,0,0.13)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, flexShrink: 0,
              }}>⭐</div>
              <div style={{ flex: 1 }}>
                <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 14, fontWeight: 700, color: '#201515' }}>식사평 남기기</p>
                <p style={{ fontSize: 12, color: '#888', marginTop: 2 }}>오늘 다녀온 가게의<br/>식사평을 남겨보세요</p>
              </div>
              <button
                onClick={() => navigate('/map')}
                style={{ background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 10, padding: '10px 14px', fontSize: 13, fontWeight: 700, cursor: 'pointer', flexShrink: 0 }}
              >
                작성하기
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}

function Section({ title, action, onAction, children }) {
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 16, fontWeight: 700, color: '#201515' }}>{title}</p>
        {action && (
          <button onClick={onAction} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 12, color: 'rgba(32,21,21,0.4)' }}>{action}</button>
        )}
      </div>
      {children}
    </div>
  )
}

function RestaurantListCard({ items, loading, emptyMsg, badge, onTap }) {
  if (loading) {
    return (
      <div style={cardWrap}>
        <div style={{ height: 120, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={spinner} />
        </div>
      </div>
    )
  }
  if (!items.length) {
    return (
      <div style={cardWrap}>
        <p style={{ padding: 24, textAlign: 'center', color: '#999', fontSize: 14 }}>{emptyMsg}</p>
      </div>
    )
  }
  return (
    <div style={cardWrap}>
      {items.map((r, i) => (
        <div key={r.id}>
          {i > 0 && <div style={{ height: 1, background: '#f0f0f0', margin: '0 20px' }} />}
          <RestaurantRow restaurant={r} badge={badge} onTap={() => onTap(r)} />
        </div>
      ))}
    </div>
  )
}

function RestaurantRow({ restaurant: r, badge, onTap }) {
  const rating = r.avg_rating
  const dist = r.distance_km
  const distText = dist != null ? (dist < 1 ? `${Math.round(dist * 1000)}m` : `${dist.toFixed(1)}km`) : null

  return (
    <button onClick={onTap} style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', padding: '11px 20px', display: 'flex', gap: 12, alignItems: 'center', textAlign: 'left' }}>
      <div style={{
        width: 80, height: 80, borderRadius: 12,
        background: 'rgba(255,79,0,0.07)',
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontSize: 28,
      }}>🍴</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 14, fontWeight: 700, color: '#201515', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.name}</p>
        {badge && <p style={{ fontSize: 12, color: '#FF4F00', marginTop: 4 }}>{badge}</p>}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 5 }}>
          {distText && <span style={{ fontSize: 11, color: '#aaa' }}>📍 {distText}</span>}
          {rating != null && <span style={{ fontSize: 11, color: '#888' }}>⭐ {rating.toFixed(1)} ({r.review_count})</span>}
          <span style={{ marginLeft: 'auto', fontSize: 11, color: 'rgba(32,21,21,0.4)', fontWeight: 600 }}>바로가기 &gt;</span>
        </div>
      </div>
    </button>
  )
}

function FestivalBanner({ festival: f, onClick }) {
  const start = new Date(f.start_date)
  const end = new Date(f.end_date)
  const dDay = f.d_day ?? 0
  const dLabel = dDay > 0 ? `D-${dDay}` : dDay === 0 ? 'D-Day' : `D+${-dDay}`
  const dateStr = `${start.getMonth()+1}.${start.getDate()} ~ ${end.getMonth()+1}.${end.getDate()}`
  const isFest = f.event_type === '축제'
  const accent = isFest ? '#9C27B0' : '#FF4F00'

  return (
    <button onClick={onClick} style={{
      width: '100%', background: `rgba(${isFest ? '156,39,176' : '255,79,0'},0.08)`,
      border: `1px solid rgba(${isFest ? '156,39,176' : '255,79,0'},0.18)`,
      borderRadius: 16, padding: 20, cursor: 'pointer', textAlign: 'left',
      display: 'flex', gap: 16, alignItems: 'center',
    }}>
      <div style={{ width: 72, height: 72, borderRadius: '50%', background: `rgba(${isFest ? '156,39,176' : '255,79,0'},0.12)`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 32, flexShrink: 0 }}>
        {isFest ? '🎪' : '🍽'}
      </div>
      <div style={{ flex: 1 }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 32, fontWeight: 700, color: accent, lineHeight: 1 }}>{dLabel}</p>
        <p style={{ fontSize: 14, fontWeight: 700, color: '#201515', marginTop: 4 }}>{f.name}</p>
        <p style={{ fontSize: 12, color: '#888', marginTop: 4 }}>📅 {dateStr}</p>
        {(f.location || f.location) && <p style={{ fontSize: 12, color: '#888', marginTop: 2 }}>📍 {f.location}</p>}
      </div>
    </button>
  )
}

const cardWrap = {
  background: '#fff',
  borderRadius: 16,
  boxShadow: '0 2px 10px rgba(0,0,0,0.06)',
  overflow: 'hidden',
}

const spinner = {
  width: 28, height: 28,
  border: '3px solid #f0f0f0',
  borderTop: '3px solid #FF4F00',
  borderRadius: '50%',
  animation: 'spin 0.8s linear infinite',
}
