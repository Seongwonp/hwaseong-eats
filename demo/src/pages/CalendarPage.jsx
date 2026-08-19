import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { api } from '../api'

const DAYS = ['일', '월', '화', '수', '목', '금', '토']

export default function CalendarPage() {
  const navigate = useNavigate()
  const [festivals, setFestivals] = useState([])
  const [loading, setLoading] = useState(true)
  const today = new Date()
  const [focusedMonth, setFocusedMonth] = useState(new Date(today.getFullYear(), today.getMonth(), 1))

  useEffect(() => {
    api.festivals.list()
      .then(data => setFestivals(data.items || data || []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const prevMonth = () => setFocusedMonth(m => new Date(m.getFullYear(), m.getMonth() - 1, 1))
  const nextMonth = () => setFocusedMonth(m => new Date(m.getFullYear(), m.getMonth() + 1, 1))

  const eventsForDay = (day) => {
    const date = new Date(focusedMonth.getFullYear(), focusedMonth.getMonth(), day)
    return festivals.filter(e => {
      const start = new Date(e.start_date)
      const end = new Date(e.end_date)
      return date >= start && date <= end
    })
  }

  const monthEvents = festivals.filter(e => {
    const start = new Date(e.start_date)
    const end = new Date(e.end_date)
    const monthStart = new Date(focusedMonth.getFullYear(), focusedMonth.getMonth(), 1)
    const monthEnd = new Date(focusedMonth.getFullYear(), focusedMonth.getMonth() + 1, 0, 23, 59, 59)
    return !(end < monthStart || start > monthEnd)
  }).sort((a, b) => new Date(a.start_date) - new Date(b.start_date))

  const firstDay = new Date(focusedMonth.getFullYear(), focusedMonth.getMonth(), 1).getDay()
  const lastDate = new Date(focusedMonth.getFullYear(), focusedMonth.getMonth() + 1, 0).getDate()
  const totalCells = firstDay + lastDate
  const rows = Math.ceil(totalCells / 7)

  if (loading) return (
    <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#FFFEFB' }}>
      <Spinner />
    </div>
  )

  return (
    <div style={{ height: '100%', overflowY: 'auto', background: '#FFFEFB' }}>
      <div style={{ padding: '20px 20px 0' }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 22, fontWeight: 700, color: '#201515' }}>먹거리 달력</p>
        <p style={{ fontSize: 12, color: 'rgba(32,21,21,0.5)', marginTop: 2, marginBottom: 16 }}>화성시 축제를 확인해보세요</p>
      </div>

      {/* 달력 */}
      <div style={{ margin: '0 20px 8px', background: '#fff', borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.05)', padding: 16 }}>
        {/* 월 네비게이션 */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <button onClick={prevMonth} style={navBtn}>‹</button>
          <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 15, color: '#201515' }}>
            {focusedMonth.getFullYear()}년 {focusedMonth.getMonth() + 1}월
          </p>
          <button onClick={nextMonth} style={navBtn}>›</button>
        </div>

        {/* 요일 헤더 */}
        <div style={{ display: 'flex', marginBottom: 8 }}>
          {DAYS.map((d, i) => (
            <div key={d} style={{ flex: 1, textAlign: 'center', fontSize: 12, fontWeight: 600, color: i === 0 ? '#f87171' : i === 6 ? '#93c5fd' : '#9ca3af' }}>{d}</div>
          ))}
        </div>

        {/* 날짜 그리드 */}
        {Array.from({ length: rows }, (_, row) => (
          <div key={row} style={{ display: 'flex' }}>
            {Array.from({ length: 7 }, (_, col) => {
              const cellIndex = row * 7 + col
              const day = cellIndex - firstDay + 1
              if (day < 1 || day > lastDate) return <div key={col} style={{ flex: 1, height: 36 }} />
              const isToday = focusedMonth.getFullYear() === today.getFullYear() && focusedMonth.getMonth() === today.getMonth() && day === today.getDate()
              const dayEvts = eventsForDay(day)
              const isSun = col === 0
              const isSat = col === 6
              return (
                <div key={col} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '2px 0' }}>
                  <div style={{
                    width: 30, height: 30, borderRadius: '50%',
                    background: isToday ? '#FF4F00' : 'transparent',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <span style={{ fontSize: 13, fontWeight: isToday ? 700 : 400, color: isToday ? '#fff' : isSun ? '#f87171' : isSat ? '#93c5fd' : '#201515' }}>{day}</span>
                  </div>
                  <div style={{ display: 'flex', gap: 1, minHeight: 6 }}>
                    {dayEvts.slice(0, 2).map((e, i) => (
                      <div key={i} style={{ width: 4, height: 4, borderRadius: '50%', background: e.event_type === '축제' ? '#9C27B0' : '#FF4F00' }} />
                    ))}
                  </div>
                </div>
              )
            })}
          </div>
        ))}
      </div>

      {/* 범례 */}
      <div style={{ display: 'flex', gap: 16, padding: '4px 20px 0' }}>
        <LegendDot color="#FF4F00" label="절기·명절" />
        <LegendDot color="#9C27B0" label="축제" />
      </div>

      {/* 월별 일정 */}
      <div style={{ padding: '24px 20px 12px' }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 14, color: '#201515' }}>
          {focusedMonth.getMonth() + 1}월 먹거리 일정
        </p>
      </div>

      <div style={{ padding: '0 20px 32px' }}>
        {monthEvents.length === 0 ? (
          <p style={{ fontSize: 13, color: '#999' }}>{focusedMonth.getMonth() + 1}월 일정이 없어요</p>
        ) : (
          monthEvents.map(e => <EventRow key={e.id} event={e} onTap={() => navigate('/map')} />)
        )}
      </div>
    </div>
  )
}

function EventRow({ event: e, onTap }) {
  const isFest = e.event_type === '축제'
  const color = isFest ? '#9C27B0' : '#FF4F00'
  const start = new Date(e.start_date)
  const end = new Date(e.end_date)
  const dDay = e.d_day ?? 0
  const dLabel = dDay > 0 ? `D-${dDay}` : dDay === 0 ? 'D-Day' : `D+${-dDay}`
  const sameDay = start.getDate() === end.getDate() && start.getMonth() === end.getMonth()
  const dateLabel = sameDay
    ? `${start.getMonth()+1}월 ${start.getDate()}일`
    : `${start.getMonth()+1}월 ${start.getDate()}일 ~ ${end.getMonth()+1}월 ${end.getDate()}일`

  return (
    <button onClick={onTap} style={{
      width: '100%', marginBottom: 10, background: '#fff', border: `1px solid ${color}40`,
      borderRadius: 12, padding: '14px 16px', cursor: 'pointer', textAlign: 'left',
      boxShadow: '0 1px 6px rgba(0,0,0,0.04)', display: 'flex', alignItems: 'center', gap: 14,
    }}>
      <div style={{ width: 52, padding: '6px 0', background: `${color}1f`, borderRadius: 8, textAlign: 'center', flexShrink: 0 }}>
        <span style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 15, color }}>{dLabel}</span>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 13, color: '#201515' }}>{e.name}</p>
        <p style={{ fontSize: 11, color: '#9ca3af', marginTop: 3 }}>{dateLabel} · {isFest ? '축제' : e.event_type}</p>
        {e.location && <p style={{ fontSize: 11, color: '#bbb', marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{e.location}</p>}
      </div>
      <span style={{ color: '#ccc', fontSize: 18, flexShrink: 0 }}>›</span>
    </button>
  )
}

function LegendDot({ color, label }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
      <div style={{ width: 8, height: 8, borderRadius: '50%', background: color }} />
      <span style={{ fontSize: 11, color: '#9ca3af' }}>{label}</span>
    </div>
  )
}

function Spinner() {
  return <div style={{ width: 28, height: 28, border: '3px solid #f0f0f0', borderTop: '3px solid #FF4F00', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
}

const navBtn = { background: 'none', border: 'none', cursor: 'pointer', fontSize: 22, color: '#201515', padding: '0 4px', lineHeight: 1 }
