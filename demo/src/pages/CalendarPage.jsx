import { useState, useEffect } from 'react'
import { api } from '../api'

export default function CalendarPage() {
  const [festivals, setFestivals] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.festivals.list()
      .then(data => setFestivals(data.items || data || []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  return (
    <div style={{ height: '100%', overflowY: 'auto', background: '#FFFEFB' }}>
      <div style={{ padding: '24px 20px 36px' }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 26, fontWeight: 700, color: '#201515', marginBottom: 20 }}>화성 먹거리 행사</p>
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: 40 }}>
            <div style={{ width: 28, height: 28, border: '3px solid #f0f0f0', borderTop: '3px solid #FF4F00', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
          </div>
        ) : festivals.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px 0', color: '#aaa' }}>
            <p style={{ fontSize: 36, marginBottom: 12 }}>📅</p>
            <p style={{ fontSize: 14 }}>현재 예정된 행사가 없어요</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {festivals.map(f => <FestivalCard key={f.id} festival={f} />)}
          </div>
        )}
      </div>
    </div>
  )
}

function FestivalCard({ festival: f }) {
  const isFest = f.event_type === '축제'
  const accent = isFest ? '#9C27B0' : '#FF4F00'
  const start = new Date(f.start_date)
  const end = new Date(f.end_date)
  const dDay = f.d_day ?? 0
  const dLabel = dDay > 0 ? `D-${dDay}` : dDay === 0 ? 'D-Day' : `D+${-dDay}`
  const dateStr = `${start.getFullYear()}.${String(start.getMonth()+1).padStart(2,'0')}.${String(start.getDate()).padStart(2,'0')} ~ ${end.getFullYear()}.${String(end.getMonth()+1).padStart(2,'0')}.${String(end.getDate()).padStart(2,'0')}`

  return (
    <div style={{
      background: '#fff', borderRadius: 16,
      boxShadow: '0 2px 10px rgba(0,0,0,0.06)',
      padding: 20, display: 'flex', gap: 16, alignItems: 'center',
    }}>
      <div style={{ width: 60, height: 60, borderRadius: '50%', background: `${accent}1a`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28, flexShrink: 0 }}>
        {isFest ? '🎪' : '🍽'}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
          <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 14, fontWeight: 700, color: '#201515', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', flex: 1 }}>{f.name}</p>
          <span style={{ fontSize: 13, fontWeight: 700, color: accent, flexShrink: 0, marginLeft: 8 }}>{dLabel}</span>
        </div>
        <p style={{ fontSize: 12, color: '#888' }}>📅 {dateStr}</p>
        {f.location && <p style={{ fontSize: 12, color: '#888', marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>📍 {f.location}</p>}
        {f.description && <p style={{ fontSize: 12, color: '#aaa', marginTop: 4, overflow: 'hidden', textOverflow: 'ellipsis', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>{f.description}</p>}
      </div>
    </div>
  )
}
