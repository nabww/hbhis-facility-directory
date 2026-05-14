import { useFacilities } from '@/hooks/useFacilities'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Building2, MapPin, Activity } from 'lucide-react'

export function Dashboard() {
  const { data: facilities, isLoading } = useFacilities()

  const total = facilities?.length || 0
  const counties = facilities ? [...new Set(facilities.map(f => f.county))].length : 0
  const recent = facilities ? [...facilities].sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()).slice(0, 5) : []

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Admin Dashboard</h1>
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Facilities</CardTitle>
            <Building2 className="h-4 w-4 text-gray-500" />
          </CardHeader>
          <CardContent><div className="text-2xl font-bold">{total}</div></CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Counties Covered</CardTitle>
            <MapPin className="h-4 w-4 text-gray-500" />
          </CardHeader>
          <CardContent><div className="text-2xl font-bold">{counties}</div></CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">System Status</CardTitle>
            <Activity className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent><div className="text-2xl font-bold text-green-600">Operational</div></CardContent>
        </Card>
      </div>
      <Card>
        <CardHeader><CardTitle>Recently Updated</CardTitle></CardHeader>
        <CardContent>
          {recent.length === 0 ? <p className="text-sm text-gray-500">No facilities yet.</p> : (
            <ul className="space-y-2">
              {recent.map(f => (
                <li key={f.id} className="text-sm border-b pb-2 flex justify-between">
                  <span>{f.facility_name} ({f.county})</span>
                  <span className="text-gray-500">{new Date(f.updated_at).toLocaleDateString()}</span>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
