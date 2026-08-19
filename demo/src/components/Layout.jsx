import { Outlet, useNavigate, useLocation } from 'react-router-dom'
import { Map, CalendarDays, Home, Bell, User } from 'lucide-react'

const NAV = [
  { path: '/map',           Icon: Map,          label: '지도' },
  { path: '/calendar',      Icon: CalendarDays,  label: '캘린더' },
  { path: '/home',          Icon: null,          label: '홈' },
  { path: '/notifications', Icon: Bell,          label: '알림' },
  { path: '/profile',       Icon: User,          label: '내정보' },
]

export default function Layout() {
  const navigate = useNavigate()
  const { pathname } = useLocation()

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', overflow: 'hidden' }}>
      <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
        <Outlet />
      </div>
      <nav style={{
        background: '#fff',
        borderTop: '1px solid #f0f0f0',
        boxShadow: '0 -2px 12px rgba(0,0,0,0.06)',
        height: 62,
        display: 'flex',
        alignItems: 'center',
        flexShrink: 0,
      }}>
        {NAV.map(({ path, Icon, label }) => {
          const active = pathname === path
          if (!Icon) {
            return (
              <button
                key={path}
                onClick={() => navigate('/home')}
                style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', border: 'none', background: 'none', cursor: 'pointer', padding: 0 }}
              >
                <div style={{
                  width: 46, height: 46, borderRadius: '50%',
                  background: pathname === '/home' ? '#FF4F00' : '#f0ede9',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  transition: 'background 0.2s',
                }}>
                  <Home size={22} color={pathname === '/home' ? '#fff' : '#bbb'} fill={pathname === '/home' ? '#fff' : 'none'} />
                </div>
              </button>
            )
          }
          return (
            <button
              key={path}
              onClick={() => navigate(path)}
              style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 3, border: 'none', background: 'none', cursor: 'pointer', padding: 0 }}
            >
              <Icon size={22} color={active ? '#FF4F00' : '#bbb'} strokeWidth={active ? 2.2 : 1.8} />
              <span style={{ fontSize: 10, fontWeight: active ? 700 : 400, color: active ? '#FF4F00' : '#bbb', letterSpacing: -0.3 }}>{label}</span>
            </button>
          )
        })}
      </nav>
    </div>
  )
}
