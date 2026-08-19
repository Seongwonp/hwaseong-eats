import { Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout'
import SplashPage from './pages/SplashPage'
import LoginPage from './pages/LoginPage'
import SignupPage from './pages/SignupPage'
import HomePage from './pages/HomePage'
import MapPage from './pages/MapPage'
import CalendarPage from './pages/CalendarPage'
import NotificationsPage from './pages/NotificationsPage'
import ProfilePage from './pages/ProfilePage'
import RestaurantDetailPage from './pages/RestaurantDetailPage'
import MyReviewsPage from './pages/MyReviewsPage'
import SavedRestaurantsPage from './pages/SavedRestaurantsPage'
import RewardPage from './pages/RewardPage'
import VerifyPage from './pages/VerifyPage'
import PrivacyPolicyPage from './pages/PrivacyPolicyPage'
import LocationTermsPage from './pages/LocationTermsPage'
import DataLicensePage from './pages/DataLicensePage'
import ReviewPage from './pages/ReviewPage'

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<SplashPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />
      <Route path="/restaurant/:id" element={<RestaurantDetailPage />} />
      <Route path="/my-reviews" element={<MyReviewsPage />} />
      <Route path="/saved-restaurants" element={<SavedRestaurantsPage />} />
      <Route path="/reward" element={<RewardPage />} />
      <Route path="/verify" element={<VerifyPage />} />
      <Route path="/privacy-policy" element={<PrivacyPolicyPage />} />
      <Route path="/location-terms" element={<LocationTermsPage />} />
      <Route path="/data-license" element={<DataLicensePage />} />
      <Route path="/review/:id" element={<ReviewPage />} />
      <Route element={<Layout />}>
        <Route path="/map" element={<MapPage />} />
        <Route path="/calendar" element={<CalendarPage />} />
        <Route path="/home" element={<HomePage />} />
        <Route path="/notifications" element={<NotificationsPage />} />
        <Route path="/profile" element={<ProfilePage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
