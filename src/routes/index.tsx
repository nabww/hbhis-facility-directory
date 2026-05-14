import { createBrowserRouter } from 'react-router-dom'
import { PublicLayout } from '@/layouts/PublicLayout'
import { AdminLayout } from '@/layouts/AdminLayout'
import { FacilityDirectory } from '@/pages/FacilityDirectory'
import { FacilityDetail } from '@/pages/FacilityDetail'
import { Login } from '@/pages/Login'
import { Dashboard } from '@/pages/admin/Dashboard'
import { FacilitiesList } from '@/pages/admin/FacilitiesList'
import { FacilityForm } from '@/pages/admin/FacilityForm'
import { Import } from '@/pages/admin/Import'
import { Users } from '@/pages/admin/Users'
import { ProtectedRoute } from '@/components/ProtectedRoute'

export const router = createBrowserRouter([
  {
    element: <PublicLayout />,
    children: [
      { path: '/', element: <FacilityDirectory /> },
      { path: '/facility/:id', element: <FacilityDetail /> },
      { path: '/login', element: <Login /> },
    ],
  },
  {
    element: (
      <ProtectedRoute requiredRoles={['admin', 'editor']}>
        <AdminLayout />
      </ProtectedRoute>
    ),
    children: [
      { path: '/admin', element: <Dashboard /> },
      { path: '/admin/facilities', element: <FacilitiesList /> },
      { path: '/admin/facilities/new', element: <FacilityForm /> },
      { path: '/admin/facilities/:id/edit', element: <FacilityForm /> },
      { path: '/admin/import', element: <Import /> },
      { path: '/admin/users', element: <Users /> },
    ],
  },
])
