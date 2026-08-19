import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

function loadKakaoSDK() {
  return new Promise((resolve) => {
    if (window.Kakao) {
      if (!window.Kakao.isInitialized()) window.Kakao.init(import.meta.env.VITE_KAKAO_JS_KEY)
      resolve()
      return
    }
    const script = document.createElement('script')
    script.src = 'https://t1.kakaocdn.net/kakao_js_sdk/2.7.4/kakao.min.js'
    script.onload = () => {
      window.Kakao.init(import.meta.env.VITE_KAKAO_JS_KEY)
      resolve()
    }
    document.head.appendChild(script)
  })
}

export default function SignupPage() {
  const navigate = useNavigate()
  const { login } = useAuth()
  const [email, setEmail] = useState('')
  const [pw, setPw] = useState('')
  const [nickname, setNickname] = useState('')
  const [showPw, setShowPw] = useState(false)
  const [agreed, setAgreed] = useState(false)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)
  const [kakaoLoading, setKakaoLoading] = useState(false)

  const canSubmit = email.includes('@') && pw.length >= 8 && nickname.trim().length >= 2 && agreed

  const handleSignup = async () => {
    if (!canSubmit || loading) return
    setLoading(true)
    try {
      await api.auth.signup(email, pw, nickname.trim())
      await login(email, pw)
      navigate('/home', { replace: true })
    } catch (e) {
      setError(e?.detail || '회원가입에 실패했어요')
    } finally {
      setLoading(false)
    }
  }

  const handleKakaoLogin = async () => {
    setKakaoLoading(true)
    try {
      await loadKakaoSDK()
      window.Kakao.Auth.authorize({
        redirectUri: 'https://seongwonp.github.io/hwaseong-eats/kakao-callback.html',
      })
    } catch (e) {
      console.error('Kakao authorize error:', e)
      setError(e?.message || '카카오 로그인 오류')
      setKakaoLoading(false)
    }
  }

  return (
    <div style={{ height: '100vh', background: '#FFFEFB', overflowY: 'auto' }}>
      <div style={{ padding: '0 24px 40px' }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '16px 0', color: '#201515', fontSize: 20 }}>←</button>

        <h1 style={{ fontFamily: '"Noto Serif KR"', fontSize: 22, fontWeight: 700, color: '#201515', marginTop: 8 }}>볏섬에 오신 걸 환영해요</h1>
        <p style={{ fontSize: 13, color: 'rgba(32,21,21,0.5)', marginTop: 4, marginBottom: 36 }}>닉네임을 설정하고 화성 먹거리 지도를 만들어요</p>

        <label style={labelStyle}>이메일</label>
        <input type="email" placeholder="example@email.com" value={email}
          onChange={e => setEmail(e.target.value)} style={inputStyle} />

        <label style={{ ...labelStyle, marginTop: 20 }}>비밀번호</label>
        <div style={{ position: 'relative' }}>
          <input type={showPw ? 'text' : 'password'} placeholder="8자 이상" value={pw}
            onChange={e => setPw(e.target.value)}
            style={{ ...inputStyle, paddingRight: 44 }} />
          <button onClick={() => setShowPw(!showPw)}
            style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#999', fontSize: 16 }}>
            {showPw ? '🙈' : '👁'}
          </button>
        </div>

        <label style={{ ...labelStyle, marginTop: 20 }}>닉네임</label>
        <input type="text" placeholder="2~10자 입력" value={nickname} maxLength={10}
          onChange={e => setNickname(e.target.value)} style={inputStyle} />

        {/* 약관 동의 체크박스 */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 24, cursor: 'pointer' }}
          onClick={() => setAgreed(!agreed)}>
          <div style={{
            width: 22, height: 22, borderRadius: 6, flexShrink: 0,
            background: agreed ? '#FF4F00' : '#fff',
            border: `1.5px solid ${agreed ? '#FF4F00' : '#ddd'}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'all 0.15s',
          }}>
            {agreed && <span style={{ color: '#fff', fontSize: 13, fontWeight: 700 }}>✓</span>}
          </div>
          <span style={{ fontSize: 13, color: '#201515' }}>서비스 이용약관 및 개인정보처리방침에 동의합니다</span>
        </div>

        {error && <p style={{ color: '#e53e3e', fontSize: 13, marginTop: 16 }}>{error}</p>}

        <button onClick={handleSignup} disabled={!canSubmit || loading}
          style={{
            width: '100%', height: 50, marginTop: 32,
            background: canSubmit ? '#FF4F00' : '#ddd',
            color: '#fff', border: 'none', borderRadius: 12,
            fontFamily: '"Noto Serif KR"', fontSize: 15, fontWeight: 700,
            cursor: canSubmit ? 'pointer' : 'not-allowed', transition: 'background 0.2s',
          }}>
          {loading ? '가입 중...' : '다음 — 화성주민 인증'}
        </button>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '20px 0' }}>
          <div style={{ flex: 1, height: 1, background: '#eee' }} />
          <span style={{ fontSize: 12, color: '#999' }}>또는</span>
          <div style={{ flex: 1, height: 1, background: '#eee' }} />
        </div>

        <button onClick={handleKakaoLogin} disabled={kakaoLoading}
          style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', padding: 0, opacity: kakaoLoading ? 0.6 : 1 }}>
          <img src={`${import.meta.env.BASE_URL}kakao_login_large_wide.png`} alt="카카오로 시작하기" style={{ width: '100%', display: 'block', borderRadius: 12 }} />
        </button>

        <div style={{ textAlign: 'center', marginTop: 12 }}>
          <button onClick={() => navigate('/home', { replace: true })}
            style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'rgba(32,21,21,0.4)', fontSize: 13 }}>
            나중에 하기 (지도만 볼게요)
          </button>
        </div>
      </div>
    </div>
  )
}

const labelStyle = { display: 'block', fontSize: 13, fontFamily: '"Noto Serif KR"', fontWeight: 700, color: '#201515', marginBottom: 8 }
const inputStyle = {
  width: '100%', height: 48, padding: '0 14px',
  border: '1px solid #ddd', borderRadius: 12,
  background: '#fff', fontSize: 13, color: '#201515',
  outline: 'none', fontFamily: '"Noto Sans KR"',
}
