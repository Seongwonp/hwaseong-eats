import { useNavigate } from 'react-router-dom'

export default function PrivacyPolicyPage() {
  const navigate = useNavigate()
  return <PolicyPage title="개인정보 처리방침" navigate={navigate} sections={sections} footnote="본 화면은 해커톤 데모용으로 작성된 예시 문서이며, 실제 법률 검토를 거치지 않았습니다." />
}

const sections = [
  { heading: '1. 수집하는 개인정보 항목', body: '볏섬은 회원가입 시 이메일, 비밀번호, 닉네임을 수집합니다. 카카오 로그인을 이용하는 경우 카카오가 제공하는 회원번호를 수집합니다. 화성 주민 인증 시에는 인증 결과와 유효기간만 저장하며, 인증에 사용한 서류 원본은 저장하지 않습니다.' },
  { heading: '2. 수집 목적', body: '회원 식별 및 로그인, 화성 주민 인증 및 화성인증 식사평 제공, 리워드 포인트 적립·전환, 서비스 부정이용 방지를 위해 개인정보를 이용합니다.' },
  { heading: '3. 보유 및 이용 기간', body: '회원 탈퇴 시 지체 없이 파기합니다. 다만 관계 법령에 따라 보존이 필요한 정보는 해당 기간 동안 별도 보관 후 파기합니다.' },
  { heading: '4. 제3자 제공', body: '볏섬은 이용자의 개인정보를 원칙적으로 외부에 제공하지 않습니다. 법령에 근거가 있거나 이용자가 사전에 동의한 경우에만 예외적으로 제공합니다.' },
  { heading: '5. 이용자의 권리', body: '이용자는 언제든지 내 정보 화면에서 저장된 정보를 확인하거나 회원 탈퇴를 통해 삭제를 요청할 수 있습니다.' },
  { heading: '6. 문의처', body: '개인정보 관련 문의는 팀 OPUS (화성시 공공데이터 기반 지역 먹거리 지도 볏섬)로 접수해 주세요.' },
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
            <p style={{ fontSize: 13, color: '#555', lineHeight: 1.7 }}>{s.body}</p>
          </div>
        ))}
        {footnote && <p style={{ fontSize: 12, color: '#bbb', borderTop: '1px solid #f0f0f0', paddingTop: 16, lineHeight: 1.6 }}>{footnote}</p>}
      </div>
    </div>
  )
}
