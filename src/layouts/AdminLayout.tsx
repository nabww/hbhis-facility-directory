import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { Navbar } from '@/components/Navbar'
import { LayoutDashboard, Building2, Upload, Users, ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'

const navItems = [
  { to: '/admin', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/admin/facilities', label: 'Facilities', icon: Building2 },
  { to: '/admin/import', label: 'Import', icon: Upload },
  { to: '/admin/users', label: 'Users', icon: Users },
]

export function AdminLayout() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Navbar />
      <div className="flex flex-1">
        <aside className="hidden md:flex w-64 flex-col border-r bg-white pt-6">
          <nav className="flex-1 space-y-1 px-3">
            {navItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.end}
                className={({ isActive }) =>
                  `flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors ${
                    isActive ? 'bg-brand-50 text-brand-700' : 'text-gray-700 hover:bg-gray-100'
                  }`
                }
              >
                <item.icon className="h-4 w-4" />
                {item.label}
              </NavLink>
            ))}
          </nav>
          <div className="p-4 border-t">
            <Button variant="ghost" className="w-full justify-start" onClick={() => navigate('/')}>
              <ArrowLeft className="mr-2 h-4 w-4" /> Back to Directory
            </Button>
          </div>
        </aside>
        <main className="flex-1 overflow-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
