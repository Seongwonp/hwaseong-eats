import { useState } from 'react'
import { useNavigate, useParams, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { api } from '../api'

const KEYWORDS = ['가성비', '카공족', '혼밥', '10대 픽']

export default function ReviewPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { state } = useLocation()
  const { isLoggedIn } = useAuth()
  const restaurant = state?.restaurant

  const [rating, setRating] = useState(null)
  const [hoverRating, setHoverRating] = useState(null)
  const [keywords, setKeywords] = useState(new Set())
  const [comment, setComment] = useState('')
  const [recommendation, setRecommendation] = useState(null)
  const [revisit, setRevisit] = useState(null)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)

  const toggleKeyword = (k) => {
    setKeywords(prev => {
      const next = new Set(prev)
      next.has(k) ? next.delete(k) : next.add(k)
      return next
    })
  }

  const canSubmit = rating != null || keywords.size > 0 || comment.trim().length > 0

  const handleSubmit = async () => {
    if (!canSubmit || submitting) return
    setSubmitting(true)
    setError(null)
    try {
      await api.reviews.create({
        restaurant_id: Number(id),
        rating: rating ?? undefined,
        tags: [...keywords],
        comment: comment.trim() || undefined,
      })
      navigate(`/restaurant/${id}`, { state: { restaurant, reviewTab: true }, replace: true })
    } catch (e) {
      setError(e?.detail || '리뷰 등록에 실패했어요')
      setSubmitting(false)
    }
  }

  if (!isLoggedIn) {
    return (
      <div style={{ height: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 16, background: '#fff' }}>
        <p style={{ fontSize: 36 }}>🔒</p>
        <p style={{ fontSize: 14, color: '#999' }}>로그인 후 식사평을 남길 수 있어요</p>
        <button onClick={() => navigate('/login')} style={primaryBtn}>로그인하기</button>
      </div>
    )
  }

  return (
    <div style={{ height: '100vh', background: '#f7f7f7', display: 'flex', flexDirection: 'column' }}>
      {/* 앱바 */}
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', background: '#fff', borderBottom: '1px solid #f0f0f0', flexShrink: 0 }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: '#201515', padding: '0 12px 0 0' }}>←</button>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 16, fontWeight: 700, color: '#201515' }}>리뷰 작성</p>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 100 }}>
        {/* 가게 정보 */}
        <div style={{ background: '#fff', padding: '16px 16px 12px' }}>
          <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 18, fontWeight: 700, color: '#201515' }}>
            {restaurant?.name || `음식점 #${id}`}
          </p>
          {restaurant?.category && <p style={{ fontSize: 13, color: '#888', marginTop: 3 }}>{restaurant.category}</p>}
          {restaurant?.address && <p style={{ fontSize: 12, color: '#aaa', marginTop: 2 }}>{restaurant.address}</p>}
          <div style={{ marginTop: 12, background: '#f6f6f6', borderRadius: 8, padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: 14 }}>ℹ️</span>
            <p style={{ fontSize: 12, color: '#888' }}>영수증 인증 기능 준비 중 · 현재 리뷰는 일반 리뷰로 등록돼요</p>
          </div>
        </div>

        <div style={{ height: 8 }} />

        {/* 평점 */}
        <SectionCard>
          <SectionTitle>평점</SectionTitle>
          <p style={{ fontSize: 12, color: '#999', marginBottom: 16 }}>전체 만족도</p>
          <div style={{ display: 'flex', gap: 8 }}>
            {[1,2,3,4,5].map(i => (
              <button
                key={i}
                onClick={() => setRating(rating === i ? null : i)}
                onMouseEnter={() => setHoverRating(i)}
                onMouseLeave={() => setHoverRating(null)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, fontSize: 44, lineHeight: 1, color: i <= (hoverRating ?? rating ?? 0) ? '#FFBB33' : '#ddd' }}
              >★</button>
            ))}
          </div>
        </SectionCard>

        <div style={{ height: 8 }} />

        {/* 키워드 */}
        <SectionCard>
          <SectionTitle>어떤 점이 좋았나요?</SectionTitle>
          <p style={{ fontSize: 12, color: '#999', marginBottom: 14 }}>중복 선택 가능</p>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10 }}>
            {KEYWORDS.map(k => {
              const sel = keywords.has(k)
              return (
                <button
                  key={k}
                  onClick={() => toggleKeyword(k)}
                  style={{
                    padding: '10px 16px', borderRadius: 24, fontSize: 13, fontWeight: 700, cursor: 'pointer',
                    background: sel ? '#FF4F00' : '#f4f4f4',
                    color: sel ? '#fff' : '#201515',
                    border: `1px solid ${sel ? '#FF4F00' : '#eee'}`,
                    transition: 'all 0.15s',
                  }}
                >{k}</button>
              )
            })}
          </div>
        </SectionCard>

        <div style={{ height: 8 }} />

        {/* 리뷰 내용 */}
        <SectionCard>
          <SectionTitle>리뷰 내용</SectionTitle>
          <p style={{ fontSize: 12, color: '#999', marginBottom: 12 }}>욕설, 허위 사실, 개인정보는 포함할 수 없습니다.</p>
          <textarea
            value={comment}
            onChange={e => setComment(e.target.value.slice(0, 100))}
            placeholder={'리뷰를 입력하세요\n\n예:\n버거가 따뜻하게 나와서 좋았고 감자튀김도 바삭했어요.\n점심시간이었는데 생각보다 빠르게 받아서 만족했습니다.'}
            style={{
              width: '100%', height: 130, padding: 14, boxSizing: 'border-box',
              border: '1px solid #eee', borderRadius: 12, resize: 'none', outline: 'none',
              fontSize: 13, color: '#201515', background: '#f9f9f9', lineHeight: 1.6,
              fontFamily: '"Noto Sans KR", sans-serif',
            }}
          />
          <p style={{ textAlign: 'right', fontSize: 12, marginTop: 6, color: comment.length > 80 ? '#FF4F00' : '#aaa' }}>
            {comment.length} / 100
          </p>
        </SectionCard>

        <div style={{ height: 8 }} />

        {/* 추가 선택 */}
        <SectionCard>
          <SectionTitle>추가 선택</SectionTitle>
          <p style={{ fontSize: 13, fontWeight: 600, color: '#201515', marginBottom: 10, marginTop: 16 }}>이 가게를 추천하나요?</p>
          <ChoiceRow options={['추천해요', '보통이에요']} selected={recommendation} onSelect={setRecommendation} />
          <p style={{ fontSize: 13, fontWeight: 600, color: '#201515', marginBottom: 10, marginTop: 18 }}>재방문 의사가 있나요?</p>
          <ChoiceRow options={['있어요', '잘 모르겠어요']} selected={revisit} onSelect={setRevisit} />
        </SectionCard>

        {error && <p style={{ color: '#e53e3e', fontSize: 13, padding: '12px 16px', textAlign: 'center' }}>{error}</p>}
      </div>

      {/* 하단 제출 버튼 */}
      <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, padding: '12px 16px 24px', background: '#fff', borderTop: '1px solid #f0f0f0' }}>
        <button
          onClick={handleSubmit}
          disabled={!canSubmit || submitting}
          style={{
            width: '100%', padding: '15px 0', borderRadius: 12, border: 'none',
            background: canSubmit ? '#FF4F00' : '#ddd',
            color: '#fff', fontFamily: '"Noto Serif KR"', fontSize: 15, fontWeight: 700,
            cursor: canSubmit ? 'pointer' : 'not-allowed',
          }}
        >
          {submitting ? '등록 중...' : '식사평 등록하기'}
        </button>
      </div>
    </div>
  )
}

function SectionCard({ children }) {
  return <div style={{ background: '#fff', padding: '20px 16px' }}>{children}</div>
}
function SectionTitle({ children }) {
  return <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 14, fontWeight: 700, color: '#201515', marginBottom: 4 }}>{children}</p>
}
function ChoiceRow({ options, selected, onSelect }) {
  return (
    <div style={{ display: 'flex', gap: 10 }}>
      {options.map(o => (
        <button
          key={o}
          onClick={() => onSelect(selected === o ? null : o)}
          style={{
            flex: 1, padding: '10px 0', borderRadius: 10, fontSize: 13, fontWeight: 600, cursor: 'pointer',
            background: selected === o ? 'rgba(255,79,0,0.08)' : '#f4f4f4',
            color: selected === o ? '#FF4F00' : '#666',
            border: `1.5px solid ${selected === o ? '#FF4F00' : 'transparent'}`,
          }}
        >{o}</button>
      ))}
    </div>
  )
}

const primaryBtn = { background: '#FF4F00', color: '#fff', border: 'none', borderRadius: 12, padding: '12px 28px', fontSize: 14, fontWeight: 700, cursor: 'pointer' }
