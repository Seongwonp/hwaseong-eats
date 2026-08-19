import { useNavigate } from 'react-router-dom'

export default function DataLicensePage() {
  const navigate = useNavigate()
  return <PolicyPage title="데이터 출처 및 라이선스" navigate={navigate} sections={sections} footnote="수집 시점 기준 데이터이며, 원본 제공처의 갱신 주기에 따라 실제 정보와 차이가 있을 수 있습니다." />
}

const sections = [
  {
    heading: '음식점 정보',
    body: '• 코나페이(경기지역화폐) 화성시 가맹점 정보 — search.konacard.co.kr\n• 화성시 모범음식점 현황 — 공공데이터포털(data.go.kr)\n• 전국일반음식점표준데이터 — 지방행정 인허가데이터(LOCALDATA), 공공데이터포털\n• 소상공인시장진흥공단 상가(상권)정보 — 좌표 보정용, 공공데이터포털',
  },
  {
    heading: '절기 · 축제 정보',
    body: '• 절기·명절·잡절 정보 — 한국천문연구원 특일 정보\n• 전국문화축제표준데이터 — 한국관광공사, 공공데이터포털',
  },
  {
    heading: '지도',
    body: '• 카카오맵 — Kakao Maps API (Kakao Corp.)',
  },
  {
    heading: '라이선스',
    body: '공공데이터포털을 통해 제공되는 데이터는 공공누리 제1유형(출처표시) 조건에 따라 이용합니다. 각 원본 데이터의 저작권은 제공 기관에 있습니다.',
  },
]

function PolicyPage({ title, navigate, sections, footnote }) {
  return (
    <div style={{ height: '100vh', background: '#FFFEFB', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', borderBottom: '1px solid #f0f0f0', flexShrink: 0 }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: '#201515', padding: '0 12px 0 0' }}>←</button>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 16, fontWeight: 700, color: '#201515' }}>{title}</p>
      </div>
      <div style={{ flex: 1, overflowY: 'auto', padding: '24px 16px 40px' }}>
        {sections.map((s, i) => (
          <div key={i} style={{ marginBottom: 24 }}>
            <p style={{ fontFamily: '"Noto Serif KR"', fontWeight: 700, fontSize: 14, color: '#201515', marginBottom: 8 }}>{s.heading}</p>
            <p style={{ fontSize: 13, color: '#555', lineHeight: 1.7, whiteSpace: 'pre-line' }}>{s.body}</p>
          </div>
        ))}
        {footnote && <p style={{ fontSize: 12, color: '#bbb', borderTop: '1px solid #f0f0f0', paddingTop: 16, lineHeight: 1.6 }}>{footnote}</p>}
      </div>
    </div>
  )
}
