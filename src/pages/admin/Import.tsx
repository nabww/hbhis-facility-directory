import { useState } from 'react'
import { ExcelUploader } from '@/components/ExcelUploader'
import { facilitiesService } from '@/services/facilities'
import { Button } from '@/components/ui/button'
import { toast } from 'sonner'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export function Import() {
  const [data, setData] = useState<any[] | null>(null)
  const [loading, setLoading] = useState(false)

  const handleImport = async () => {
    if (!data || data.length === 0) return
    setLoading(true)
    try {
      const mapped = data.map(row => ({
        mfl_code: row['MFL Code'] || '',
        facility_name: row['Facility Name'] || '',
        county: row['County'] || '',
        subcounty: row['Subcounty'] || '',
        facility_type: row['Facility Type'] || '',
        sophos_ip: row['Sophos IP'] || null,
        elastic_ip: row['Elastic IP'] || null,
        sophos_url: row['Sophos URL'] || null,
        elastic_url: row['Elastic URL'] || null,
        status: 'active',
      }))
      await facilitiesService.bulkImport(mapped)
      toast.success(`Imported ${mapped.length} facilities`)
      setData(null)
    } catch (err: any) {
      toast.error(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6 max-w-2xl">
      <h1 className="text-3xl font-bold">Import Facilities</h1>
      <Card>
        <CardHeader><CardTitle>Upload Excel File</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <ExcelUploader onUpload={setData} />
          {data && (
            <div>
              <p className="text-sm text-gray-600">{data.length} rows detected.</p>
              <Button onClick={handleImport} disabled={loading} className="mt-2">
                {loading ? 'Importing...' : 'Start Import'}
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
