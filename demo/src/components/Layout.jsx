import { Outlet, useNavigate, useLocation } from 'react-router-dom'

const NAV = [
  { path: '/map',           icon: MapIcon,    activeIcon: MapIconFill,  label: '지도',   idx: 0 },
  { path: '/calendar',      icon: CalIcon,    activeIcon: CalIconFill,  label: '캘린더', idx: 1 },
  { path: '/home',          icon: null,       activeIcon: null,         label: '홈',     idx: 2 },
  { path: '/notifications', icon: BellIcon,   activeIcon: BellIconFill, label: '알림',   idx: 3 },
  { path: '/profile',       icon: PersonIcon, activeIcon: PersonIconFill,label: '내정보', idx: 4 },
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
        height: 60,
        display: 'flex',
        alignItems: 'center',
        flexShrink: 0,
      }}>
        {NAV.map(({ path, icon: Icon, activeIcon: ActiveIcon, label, idx }) => {
          const active = pathname === path || (path === '/home' && pathname === '/home')
          if (idx === 2) {
            return (
              <button
                key={idx}
                onClick={() => navigate('/home')}
                style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', border: 'none', background: 'none', cursor: 'pointer', padding: 0 }}
              >
                <div style={{
                  width: 44, height: 44,
                  borderRadius: '50%',
                  background: pathname === '/home' ? '#FF4F00' : '#f0f0f0',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <HomeIcon color={pathname === '/home' ? '#fff' : '#bbb'} />
                </div>
              </button>
            )
          }
          return (
            <button
              key={idx}
              onClick={() => navigate(path)}
              style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 2, border: 'none', background: 'none', cursor: 'pointer', padding: 0 }}
            >
              {active ? <ActiveIcon /> : <Icon />}
              <span style={{ fontSize: 10, fontWeight: active ? 700 : 400, color: active ? '#FF4F00' : '#bbb' }}>{label}</span>
            </button>
          )
        })}
      </nav>
    </div>
  )
}

function MapIcon() { return <svg width="22" height="22" fill="none" viewBox="0 0 24 24"><path stroke="#bbb" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6-3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-1.447-.894L15 9m0 8V9M9 7l6 2"/></svg> }
function MapIconFill() { return <svg width="22" height="22" fill="none" viewBox="0 0 24 24"><path stroke="#FF4F00" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6-3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-1.447-.894L15 9m0 8V9M9 7l6 2"/></svg> }
function CalIcon() { return <svg width="22" height="22" fill="none" viewBox="0 0 24 24"><rect stroke="#bbb" strokeWidth="1.8" x="3" y="4" width="18" height="18" rx="2"/><path stroke="#bbb" strokeWidth="1.8" strokeLinecap="round" d="M16 2v4M8 2v4M3 10h18"/></svg> }
function CalIconFill() { return <svg width="22" height="22" fill="none" viewBox="0 0 24 24"><rect stroke="#FF4F00" strokeWidth="1.8" x="3" y="4" width="18" height="18" rx="2"/><path stroke="#FF4F00" strokeWidth="1.8" strokeLinecap="round" d="M16 2v4M8 2v4M3 10h18"/></svg> }
function HomeIcon({ color = '#bbb' }) { return <svg width="24" height="24" fill={color} viewBox="0 0 24 24"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg> }
function BellIcon() { return <svg width="22" height="22" fill="none" viewBox="0 0 24 24"><path stroke="#bbb" strokeWidth="1.8" strokeLinecap="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6 6 0 00-5-5.917V4a1 1 0 00-2 0v1.083A6 6 0 006 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg> }
function BellIconFill() { return <svg width="22" height="22" fill="none" viewBox="0 0 24 24"><path stroke="#FF4F00" strokeWidth="1.8" strokeLinecap="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6 6 0 00-5-5.917V4a1 1 0 00-2 0v1.083A6 6 0 006 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg> }
function PersonIcon() { return <svg width="22" height="22" fill="none" viewBox="0 0 24 24"><path stroke="#bbb" strokeWidth="1.8" strokeLinecap="round" d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2M12 11a4 4 0 100-8 4 4 0 000 8z"/></svg> }
function PersonIconFill() { return <svg width="22" height="22" fill="none" viewBox="0 0 24 24"><path stroke="#FF4F00" strokeWidth="1.8" strokeLinecap="round" d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2M12 11a4 4 0 100-8 4 4 0 000 8z"/></svg> }
