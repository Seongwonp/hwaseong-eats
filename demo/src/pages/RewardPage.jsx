import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { api } from '../api'

export default function RewardPage() {
  const navigate = useNavigate()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [showDialog, setShowDialog] = useState(false)
  const [exchanging, setExchanging] = useState(false)

  const load = () => {
    setLoading(true)
    api.auth.points()
      .then(setData)
      .catch(() => setError('포인트 정보를 불러오지 못했어요'))
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const handleExchange = async () => {
    setExchanging(true)
    try {
      const res = await api.auth.exchange(1000)
      setData(prev => ({ ...prev, balance: res.balance }))
      setShowDialog(false)
      showToast('화성페이 1,000원 전환 완료!')
    } catch (e) {
      showToast(e?.detail || '전환에 실패했어요')
    } finally {
      setExchanging(false)
    }
  }

  const balance = data?.balance ?? 0

  return (
    <div style={{ height: '100vh', background: '#FFFEFB', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', borderBottom: '1px solid #f0f0f0', background: '#FFFEFB', flexShrink: 0 }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: '#201515', padding: '0 12px 0 0' }}>←</button>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 16, fontWeight: 700, color: '#201515' }}>리워드</p>
      </div>

      {loading ? (
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Spinner /></div>
      ) : error ? (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 12 }}>
          <p style={{ color: '#999', fontSize: 14 }}>{error}</p>
          <button onClick={load} style={retryBtn}>다시 시도</button>
        </div>
      ) : (
        <div style={{ flex: 1, overflowY: 'auto', padding: '0 16px 40px' }}>
          {/* 포인트 카드 */}
          <div style={{ margin: '20px 0', padding: 24, borderRadius: 20, background: 'linear-gradient(135deg, #FF4F00, #FF7A33)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <p style={{ color: 'rgba(255,255,255,0.7)', fontSize: 13 }}>볏섬 포인트</p>
              <span style={{ background: 'rgba(255,255,255,0.2)', borderRadius: 20, padding: '4px 10px', color: '#fff', fontSize: 11, fontWeight: 700 }}>화성주민 인증</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6 }}>
              <p style={{ fontFamily: '"Noto Serif KR"', color: '#fff', fontSize: 40, fontWeight: 700, lineHeight: 1 }}>{balance.toLocaleString()}</p>
              <p style={{ color: 'rgba(255,255,255,0.7)', fontSize: 18, fontWeight: 700, marginBottom: 4 }}>P</p>
            </div>
            <p style={{ color: 'rgba(255,255,255,0.6)', fontSize: 12, marginTop: 4 }}>화성인증 식사평 1건당 +500P</p>
          </div>

          {/* 전환 버튼 */}
          <button
            onClick={() => balance >= 1000 && setShowDialog(true)}
            disabled={balance < 1000}
            style={{
              width: '100%', padding: '14px 0', borderRadius: 12, border: 'none',
              background: balance >= 1000 ? '#FF4F00' : '#ddd',
              color: '#fff', fontFamily: '"Noto Serif KR"', fontSize: 15, fontWeight: 700,
              cursor: balance >= 1000 ? 'pointer' : 'not-allowed',
            }}
          >
            💳 화성페이로 전환하기
          </button>
          <p style={{ textAlign: 'center', fontSize: 12, color: 'rgba(32,21,21,0.4)', marginTop: 8 }}>1,000P = 1,000원 화성페이 (최소 1,000P)</p>

          {/* 포인트 적립 방법 */}
          <div style={{ marginTop: 28 }}>
            <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 14, fontWeight: 700, color: '#201515', marginBottom: 12 }}>포인트 적립 방법</p>
            <div style={{ background: '#fff', borderRadius: 12, border: '1px solid #eee', padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ fontSize: 24 }}>🏅</span>
              <div style={{ flex: 1 }}>
                <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 13, color: '#201515' }}>화성인증 식사평</p>
                <p style={{ fontSize: 12, color: '#999', marginTop: 2 }}>주민인증 + 영수증 인증 후 식사평 작성</p>
              </div>
              <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 15, color: '#FF4F00' }}>+500P</p>
            </div>
          </div>

          {/* 포인트 내역 */}
          <div style={{ marginTop: 28 }}>
            <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 14, fontWeight: 700, color: '#201515', marginBottom: 12 }}>포인트 내역</p>
            {!data?.items || data.items.length === 0 ? (
              <p style={{ fontSize: 13, color: '#999' }}>아직 내역이 없어요.</p>
            ) : (
              data.items.map((item, i) => (
                <div key={item.id} style={{ paddingBottom: 10, marginBottom: 10, borderBottom: i < data.items.length - 1 ? '1px solid #f0f0f0' : 'none', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 600, fontSize: 13, color: '#201515' }}>{item.reason}</p>
                    <p style={{ fontSize: 11, color: '#999', marginTop: 2 }}>{formatDate(item.created_at)}</p>
                  </div>
                  <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 14, color: item.delta > 0 ? '#4CAF50' : '#999' }}>
                    {item.delta > 0 ? '+' : ''}{item.delta} P
                  </p>
                </div>
              ))
            )}
          </div>
        </div>
      )}

      {/* 전환 다이얼로그 */}
      {showDialog && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, padding: 20 }}>
          <div style={{ background: '#fff', borderRadius: 16, padding: 24, width: '100%', maxWidth: 300 }}>
            <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 16, color: '#201515', marginBottom: 12 }}>화성페이 전환</p>
            <p style={{ fontSize: 14, color: '#666', textAlign: 'center', marginBottom: 8 }}>1,000 P를 화성페이 1,000원으로<br/>전환할까요?</p>
            <p style={{ fontSize: 12, color: '#999', textAlign: 'center', marginBottom: 24 }}>실제 화성페이 연동 전 데모 시연용 기능이에요</p>
            <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
              <button onClick={() => setShowDialog(false)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#999', fontSize: 14, padding: '8px 12px' }}>취소</button>
              <button onClick={handleExchange} disabled={exchanging}
                style={{ background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 14, fontWeight: 700, cursor: 'pointer' }}>
                {exchanging ? '처리 중...' : '전환하기'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function formatDate(iso) {
  const d = new Date(iso)
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`
}

function showToast(msg) {
  const el = document.createElement('div')
  el.textContent = msg
  Object.assign(el.style, { position: 'fixed', bottom: '80px', left: '50%', transform: 'translateX(-50%)', background: 'rgba(0,0,0,0.7)', color: '#fff', borderRadius: '20px', padding: '8px 20px', fontSize: '13px', zIndex: 99999, whiteSpace: 'nowrap' })
  document.body.appendChild(el)
  setTimeout(() => el.remove(), 2000)
}

function Spinner() {
  return <div style={{ width: 28, height: 28, border: '2.5px solid #f0f0f0', borderTop: '2.5px solid #FF4F00', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
}
const retryBtn = { background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 20, padding: '8px 20px', fontSize: 13, cursor: 'pointer' }
