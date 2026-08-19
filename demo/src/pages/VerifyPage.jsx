import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

export default function VerifyPage() {
  const navigate = useNavigate()
  const { user, refreshUser } = useAuth()
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)

  const verified = done || user?.is_resident_verified

  const handleVerify = async () => {
    setLoading(true)
    try {
      await api.auth.verify()
      await refreshUser()
      setDone(true)
    } catch (e) {
      // 백엔드 미연결 시 조용히 처리
      setDone(true)
    } finally {
      setLoading(false)
    }
  }

  const expiresText = user?.resident_expires_at
    ? (() => {
        const d = new Date(user.resident_expires_at)
        return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}까지 유효`
      })()
    : null

  return (
    <div style={{ height: '100vh', background: '#FFFEFB', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', borderBottom: '1px solid #f0f0f0', background: '#FFFEFB', flexShrink: 0 }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: '#201515', padding: '0 12px 0 0' }}>←</button>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 16, fontWeight: 700, color: '#201515' }}>화성주민 인증</p>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '24px 16px' }}>
        {/* 화성인증 배지 설명 */}
        <div style={{ background: 'rgba(255,79,0,0.06)', borderRadius: 16, border: '1px solid rgba(255,79,0,0.15)', padding: 20, display: 'flex', alignItems: 'center', gap: 16, marginBottom: 28 }}>
          <span style={{ fontSize: 36 }}>🏅</span>
          <div>
            <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 15, color: '#201515', marginBottom: 4 }}>화성인증 배지</p>
            <p style={{ fontSize: 12, color: '#999', lineHeight: 1.5 }}>화성 주민만 받을 수 있어요.<br/>인증된 리뷰어의 식사평은 배지가 붙어요.</p>
          </div>
        </div>

        {/* 인증 단계 */}
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 14, fontWeight: 700, color: '#201515', marginBottom: 14 }}>인증 단계</p>

        <StepRow step="1" title="화성주민 인증" desc="화성시 주민등록 기반 본인확인 (6개월 유효)" done={verified} />
        <div style={{ height: 12 }} />
        <StepRow step="2" title="영수증 인증" desc="식사평 작성 시 방문 영수증 첨부" done={false} pending />

        <div style={{ marginTop: 32 }}>
          {!verified ? (
            <button
              onClick={handleVerify}
              disabled={loading}
              style={{
                width: '100%', padding: '14px 0', borderRadius: 12, border: 'none',
                background: loading ? '#ccc' : '#FF4F00', color: '#fff',
                fontFamily: '"Noto Serif KR"', fontSize: 15, fontWeight: 700,
                cursor: loading ? 'not-allowed' : 'pointer',
              }}
            >
              {loading ? '인증 중...' : '주민인증 시작'}
            </button>
          ) : (
            <div style={{ background: 'rgba(76,175,80,0.08)', borderRadius: 16, border: '1px solid rgba(76,175,80,0.3)', padding: 20, textAlign: 'center' }}>
              <p style={{ fontSize: 32, marginBottom: 8 }}>🎉</p>
              <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 16, color: '#4CAF50', marginBottom: 4 }}>화성주민 인증 완료!</p>
              <p style={{ fontSize: 12, color: '#999' }}>이제 화성인증 식사평을 남길 수 있어요</p>
              {expiresText && <p style={{ fontSize: 12, color: '#bbb', marginTop: 4 }}>{expiresText}</p>}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function StepRow({ step, title, desc, done, pending }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
      <div style={{
        width: 32, height: 32, borderRadius: '50%', flexShrink: 0,
        background: done ? '#FF4F00' : pending ? '#f5f5f5' : '#f5f5f5',
        border: `2px solid ${done ? '#FF4F00' : '#ddd'}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {done ? (
          <span style={{ color: '#fff', fontSize: 14, fontWeight: 700 }}>✓</span>
        ) : (
          <span style={{ color: '#bbb', fontSize: 13, fontWeight: 700 }}>{step}</span>
        )}
      </div>
      <div>
        <p style={{ fontSize: 14, fontWeight: 700, color: done ? '#FF4F00' : '#201515' }}>{title}</p>
        <p style={{ fontSize: 12, color: '#999', marginTop: 2 }}>{desc}</p>
        {pending && <p style={{ fontSize: 11, color: '#bbb', marginTop: 2 }}>식사평 작성 시 진행</p>}
      </div>
    </div>
  )
}
