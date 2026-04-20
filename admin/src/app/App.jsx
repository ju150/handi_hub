import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from '../hooks/useAuth'
import ProtectedRoute from '../components/ProtectedRoute'
import AppLayout from '../components/AppLayout'

import LoginPage       from '../pages/LoginPage'
import DashboardPage   from '../pages/DashboardPage'
import CareVisitsPage  from '../pages/CareVisitsPage'
import ActivitiesPage  from '../pages/ActivitiesPage'
import NutritionPage   from '../pages/NutritionPage'
import ReeducationPage from '../pages/ReeducationPage'
import BooksPage       from '../pages/BooksPage'

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/" element={<ProtectedRoute><AppLayout /></ProtectedRoute>}>
            <Route index             element={<DashboardPage />} />
            <Route path="care-visits"  element={<CareVisitsPage />} />
            <Route path="activities"   element={<ActivitiesPage />} />
            <Route path="nutrition"    element={<NutritionPage />} />
            <Route path="reeducation"  element={<ReeducationPage />} />
            <Route path="books"        element={<BooksPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}
