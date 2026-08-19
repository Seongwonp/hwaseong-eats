import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

export default function NotificationsPage() {
  const navigate = useNavigate()
  const { isLoggedIn, user } = useAuth()
  const [festivals, setFestivals] = useState([])

  useEffect(() => {
    api.festivals.list().then(data => setFestivals(data.items || data || [])).catch(() => {})
  }, [])

  // 가장 가까운 축제
  const nearestFestival = festivals
    .filter(e => e.event_type === '축제' && (e.d_day ?? -1) >= 0)
    .sort((a, b) => a.d_day - b.d_day)[0] || null

  const dDayText = (d) => d > 0 ? `D-${d}` : d === 0 ? 'D-Day' : `D+${-d}`

  const festivalTitle = nearestFestival
    ? `화성 ${nearestFestival.name} ${dDayText(nearestFestival.d_day)}`
    : '화성 먹거리 행사 일정을 확인하세요'
  const festivalBody = nearestFestival
    ? `${new Date(nearestFestival.start_date).getMonth()+1}월 ${new Date(nearestFestival.start_date).getDate()}일 ~ ${new Date(nearestFestival.end_date).getMonth()+1}월 ${new Date(nearestFestival.end_date).getDate()}일${nearestFestival.location ? ` · ${nearestFestival.location}` : ''}`
    : '달력 탭에서 확인해보세요'

  // 포인트 알림
  const pts = user?.points ?? 0
  let pointTitle, pointBody, pointUnread = false, pointAction = null
  if (isLoggedIn) {
    if (pts >= 1000) {
      pointTitle = `포인트가 ${pts.toLocaleString()}P 넘었어요.`
      pointBody = '포인트를 교환하여 화성페이를 사용해보세요.'
      pointUnread = true
      pointAction = { label: '교환하기', action: () => {} }
    } else {
      pointTitle = `현재 보유 포인트는 ${pts}P 입니다.`
      pointBody = '1,000P 이상 모으면 화성페이로 교환할 수 있어요!'
    }
  } else {
    pointTitle = '로그인하고 포인트를 적립해보세요!'
    pointBody = '화성인증 가맹점에서 식사평을 남기면 포인트가 적립됩니다.'
    pointAction = { label: '로그인하기', action: () => navigate('/login') }
  }

  // 인증 알림
  let verifyTitle, verifyBody, verifyUnread = false, verifyAction = null
  if (isLoggedIn) {
    if (user?.is_verified) {
      verifyTitle = '화성 주민 인증이 정상 유지 중입니다.'
      verifyBody = `${user?.expires_at ?? '인증 완료'}. 혜택 배지를 유지하고 있어요.`
    } else {
      verifyTitle = '아직 화성 주민 인증을 하지 않으셨어요.'
      verifyBody = '주민 인증을 완료하면 화성인증 식사평 작성 시 500P를 적립받을 수 있어요!'
      verifyUnread = true
      verifyAction = { label: '인증하기', action: () => navigate('/profile') }
    }
  } else {
    verifyTitle = '화성 시민이신가요?'
    verifyBody = '주민 인증 시 화성인증 식사평으로 포인트를 적립받는 등 다양한 리워드를 누려보세요!'
    verifyAction = { label: '알아보기', action: () => navigate('/signup') }
  }

  return (
    <div style={{ height: '100%', overflowY: 'auto', background: '#FFFEFB' }}>
      <div style={{ padding: '20px 16px 0' }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 22, fontWeight: 700, color: '#201515' }}>알림</p>
        <p style={{ fontSize: 12, color: 'rgba(32,21,21,0.5)', marginTop: 2, marginBottom: 16 }}>화성시 먹거리 소식을 확인해보세요</p>
      </div>

      <div style={{ padding: '0 16px 32px' }}>
        <NotifItem
          iconBg="rgba(255,79,0,0.1)"
          icon={<StoreIcon color="#FF4F00" />}
          title="우리 집 근처에 새로 오픈한 가게"
          body="봉담읍에 새로 오픈한 '화성인증 맛집'이에요."
          timeAgo="방금 전"
          isUnread
          onTap={() => navigate('/map')}
        />
        <NotifItem
          iconBg="rgba(156,39,176,0.1)"
          icon={<FestIcon color="#9C27B0" />}
          title={festivalTitle}
          body={festivalBody}
          timeAgo="1시간 전"
          isUnread
          onTap={() => navigate('/calendar')}
        />
        <NotifItem
          iconBg="rgba(245,166,35,0.1)"
          icon={<StarIcon color="#F5A623" />}
          title={pointTitle}
          body={pointBody}
          timeAgo="16시간 전"
          isUnread={pointUnread}
          action={pointAction}
          onTap={pointAction?.action}
        />
        <NotifItem
          iconBg="rgba(76,175,80,0.1)"
          icon={<ShieldIcon color="#4CAF50" />}
          title={verifyTitle}
          body={verifyBody}
          timeAgo="어제"
          isUnread={verifyUnread}
          action={verifyAction}
          onTap={verifyAction?.action}
        />
        <NotifItem
          iconBg="rgba(150,150,150,0.1)"
          icon={<BellIcon color="#999" />}
          title="알림을 놓치고 싶지 않다면?"
          body="푸시 알림을 켜두면 더 빠르게 소식을 받을 수 있어요."
          timeAgo="어제"
          action={{ label: '설정하기', action: () => {} }}
        />
      </div>
    </div>
  )
}

function NotifItem({ iconBg, icon, title, body, timeAgo, isUnread = false, action, onTap }) {
  return (
    <div
      onClick={onTap}
      style={{
        marginBottom: 10,
        padding: 14,
        borderRadius: 12,
        border: `1px solid ${isUnread ? 'rgba(255,79,0,0.12)' : '#f5f5f5'}`,
        background: isUnread ? 'rgba(255,79,0,0.04)' : '#fff',
        cursor: onTap ? 'pointer' : 'default',
        display: 'flex', gap: 12, alignItems: 'flex-start',
      }}>
      <div style={{ width: 38, height: 38, borderRadius: '50%', background: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        {icon}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 4, marginBottom: 3 }}>
          <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 13, fontWeight: isUnread ? 700 : 400, color: '#201515', flex: 1 }}>{title}</p>
          {isUnread && <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#FF4F00', flexShrink: 0, marginTop: 4 }} />}
        </div>
        <p style={{ fontSize: 12, color: '#888', lineHeight: 1.5 }}>{body}</p>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 6 }}>
          <span style={{ fontSize: 11, color: '#bbb' }}>{timeAgo}</span>
          {action && (
            <button onClick={(e) => { e.stopPropagation(); action.action() }}
              style={{ background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 6, padding: '4px 10px', fontSize: 11, fontWeight: 700, cursor: 'pointer' }}>
              {action.label}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

function StoreIcon({ color }) {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
}
function FestIcon({ color }) {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"><path d="M21 10.5c0 6-9 12-9 12S3 16.5 3 10.5a9 9 0 1118 0z"/><circle cx="12" cy="10.5" r="3"/></svg>
}
function StarIcon({ color }) {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
}
function ShieldIcon({ color }) {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
}
function BellIcon({ color }) {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0"/></svg>
}
