import { useNavigate } from 'react-router-dom'
import { useFacilities, useDeleteFacility } from '@/hooks/useFacilities'
import { Button } from '@/components/ui/button'
import { Plus, Pencil, Trash2 } from 'lucide-react'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { useState } from 'react'
import { toast } from 'sonner'

export function FacilitiesList() {
  const { data: facilities } = useFacilities()
  const deleteMutation = useDeleteFacility()
  const navigate = useNavigate()
  const [deleteId, setDeleteId] = useState<string | null>(null)

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteMutation.mutateAsync(deleteId)
      toast.success('Facility deleted')
    } catch (err: any) {
      toast.error(err.message)
    } finally {
      setDeleteId(null)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Manage Facilities</h1>
        <Button onClick={() => navigate('/admin/facilities/new')}>
          <Plus className="mr-2 h-4 w-4" /> Add Facility
        </Button>
      </div>
      <div className="rounded-md border bg-white">
        <table className="w-full text-sm">
          <thead className="border-b">
            <tr>
              <th className="p-3 text-left">Name</th>
              <th className="p-3 text-left">County</th>
              <th className="p-3 text-left">Subcounty</th>
              <th className="p-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {facilities?.map(f => (
              <tr key={f.id} className="border-b hover:bg-gray-50">
                <td className="p-3">{f.facility_name}</td>
                <td className="p-3">{f.county}</td>
                <td className="p-3">{f.subcounty || '—'}</td>
                <td className="p-3 text-right">
                  <Button variant="ghost" size="icon" onClick={() => navigate(`/admin/facilities/${f.id}/edit`)}>
                    <Pencil className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="icon" onClick={() => setDeleteId(f.id)}>
                    <Trash2 className="h-4 w-4 text-red-500" />
                  </Button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <ConfirmDialog
        open={!!deleteId}
        onOpenChange={(o) => !o && setDeleteId(null)}
        title="Delete Facility"
        description="Are you sure you want to delete this facility? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
      />
    </div>
  )
}
