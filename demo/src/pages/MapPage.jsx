import { useEffect, useRef, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, Navigation } from 'lucide-react'
import { api } from '../api'

const DEFAULT_LAT = 37.1996
const DEFAULT_LNG = 126.8312
const RADIUS_KM = 2.0
const MAX_DISPLAY = 30

export default function MapPage() {
  const navigate = useNavigate()
  const mapRef = useRef(null)
  const mapInst = useRef(null)
  const markersRef = useRef([])

  const [restaurants, setRestaurants] = useState([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [selected, setSelected] = useState(null)
  const [isKonapay, setIsKonapay] = useState(false)
  const [category, setCategory] = useState(null)
  const [center, setCenter] = useState({ lat: DEFAULT_LAT, lng: DEFAULT_LNG })
  const [showSearchHere, setShowSearchHere] = useState(false)
  const [isLocating, setIsLocating] = useState(false)
  const [sheetExpanded, setSheetExpanded] = useState(false)

  const CATEGORIES = ['음식점', '카페', '편의점', '대형마트']
  const CAT_ICONS = { '음식점': '🍽', '카페': '☕', '편의점': '🏪', '대형마트': '🛒' }

  const fetchRestaurants = useCallback(async (lat, lng, konapay, cat) => {
    setLoading(true)
    try {
      const data = await api.restaurants.list({
        lat, lng,
        radius_km: RADIUS_KM,
        limit: MAX_DISPLAY,
        food_only: false,
        ...(konapay ? { is_konapay: true } : {}),
        ...(cat ? { category: cat } : {}),
      })
      setRestaurants(data.items || [])
      setTotal(data.total || 0)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (!mapRef.current) return

    const initMap = () => {
      window.kakao.maps.load(() => {
      const map = new window.kakao.maps.Map(mapRef.current, {
        center: new window.kakao.maps.LatLng(DEFAULT_LAT, DEFAULT_LNG),
        level: 8,
      })
      mapInst.current = map

      let idleTimer = null
      window.kakao.maps.event.addListener(map, 'idle', () => {
        clearTimeout(idleTimer)
        idleTimer = setTimeout(() => {
          const c = map.getCenter()
          setCenter({ lat: c.getLat(), lng: c.getLng() })
          setShowSearchHere(true)
        }, 300)
      })

      window.kakao.maps.event.addListener(map, 'click', () => {
        setSelected(null)
      })

      fetchRestaurants(DEFAULT_LAT, DEFAULT_LNG, false, null)

      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          pos => {
            const lat = pos.coords.latitude
            const lng = pos.coords.longitude
            map.setCenter(new window.kakao.maps.LatLng(lat, lng))
            setCenter({ lat, lng })
            fetchRestaurants(lat, lng, false, null)
          },
          () => {}
        )
      }
      })
    }

    if (window.kakao?.maps) {
      initMap()
    } else {
      const script = document.createElement('script')
      script.src = `//dapi.kakao.com/v2/maps/sdk.js?appkey=${import.meta.env.VITE_KAKAO_MAP_KEY}&libraries=services,clusterer&autoload=false`
      script.onload = initMap
      document.head.appendChild(script)
    }
  }, [fetchRestaurants])

  useEffect(() => {
    if (!mapInst.current || !window.kakao?.maps) return

    markersRef.current.forEach(m => m.setMap(null))
    markersRef.current = []

    const map = mapInst.current

    restaurants.forEach(r => {
      if (!r.lat || !r.lng) return

      const svgColor = r.is_konapay ? '%234CAF50' : '%234A90D9'
      const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='28' height='38' viewBox='0 0 28 38'><path d='M14 0C6.3 0 0 6.3 0 14c0 10.5 14 24 14 24s14-13.5 14-24C28 6.3 21.7 0 14 0z' fill='${svgColor}' stroke='white' stroke-width='1.5'/><circle cx='14' cy='14' r='6' fill='white'/></svg>`
      const imgUrl = 'data:image/svg+xml,' + svg
      const markerImg = new window.kakao.maps.MarkerImage(
        imgUrl,
        new window.kakao.maps.Size(28, 38),
        { offset: new window.kakao.maps.Point(14, 38) }
      )
      const marker = new window.kakao.maps.Marker({
        position: new window.kakao.maps.LatLng(r.lat, r.lng),
        map,
        image: markerImg,
      })

      window.kakao.maps.event.addListener(marker, 'click', () => {
        setSelected(r)
        setSheetExpanded(false)
        map.setCenter(new window.kakao.maps.LatLng(r.lat, r.lng))
        map.setLevel(3)
      })

      markersRef.current.push(marker)
    })
  }, [restaurants])

  const handleSearchHere = () => {
    fetchRestaurants(center.lat, center.lng, isKonapay, category)
    setShowSearchHere(false)
  }

  const handleMyLocation = () => {
    setIsLocating(true)
    navigator.geolocation.getCurrentPosition(
      pos => {
        const lat = pos.coords.latitude
        const lng = pos.coords.longitude
        mapInst.current?.setCenter(new window.kakao.maps.LatLng(lat, lng))
        setCenter({ lat, lng })
        fetchRestaurants(lat, lng, isKonapay, category)
        setIsLocating(false)
      },
      () => setIsLocating(false)
    )
  }

  const handleKonapayToggle = () => {
    const next = !isKonapay
    setIsKonapay(next)
    fetchRestaurants(center.lat, center.lng, next, category)
    setShowSearchHere(false)
  }

  const handleCategoryToggle = (cat) => {
    const next = category === cat ? null : cat
    setCategory(next)
    fetchRestaurants(center.lat, center.lng, isKonapay, next)
    setShowSearchHere(false)
  }

  const handleSelectRestaurant = (r) => {
    setSelected(r)
    setSheetExpanded(false)
    if (mapInst.current && r.lat && r.lng) {
      mapInst.current.setCenter(new window.kakao.maps.LatLng(r.lat, r.lng))
      mapInst.current.setLevel(3)
    }
  }

  const panelH = sheetExpanded ? '80%' : '38%'

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', overflow: 'hidden' }}>
      {/* 카카오맵 */}
      <div ref={mapRef} style={{ position: 'absolute', inset: 0, zIndex: 1 }} />

      {/* 검색바 + 카테고리 칩 */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, padding: '14px 16px 0', pointerEvents: 'none', zIndex: 10 }}>
        <button
          onClick={() => navigate('/map')}
          style={{
            width: '100%', pointerEvents: 'auto',
            background: '#fff', border: 'none', borderRadius: 50,
            padding: '10px 14px', cursor: 'pointer', textAlign: 'left',
            boxShadow: '0 3px 12px rgba(0,0,0,0.12)',
            display: 'flex', alignItems: 'center', gap: 10,
          }}
        >
          <div style={{ width: 34, height: 34, borderRadius: '50%', background: '#FF4F00', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Search size={16} color="#fff" />
          </div>
          <span style={{ fontSize: 14, color: '#aaa' }}>여기에 검색</span>
        </button>

        {/* 카테고리 칩 */}
        <div style={{ display: 'flex', gap: 8, marginTop: 10, overflowX: 'auto', pointerEvents: 'auto', paddingBottom: 2 }}>
          {CATEGORIES.map(cat => {
            const sel = category === cat
            return (
              <button
                key={cat}
                onClick={() => handleCategoryToggle(cat)}
                style={{
                  flexShrink: 0,
                  background: sel ? '#FF4F00' : '#fff',
                  color: sel ? '#fff' : '#201515',
                  border: 'none', borderRadius: 20,
                  padding: '7px 14px',
                  fontSize: 13, fontWeight: 600, cursor: 'pointer',
                  boxShadow: '0 2px 6px rgba(0,0,0,0.1)',
                  display: 'flex', alignItems: 'center', gap: 5,
                  transition: 'background 0.18s',
                }}
              >
                <span style={{ fontSize: 14 }}>{CAT_ICONS[cat]}</span>
                {cat}
              </button>
            )
          })}
        </div>

        {showSearchHere && (
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 8, pointerEvents: 'auto' }}>
            <button
              onClick={handleSearchHere}
              style={{
                background: '#FF4F00', border: 'none',
                borderRadius: 50, padding: '8px 18px',
                fontSize: 13, fontWeight: 700, color: '#fff',
                boxShadow: '0 2px 8px rgba(255,79,0,0.3)', cursor: 'pointer',
              }}
            >
              🔍 이 지역에서 검색
            </button>
          </div>
        )}
      </div>

      {/* 볏섬 로고 */}
      <div style={{
        position: 'absolute',
        bottom: `calc(${panelH} + 12px)`,
        left: 16, zIndex: 10,
        background: '#FF4F00', borderRadius: 20,
        padding: '5px 12px',
        boxShadow: '0 2px 6px rgba(0,0,0,0.15)',
        transition: 'bottom 0.3s ease',
      }}>
        <span style={{ color: '#fff', fontFamily: '"Noto Serif KR"', fontSize: 13, fontWeight: 700 }}>볏섬</span>
      </div>

      {/* 내 위치 버튼 */}
      <button
        onClick={handleMyLocation}
        style={{
          position: 'absolute',
          bottom: `calc(${panelH} + 12px)`,
          right: 16, zIndex: 10,
          width: 42, height: 42, borderRadius: '50%',
          background: '#fff', border: 'none', cursor: 'pointer',
          boxShadow: '0 2px 8px rgba(0,0,0,0.18)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 18, transition: 'bottom 0.3s ease',
        }}
      >
        {isLocating ? <SpinnerSmall /> : <Navigation size={18} color="#FF4F00" />}
      </button>

      {/* 하단 패널 */}
      <div
        style={{
          position: 'absolute', bottom: 0, left: 0, right: 0,
          height: panelH, zIndex: 10,
          background: '#fff',
          borderRadius: '20px 20px 0 0',
          boxShadow: '0 -4px 16px rgba(0,0,0,0.1)',
          display: 'flex', flexDirection: 'column',
          transition: 'height 0.3s ease',
        }}
      >
        {/* 핸들 */}
        <div
          style={{ display: 'flex', justifyContent: 'center', padding: '12px 0 6px', cursor: 'pointer', flexShrink: 0 }}
          onClick={() => setSheetExpanded(!sheetExpanded)}
        >
          <div style={{ width: 40, height: 4, background: '#ddd', borderRadius: 2 }} />
        </div>

        {selected ? (
          <RestaurantPreview
            restaurant={selected}
            onClose={() => setSelected(null)}
            onDetail={() => navigate(`/restaurant/${selected.id}`, { state: { restaurant: selected } })}
          />
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0 }}>
            {/* 헤더 */}
            <div style={{ padding: '6px 16px 10px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexShrink: 0 }}>
              <div>
                <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 18, fontWeight: 700, color: '#201515' }}>화성시</p>
                {!loading && (
                  <p style={{ fontSize: 11, color: '#999', marginTop: 2 }}>
                    {total > MAX_DISPLAY
                      ? `가까운 음식점 ${MAX_DISPLAY}개를 표시하고 있어요`
                      : restaurants.length === 0 ? '주변 음식점을 찾을 수 없어요'
                      : `${restaurants.length}개 음식점`}
                  </p>
                )}
              </div>
              <button
                onClick={handleKonapayToggle}
                style={{
                  background: isKonapay ? '#FF4F00' : '#f5f5f5',
                  color: isKonapay ? '#fff' : '#666',
                  border: 'none', borderRadius: 50,
                  padding: '6px 12px', fontSize: 12, fontWeight: 700,
                  cursor: 'pointer',
                }}
              >
                💳 화성페이
              </button>
            </div>

            <div style={{ height: 1, background: '#f0f0f0', flexShrink: 0 }} />

            {/* 목록 */}
            <div style={{ flex: 1, overflowY: 'auto' }}>
              {loading ? (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 80 }}>
                  <SpinnerSmall />
                </div>
              ) : restaurants.length === 0 ? (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 80 }}>
                  <p style={{ color: '#999', fontSize: 14 }}>주변에 음식점이 없어요</p>
                </div>
              ) : (
                restaurants.map((r, i) => (
                  <div key={r.id}>
                    {i > 0 && <div style={{ height: 1, background: '#f0f0f0' }} />}
                    <MapRestaurantRow restaurant={r} onTap={() => handleSelectRestaurant(r)} />
                  </div>
                ))
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

function MapRestaurantRow({ restaurant: r, onTap }) {
  const dist = r.distance_km
  const distText = dist != null ? (dist < 1 ? `${Math.round(dist * 1000)}m` : `${dist.toFixed(1)}km`) : null

  return (
    <button onClick={onTap} style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', padding: '12px 16px', display: 'flex', gap: 12, alignItems: 'center', textAlign: 'left' }}>
      <div style={{ width: 48, height: 48, borderRadius: 10, background: 'rgba(255,79,0,0.07)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontSize: 20 }}>🍴</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 14, fontWeight: 700, color: '#201515', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.name}</p>
        <p style={{ fontSize: 11, color: '#999', marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.category ? `${r.category} · ${r.address}` : r.address}</p>
      </div>
      <div style={{ textAlign: 'right', flexShrink: 0 }}>
        {distText && <p style={{ fontSize: 11, color: '#aaa' }}>{distText}</p>}
        {r.avg_rating != null && <p style={{ fontSize: 11, color: '#888' }}>⭐ {r.avg_rating.toFixed(1)}</p>}
      </div>
    </button>
  )
}

function RestaurantPreview({ restaurant: r, onClose, onDetail }) {
  const dist = r.distance_km
  const distText = dist != null ? (dist < 1 ? `${Math.round(dist * 1000)}m` : `${dist.toFixed(1)}km`) : null

  return (
    <button onClick={onDetail} style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', padding: '0 16px 20px', textAlign: 'left' }}>
      <div style={{ display: 'flex', alignItems: 'center', marginBottom: 10 }}>
        <button onClick={e => { e.stopPropagation(); onClose() }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#888', padding: '0 6px 0 0', fontSize: 16 }}>← 목록으로</button>
        <div style={{ flex: 1 }} />
        <span style={{ color: '#ccc', fontSize: 18 }}>›</span>
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', marginBottom: 4 }}>
        <p style={{ fontFamily: '"Noto Serif KR"', fontSize: 17, fontWeight: 700, color: '#201515' }}>{r.name}</p>
        {r.is_konapay && <Badge text="💳 화성페이" color="#4CAF50" />}
        {r.is_mobeom && <Badge text="🏆 모범" color="#2196F3" />}
      </div>
      <p style={{ fontSize: 12, color: '#999', marginBottom: 6 }}>{r.category ? `${r.category} · ${r.address}` : r.address}</p>
      <div style={{ display: 'flex', gap: 10 }}>
        {r.avg_rating != null && <span style={{ fontSize: 12, color: '#999' }}>⭐ {r.avg_rating.toFixed(1)} ({r.review_count})</span>}
        {distText && <span style={{ fontSize: 12, color: '#bbb' }}>📍 {distText}</span>}
      </div>
    </button>
  )
}

function Badge({ text, color }) {
  return (
    <span style={{ fontSize: 10, fontWeight: 700, color, background: `${color}1a`, borderRadius: 6, padding: '2px 7px' }}>{text}</span>
  )
}

function SpinnerSmall() {
  return (
    <div style={{
      width: 22, height: 22,
      border: '2.5px solid #f0f0f0',
      borderTop: '2.5px solid #FF4F00',
      borderRadius: '50%',
      animation: 'spin 0.8s linear infinite',
    }} />
  )
}
