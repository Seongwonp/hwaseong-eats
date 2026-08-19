import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

export default function ProfilePage() {
  const navigate = useNavigate()
  const { user, isLoggedIn, logout } = useAuth()
  const [points, setPoints] = useState(null)

  useEffect(() => {
    if (isLoggedIn) {
      api.auth.points().catch(() => null).then(data => {
        if (data) setPoints(data.total_points ?? data.points ?? 0)
      })
    }
  }, [isLoggedIn])

  return (
    <div style={{ height: '100%', overflowY: 'auto', background: '#f5f5f5' }}>
      <div style={{ padding: '20px 16px 16px' }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 26, fontWeight: 700, color: '#201515' }}>내 정보</p>
      </div>

      {/* 프로필 카드 */}
      <Card>
        {isLoggedIn ? (
          <div style={{ padding: 20, display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{ width: 56, height: 56, borderRadius: '50%', background: 'rgba(255,79,0,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24 }}>👤</div>
            <div style={{ flex: 1 }}>
              <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 18, fontWeight: 700, color: '#201515' }}>{user?.nickname || '사용자'}</p>
              <p style={{ fontSize: 13, color: '#888', marginTop: 2 }}>{user?.email}</p>
            </div>
          </div>
        ) : (
          <div style={{ padding: 20 }}>
            <p style={{ fontSize: 14, color: '#888', marginBottom: 12 }}>로그인하고 더 많은 기능을 이용해보세요</p>
            <button onClick={() => navigate('/login')} style={btnPrimary}>로그인 / 회원가입</button>
          </div>
        )}
      </Card>

      {isLoggedIn && (
        <>
          <div style={{ height: 12 }} />

          {/* 포인트 카드 */}
          <Card>
            <div style={{ padding: 20, display: 'flex', alignItems: 'center' }}>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 13, fontWeight: 600, color: '#201515' }}>내 포인트</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 6 }}>
                  <span style={{ fontSize: 22, color: '#FFBB33' }}>⭐</span>
                  <span style={{ fontFamily: '"Noto Serif KR"', fontSize: 26, fontWeight: 700, color: '#FF4F00' }}>
                    {points != null ? points.toLocaleString() : '—'} P
                  </span>
                </div>
                <p style={{ fontSize: 12, color: '#999', marginTop: 2 }}>1,000P부터 교환 가능</p>
              </div>
              <button style={{ ...btnOutline, flexShrink: 0 }}>교환하기</button>
            </div>
          </Card>

          <div style={{ height: 12 }} />
          <SectionLabel>인증</SectionLabel>
          <Card>
            <div style={{ padding: 20, display: 'flex', alignItems: 'center', gap: 14 }}>
              <div style={{ width: 48, height: 48, borderRadius: '50%', background: 'rgba(255,79,0,0.08)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, flexShrink: 0 }}>🛡</div>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 14, fontWeight: 700, color: '#201515' }}>화성 시민 인증</p>
                <p style={{ fontSize: 12, color: user?.is_verified ? '#FF4F00' : '#999', marginTop: 2 }}>
                  {user?.is_verified ? (user?.expires_at || '인증 완료') : '인증이 필요해요'}
                </p>
              </div>
              {!user?.is_verified && (
                <button style={{ ...btnOutline, flexShrink: 0, fontSize: 12 }}>인증하기</button>
              )}
            </div>
          </Card>

          <div style={{ height: 12 }} />
          <SectionLabel>계정</SectionLabel>
          <Card>
            <MenuRow label="내가 남긴 리뷰" icon="📝" />
            <div style={{ height: 1, background: '#f0f0f0', margin: '0 16px' }} />
            <MenuRow label="저장된 가게" icon="❤️" />
            <div style={{ height: 1, background: '#f0f0f0', margin: '0 16px' }} />
            <MenuRow label="알림 설정" icon="🔔" />
            <div style={{ height: 1, background: '#f0f0f0', margin: '0 16px' }} />
            <MenuRow label="로그아웃" icon="🚪" onTap={() => { logout(); navigate('/home') }} textColor="#999" />
          </Card>

          <div style={{ height: 12 }} />
          <SectionLabel>약관</SectionLabel>
          <Card>
            <MenuRow label="개인정보처리방침" icon="📄" />
            <div style={{ height: 1, background: '#f0f0f0', margin: '0 16px' }} />
            <MenuRow label="이용약관" icon="📋" />
          </Card>
        </>
      )}

      <div style={{ height: 32 }} />
    </div>
  )
}

function Card({ children }) {
  return <div style={{ background: '#fff', margin: '0 0', borderRadius: 0 }}>{children}</div>
}

function SectionLabel({ children }) {
  return <p style={{ fontSize: 12, fontWeight: 600, color: '#999', padding: '8px 16px 6px', background: '#f5f5f5' }}>{children}</p>
}

function MenuRow({ label, icon, onTap, textColor = '#201515' }) {
  return (
    <button onClick={onTap} style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
      <span style={{ fontSize: 18 }}>{icon}</span>
      <span style={{ flex: 1, fontSize: 14, color: textColor, textAlign: 'left' }}>{label}</span>
      <span style={{ color: '#ccc', fontSize: 18 }}>›</span>
    </button>
  )
}

const btnPrimary = { background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 10, cursor: 'pointer', fontSize: 14, fontWeight: 700, padding: '12px 20px', width: '100%', fontFamily: '"Noto Serif KR"' }
const btnOutline = { background: 'none', border: '1px solid #ddd', borderRadius: 20, cursor: 'pointer', fontSize: 13, color: '#201515', padding: '8px 14px', fontFamily: '"Noto Sans KR"' }
