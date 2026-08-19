import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

export default function ProfilePage() {
  const navigate = useNavigate()
  const { user, isLoggedIn, logout, refreshUser } = useAuth()
  const [points, setPoints] = useState(null)
  const [notifEnabled, setNotifEnabled] = useState(true)
  const [showLogoutDialog, setShowLogoutDialog] = useState(false)
  const [showWithdrawDialog, setShowWithdrawDialog] = useState(false)
  const [showNicknameDialog, setShowNicknameDialog] = useState(false)
  const [newNickname, setNewNickname] = useState('')
  const [nicknameLoading, setNicknameLoading] = useState(false)
  const [nicknameError, setNicknameError] = useState(null)

  useEffect(() => {
    if (isLoggedIn) {
      api.auth.points().catch(() => null).then(data => {
        if (data) setPoints(data.balance ?? 0)
      })
    }
  }, [isLoggedIn])

  const formatPoints = (p) => {
    if (p == null) return '—'
    return p >= 1000 ? p.toLocaleString() : String(p)
  }

  const handleNicknameChange = async () => {
    if (!newNickname.trim() || newNickname.trim().length < 2) return
    setNicknameLoading(true)
    setNicknameError(null)
    try {
      await api.auth.updateNickname(newNickname.trim())
      await refreshUser()
      setShowNicknameDialog(false)
      setNewNickname('')
    } catch (e) {
      setNicknameError(e?.detail || '닉네임 변경에 실패했어요')
    } finally {
      setNicknameLoading(false)
    }
  }

  const handleWithdraw = async () => {
    try {
      await api.auth.deleteAccount()
    } catch (_) {}
    logout()
    navigate('/home')
  }

  const verified = user?.is_resident_verified
  const expiresText = user?.resident_expires_at
    ? (() => {
        const d = new Date(user.resident_expires_at)
        return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}까지 유효`
      })()
    : verified ? '인증 완료' : '인증이 필요해요'

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
              <p style={{ fontSize: 12, color: '#999', marginTop: 2 }}>{user?.email || ''}</p>
            </div>
            <button style={btnOutline} onClick={() => { setNewNickname(user?.nickname || ''); setShowNicknameDialog(true) }}>닉네임 변경</button>
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
              <button style={{ ...btnOutline, flexShrink: 0 }} onClick={() => navigate('/reward')}>교환하기</button>
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
                <p style={{ fontSize: 12, color: '#999', marginTop: 2 }}>{expiresText}</p>
              </div>
              <button style={{ ...btnOutline, flexShrink: 0, fontSize: 13 }} onClick={() => navigate('/verify')}>
                {verified ? '갱신하기' : '인증하기'}
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
            <NavRow label="내가 쓴 식사평" onTap={() => navigate('/my-reviews')} />
            <Divider />
            <NavRow label="저장한 가게" onTap={() => navigate('/saved-restaurants')} />
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
        <NavRow label="개인정보 처리방침" onTap={() => navigate('/privacy-policy')} />
        <Divider />
        <NavRow label="위치정보 이용약관" onTap={() => navigate('/location-terms')} />
        <Divider />
        <NavRow label="데이터 출처 및 라이선스" onTap={() => navigate('/data-license')} />
      </WhiteCard>

      {isLoggedIn && (
        <>
          <div style={{ height: 12 }} />
          <WhiteCard>
            <NavRow label="로그아웃" onTap={() => setShowLogoutDialog(true)} />
          </WhiteCard>
          <div style={{ height: 16 }} />
          <div style={{ textAlign: 'center' }}>
            <button onClick={() => setShowWithdrawDialog(true)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 13, color: '#aaa' }}>
              회원 탈퇴
            </button>
          </div>
        </>
      )}

      {/* 화성시 로고 */}
      <div style={{ marginTop: 12, paddingBottom: 36, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
        <img src={`${import.meta.env.BASE_URL}hwaseong.png`} alt="화성시" style={{ width: '55%', maxWidth: 180, opacity: 0.6 }} />
        <p style={{ fontSize: 11, color: 'rgba(32,21,21,0.35)', textAlign: 'center' }}>볏섬은 화성시와 함께합니다</p>
      </div>

      {/* 로그아웃 다이얼로그 */}
      {showLogoutDialog && (
        <Dialog>
          <p style={dlgTitle}>로그아웃</p>
          <p style={dlgBody}>로그아웃 하시겠어요?</p>
          <div style={dlgBtns}>
            <button onClick={() => setShowLogoutDialog(false)} style={dlgCancel}>취소</button>
            <button onClick={() => { setShowLogoutDialog(false); logout(); navigate('/home') }} style={dlgConfirm}>로그아웃</button>
          </div>
        </Dialog>
      )}

      {/* 회원탈퇴 다이얼로그 */}
      {showWithdrawDialog && (
        <Dialog>
          <p style={dlgTitle}>회원 탈퇴</p>
          <p style={dlgBody}>탈퇴하면 모든 데이터가<br/>삭제됩니다. 계속할까요?</p>
          <div style={dlgBtns}>
            <button onClick={() => setShowWithdrawDialog(false)} style={dlgCancel}>취소</button>
            <button onClick={() => { setShowWithdrawDialog(false); handleWithdraw() }} style={{ ...dlgConfirm, color: '#e53e3e' }}>탈퇴</button>
          </div>
        </Dialog>
      )}

      {/* 닉네임 변경 다이얼로그 */}
      {showNicknameDialog && (
        <Dialog>
          <p style={dlgTitle}>닉네임 변경</p>
          <input
            value={newNickname}
            onChange={e => setNewNickname(e.target.value)}
            maxLength={10}
            placeholder="2~10자 입력"
            style={{ width: '100%', border: '1px solid #ddd', borderRadius: 8, padding: '10px 12px', fontSize: 14, outline: 'none', marginBottom: 4, boxSizing: 'border-box' }}
          />
          {nicknameError && <p style={{ color: '#e53e3e', fontSize: 12, marginBottom: 8 }}>{nicknameError}</p>}
          <div style={{ ...dlgBtns, marginTop: 8 }}>
            <button onClick={() => { setShowNicknameDialog(false); setNicknameError(null) }} style={dlgCancel}>취소</button>
            <button onClick={handleNicknameChange} disabled={nicknameLoading || newNickname.trim().length < 2} style={dlgConfirm}>
              {nicknameLoading ? '변경 중...' : '변경'}
            </button>
          </div>
        </Dialog>
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
function Dialog({ children }) {
  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999 }}>
      <div style={{ background: '#fff', borderRadius: 16, padding: 24, width: 280, margin: '0 20px' }}>{children}</div>
    </div>
  )
}

const btnOutline = { background: 'none', border: '1px solid #ccc', borderRadius: 20, cursor: 'pointer', fontSize: 13, fontWeight: 600, color: '#201515', padding: '8px 14px' }
const dlgTitle = { fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 16, marginBottom: 12, color: '#201515' }
const dlgBody = { fontSize: 14, color: '#666', marginBottom: 24, lineHeight: 1.6 }
const dlgBtns = { display: 'flex', gap: 8, justifyContent: 'flex-end' }
const dlgCancel = { background: 'none', border: 'none', cursor: 'pointer', color: '#666', fontSize: 14, padding: '8px 12px' }
const dlgConfirm = { background: 'none', border: 'none', cursor: 'pointer', color: '#FF4F00', fontSize: 14, fontWeight: 700, padding: '8px 12px' }
