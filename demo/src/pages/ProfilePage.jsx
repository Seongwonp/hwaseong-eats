import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

export default function ProfilePage() {
  const navigate = useNavigate()
  const { user, isLoggedIn, logout } = useAuth()
  const [points, setPoints] = useState(null)
  const [notifEnabled, setNotifEnabled] = useState(true)
  const [showLogoutDialog, setShowLogoutDialog] = useState(false)

  useEffect(() => {
    if (isLoggedIn) {
      api.auth.points().catch(() => null).then(data => {
        if (data) setPoints(data.total_points ?? data.points ?? 0)
      })
    }
  }, [isLoggedIn])

  const formatPoints = (p) => {
    if (p == null) return '—'
    return p >= 1000 ? p.toLocaleString() : String(p)
  }

  return (
    <div style={{ height: '100%', overflowY: 'auto', background: '#f5f5f5' }}>
      <div style={{ padding: '20px 16px 16px' }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 26, fontWeight: 700, color: '#201515' }}>내 정보</p>
      </div>

      {/* 프로필 카드 */}
      <WhiteCard>
        {isLoggedIn ? (
          <div style={{ padding: 20, display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ width: 52, height: 52, borderRadius: '50%', background: '#FFDED0', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <svg width="28" height="28" viewBox="0 0 24 24" fill="#FF4F00"><path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8V21.6h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/></svg>
            </div>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 16, fontWeight: 700, color: '#201515' }}>{user?.nickname || '화성 주민'}</p>
            </div>
            <button style={btnOutline} onClick={() => {}}>닉네임 변경</button>
          </div>
        ) : (
          <button onClick={() => navigate('/login')} style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', padding: 20, display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ width: 52, height: 52, borderRadius: '50%', background: '#eee', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <svg width="28" height="28" viewBox="0 0 24 24" fill="#bbb"><path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8V21.6h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/></svg>
            </div>
            <span style={{ flex: 1, fontSize: 16, fontWeight: 700, color: '#201515', textAlign: 'left' }}>로그인 해주세요.</span>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="#ccc"><path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"/></svg>
          </button>
        )}
      </WhiteCard>

      {isLoggedIn && (
        <>
          <div style={{ height: 12 }} />

          {/* 포인트 카드 */}
          <WhiteCard>
            <div style={{ padding: 20, display: 'flex', alignItems: 'center' }}>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 13, fontWeight: 600, color: '#201515' }}>내 포인트</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 6 }}>
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="#FFBB33"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
                  <span style={{ fontFamily: '"Noto Serif KR"', fontSize: 26, fontWeight: 700, color: '#FF4F00' }}>
                    {formatPoints(points)} P
                  </span>
                </div>
                <p style={{ fontSize: 12, color: '#999', marginTop: 2 }}>1,000P부터 교환 가능</p>
              </div>
              <button style={{ ...btnOutline, flexShrink: 0 }}>교환하기</button>
            </div>
          </WhiteCard>

          <div style={{ height: 12 }} />

          {/* 인증 */}
          <SectionLabel>인증</SectionLabel>
          <WhiteCard>
            <div style={{ padding: 20, display: 'flex', alignItems: 'center', gap: 14 }}>
              <div style={{ width: 48, height: 48, borderRadius: '50%', background: 'rgba(255,79,0,0.08)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="#FF4F00"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z"/></svg>
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 14, fontWeight: 700, color: '#201515' }}>화성 시민 인증</p>
                <p style={{ fontSize: 12, color: '#999', marginTop: 2 }}>
                  {user?.is_verified ? (user?.expires_at || '인증 완료') : '인증이 필요해요'}
                </p>
              </div>
              <button style={{ ...btnOutline, flexShrink: 0, fontSize: 13 }}>
                {user?.is_verified ? '갱신하기' : '인증하기'}
              </button>
            </div>
          </WhiteCard>

          <div style={{ height: 12 }} />
        </>
      )}

      {/* 설정 */}
      <SectionLabel>설정</SectionLabel>
      <WhiteCard>
        {isLoggedIn && (
          <>
            <NavRow label="내가 쓴 식사평" />
            <Divider />
            <NavRow label="저장한 가게" />
            <Divider />
          </>
        )}
        {/* 알림 토글 */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '8px 16px' }}>
          <span style={{ flex: 1, fontSize: 14, fontWeight: 500, color: '#201515' }}>알림</span>
          <div
            onClick={() => setNotifEnabled(!notifEnabled)}
            style={{
              width: 44, height: 24, borderRadius: 12, cursor: 'pointer',
              background: notifEnabled ? '#FF4F00' : '#ddd',
              position: 'relative', transition: 'background 0.2s',
            }}>
            <div style={{
              width: 20, height: 20, borderRadius: '50%', background: '#fff',
              position: 'absolute', top: 2, left: notifEnabled ? 22 : 2,
              transition: 'left 0.2s', boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
            }} />
          </div>
        </div>
        <Divider />
        <NavRow label="개인정보 처리방침" />
        <Divider />
        <NavRow label="위치정보 이용약관" />
        <Divider />
        <NavRow label="데이터 출처 및 라이선스" />
      </WhiteCard>

      {isLoggedIn && (
        <>
          <div style={{ height: 12 }} />
          <WhiteCard>
            <NavRow label="로그아웃" onTap={() => setShowLogoutDialog(true)} />
          </WhiteCard>
          <div style={{ height: 16 }} />
          <div style={{ textAlign: 'center' }}>
            <button style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 13, color: '#aaa' }}>
              회원 탈퇴
            </button>
          </div>
        </>
      )}

      <div style={{ height: 32 }} />

      {/* 로그아웃 다이얼로그 */}
      {showLogoutDialog && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999 }}>
          <div style={{ background: '#fff', borderRadius: 16, padding: 24, width: 280, margin: '0 20px' }}>
            <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 16, marginBottom: 12, color: '#201515' }}>로그아웃</p>
            <p style={{ fontSize: 14, color: '#666', marginBottom: 24 }}>로그아웃 하시겠어요?</p>
            <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
              <button onClick={() => setShowLogoutDialog(false)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#666', fontSize: 14, padding: '8px 12px' }}>취소</button>
              <button onClick={() => { setShowLogoutDialog(false); logout(); navigate('/home') }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#FF4F00', fontSize: 14, fontWeight: 700, padding: '8px 12px' }}>로그아웃</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function WhiteCard({ children }) {
  return <div style={{ background: '#fff', width: '100%' }}>{children}</div>
}

function SectionLabel({ children }) {
  return <p style={{ fontSize: 13, fontWeight: 700, color: '#201515', padding: '0 16px 8px', background: '#f5f5f5' }}>{children}</p>
}

function NavRow({ label, onTap }) {
  return (
    <button onClick={onTap} style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', padding: '14px 16px', display: 'flex', alignItems: 'center', textAlign: 'left' }}>
      <span style={{ flex: 1, fontSize: 14, fontWeight: 500, color: '#201515' }}>{label}</span>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="rgba(32,21,21,0.3)"><path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"/></svg>
    </button>
  )
}

function Divider() {
  return <div style={{ height: 1, background: '#f2f2f2', margin: '0 16px' }} />
}

const btnOutline = { background: 'none', border: '1px solid #ccc', borderRadius: 20, cursor: 'pointer', fontSize: 13, fontWeight: 600, color: '#201515', padding: '8px 14px' }
