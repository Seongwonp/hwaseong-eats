import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

function loadKakaoSDK() {
  return new Promise((resolve) => {
    if (window.Kakao) { resolve(); return }
    const script = document.createElement('script')
    script.src = 'https://t1.kakaocdn.net/kakao_js_sdk/2.7.4/kakao.min.js'
    script.onload = () => {
      if (!window.Kakao.isInitialized()) {
        window.Kakao.init(import.meta.env.VITE_KAKAO_JS_KEY)
      }
      resolve()
    }
    document.head.appendChild(script)
  })
}

export default function LoginPage() {
  const navigate = useNavigate()
  const { login, error, setError } = useAuth()
  const [email, setEmail] = useState('')
  const [pw, setPw] = useState('')
  const [showPw, setShowPw] = useState(false)
  const [loading, setLoading] = useState(false)
  const [kakaoLoading, setKakaoLoading] = useState(false)

  useEffect(() => { loadKakaoSDK() }, [])

  const canSubmit = email.includes('@') && pw.length >= 6

  const handleKakaoLogin = async () => {
    setKakaoLoading(true)
    try {
      await loadKakaoSDK()
      const accessToken = await new Promise((resolve, reject) => {
        window.Kakao.Auth.login({
          success: (auth) => resolve(auth.access_token),
          fail: reject,
        })
      })
      const data = await api.auth.kakaoLogin(accessToken)
      localStorage.setItem('token', data.access_token)
      navigate('/home', { replace: true })
    } catch (e) {
      setError(e?.error_description || e?.detail || JSON.stringify(e) || '카카오 로그인에 실패했어요')
    } finally {
      setKakaoLoading(false)
    }
  }

  const handleLogin = async () => {
    if (!canSubmit || loading) return
    setLoading(true)
    try {
      await login(email, pw)
      navigate('/home', { replace: true })
    } catch (e) {
      setError(e?.detail || '이메일 또는 비밀번호를 확인해주세요')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ height: '100vh', background: '#FFFEFB', overflowY: 'auto' }}>
      <div style={{ padding: '0 24px 40px' }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '16px 0', color: '#201515' }}>
          ← 뒤로
        </button>
        <h1 style={{ fontFamily: '"Noto Serif KR"', fontSize: 22, fontWeight: 700, color: '#201515', marginTop: 8 }}>다시 오셨군요!</h1>
        <p style={{ fontSize: 13, color: 'rgba(32,21,21,0.5)', marginTop: 4, marginBottom: 36 }}>이메일로 로그인해 주세요</p>

        <label style={labelStyle}>이메일</label>
        <input
          type="email"
          placeholder="example@email.com"
          value={email}
          onChange={e => setEmail(e.target.value)}
          style={inputStyle}
        />

        <label style={{ ...labelStyle, marginTop: 20 }}>비밀번호</label>
        <div style={{ position: 'relative' }}>
          <input
            type={showPw ? 'text' : 'password'}
            placeholder="6자 이상"
            value={pw}
            onChange={e => setPw(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleLogin()}
            style={{ ...inputStyle, paddingRight: 44 }}
          />
          <button
            onClick={() => setShowPw(!showPw)}
            style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#999' }}
          >
            {showPw ? '🙈' : '👁'}
          </button>
        </div>

        {error && <p style={{ color: '#e53e3e', fontSize: 13, marginTop: 10 }}>{error}</p>}

        <button
          onClick={handleLogin}
          disabled={!canSubmit || loading}
          style={{
            width: '100%', height: 50, marginTop: 32,
            background: canSubmit ? '#FF4F00' : '#ddd',
            color: '#fff', border: 'none', borderRadius: 12,
            fontFamily: '"Noto Serif KR"', fontSize: 15, fontWeight: 700,
            cursor: canSubmit ? 'pointer' : 'not-allowed',
            transition: 'background 0.2s',
          }}
        >
          {loading ? '로그인 중...' : '로그인'}
        </button>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '20px 0' }}>
          <div style={{ flex: 1, height: 1, background: '#eee' }} />
          <span style={{ fontSize: 12, color: '#999' }}>또는</span>
          <div style={{ flex: 1, height: 1, background: '#eee' }} />
        </div>

        <button
          onClick={handleKakaoLogin}
          disabled={kakaoLoading}
          style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', padding: 0, opacity: kakaoLoading ? 0.6 : 1 }}
        >
          <img src={`${import.meta.env.BASE_URL}kakao_login_large_wide.png`} alt="카카오로 시작하기" style={{ width: '100%', display: 'block', borderRadius: 12 }} />
        </button>

        <div style={{ textAlign: 'center', marginTop: 20 }}>
          <button
            onClick={() => navigate('/signup')}
            style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#FF4F00', fontSize: 13 }}
          >
            아직 계정이 없어요 → 회원가입
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
