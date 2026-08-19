import { Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout'
import SplashPage from './pages/SplashPage'
import LoginPage from './pages/LoginPage'
import SignupPage from './pages/SignupPage'
import HomePage from './pages/HomePage'
import MapPage from './pages/MapPage'
import ProfilePage from './pages/ProfilePage'
import RestaurantDetailPage from './pages/RestaurantDetailPage'
import CalendarPage from './pages/CalendarPage'

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<SplashPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />
      <Route path="/restaurant/:id" element={<RestaurantDetailPage />} />
      <Route element={<Layout />}>
        <Route path="/map" element={<MapPage />} />
        <Route path="/calendar" element={<CalendarPage />} />
        <Route path="/home" element={<HomePage />} />
        <Route path="/notifications" element={<PlaceholderPage label="알림" />} />
        <Route path="/profile" element={<ProfilePage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

function PlaceholderPage({ label }) {
  return (
    <div className="flex flex-col items-center justify-center h-full text-gray-400">
      <p className="text-4xl mb-3">🔔</p>
      <p className="font-serif text-lg text-ink font-bold">{label}</p>
      <p className="text-sm mt-1">준비 중이에요</p>
    </div>
  )
}
