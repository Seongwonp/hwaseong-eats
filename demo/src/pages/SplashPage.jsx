import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'

export default function SplashPage() {
  const navigate = useNavigate()
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    requestAnimationFrame(() => setVisible(true))
    const t = setTimeout(() => navigate('/home', { replace: true }), 1400)
    return () => clearTimeout(t)
  }, [navigate])

  return (
    <div style={{
      height: '100vh', background: '#FFFEFB',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      opacity: visible ? 1 : 0, transition: 'opacity 0.7s ease',
    }}>
      <div style={{
        width: 80, height: 80,
        background: '#FF4F00', borderRadius: 20,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        marginBottom: 20,
        boxShadow: '0 8px 24px rgba(255,79,0,0.3)',
      }}>
        <span style={{ fontSize: 36 }}>🍽</span>
      </div>
      <p style={{ fontFamily: '"Noto Serif KR", serif', fontSize: 36, fontWeight: 700, color: '#201515', lineHeight: 1 }}>볏섬</p>
      <p style={{ fontFamily: '"Noto Serif KR", serif', fontSize: 14, color: 'rgba(32,21,21,0.55)', marginTop: 8 }}>화성 먹거리 지도</p>
    </div>
  )
}
