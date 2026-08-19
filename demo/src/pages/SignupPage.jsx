import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

export default function SignupPage() {
  const navigate = useNavigate()
  const { login } = useAuth()
  const [form, setForm] = useState({ email: '', password: '', nickname: '' })
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)

  const set = (k) => (e) => setForm(p => ({ ...p, [k]: e.target.value }))
  const canSubmit = form.email.includes('@') && form.password.length >= 6 && form.nickname.length >= 1

  const handleSignup = async () => {
    if (!canSubmit || loading) return
    setLoading(true)
    try {
      await api.auth.signup(form.email, form.password, form.nickname)
      await login(form.email, form.password)
      navigate('/home', { replace: true })
    } catch (e) {
      setError(e?.detail || '회원가입에 실패했어요')
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
        <h1 style={{ fontFamily: '"Noto Serif KR"', fontSize: 22, fontWeight: 700, color: '#201515', marginTop: 8 }}>처음 오셨군요!</h1>
        <p style={{ fontSize: 13, color: 'rgba(32,21,21,0.5)', marginTop: 4, marginBottom: 36 }}>간단하게 가입하고 시작해요</p>

        {[
          { key: 'email', label: '이메일', type: 'email', placeholder: 'example@email.com' },
          { key: 'password', label: '비밀번호', type: 'password', placeholder: '6자 이상' },
          { key: 'nickname', label: '닉네임', type: 'text', placeholder: '화성시민' },
        ].map(({ key, label, type, placeholder }) => (
          <div key={key} style={{ marginBottom: 16 }}>
            <label style={labelStyle}>{label}</label>
            <input
              type={type}
              placeholder={placeholder}
              value={form[key]}
              onChange={set(key)}
              style={inputStyle}
            />
          </div>
        ))}

        {error && <p style={{ color: '#e53e3e', fontSize: 13, marginTop: 4 }}>{error}</p>}

        <button
          onClick={handleSignup}
          disabled={!canSubmit || loading}
          style={{
            width: '100%', height: 50, marginTop: 20,
            background: canSubmit ? '#FF4F00' : '#ddd',
            color: '#fff', border: 'none', borderRadius: 12,
            fontFamily: '"Noto Serif KR"', fontSize: 15, fontWeight: 700,
            cursor: canSubmit ? 'pointer' : 'not-allowed',
          }}
        >
          {loading ? '가입 중...' : '가입하기'}
        </button>
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
