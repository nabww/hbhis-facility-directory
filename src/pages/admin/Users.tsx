import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { toast } from 'sonner'
import type { Profile } from '@/types'

export function Users() {
  const [profiles, setProfiles] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchProfiles()
  }, [])

  async function fetchProfiles() {
    setLoading(true)
    const { data, error } = await supabase.from('profiles').select('*')
    if (error) toast.error('Failed to load users')
    else setProfiles(data)
    setLoading(false)
  }

  const updateRole = async (userId: string, role: 'viewer' | 'editor' | 'admin') => {
    const { error } = await supabase.from('profiles').update({ role }).eq('id', userId)
    if (error) toast.error('Update failed')
    else {
      toast.success('Role updated')
      fetchProfiles()
    }
  }

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">User Management</h1>
      <Card>
        <CardHeader><CardTitle>Registered Users</CardTitle></CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="border-b">
                <tr>
                  <th className="text-left p-2">User ID</th>
                  <th className="text-left p-2">Full Name</th>
                  <th className="text-left p-2">Role</th>
                  <th className="text-left p-2">Actions</th>
                </tr>
              </thead>
              <tbody>
                {profiles.map((profile) => (
                  <tr key={profile.id} className="border-b">
                    <td className="p-2 font-mono text-xs">{profile.id}</td>
                    <td className="p-2">{profile.full_name || '—'}</td>
                    <td className="p-2">{profile.role}</td>
                    <td className="p-2">
                      <select
                        value={profile.role}
                        onChange={(e) => updateRole(profile.id, e.target.value as any)}
                        className="border rounded px-2 py-1 text-xs"
                      >
                        <option value="viewer">Viewer</option>
                        <option value="editor">Editor</option>
                        <option value="admin">Admin</option>
                      </select>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
