import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Button } from '@/components/ui/button'
import { RotateCcw } from 'lucide-react'

interface Filters {
  county: string
  subcounty: string
  status: string
}

interface FiltersPanelProps {
  filters: Filters
  counties: string[]
  subcounties: string[]
  onFilterChange: (key: keyof Filters, value: string) => void
  onReset: () => void
}

export function FiltersPanel({ filters, counties, subcounties, onFilterChange, onReset }: FiltersPanelProps) {
  return (
    <div className="flex flex-wrap gap-3 items-end">
      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-medium text-gray-700">County</label>
        <Select value={filters.county} onValueChange={(v) => onFilterChange('county', v)}>
          <SelectTrigger className="w-[160px]">
            <SelectValue placeholder="All counties" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All counties</SelectItem>
            {counties.map((c) => (
              <SelectItem key={c} value={c}>{c}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-medium text-gray-700">Subcounty</label>
        <Select value={filters.subcounty} onValueChange={(v) => onFilterChange('subcounty', v)}>
          <SelectTrigger className="w-[160px]">
            <SelectValue placeholder="All subcounties" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All subcounties</SelectItem>
            {subcounties.map((sc) => (
              <SelectItem key={sc} value={sc}>{sc}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-medium text-gray-700">Status</label>
        <Select value={filters.status} onValueChange={(v) => onFilterChange('status', v)}>
          <SelectTrigger className="w-[130px]">
            <SelectValue placeholder="All statuses" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All statuses</SelectItem>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="inactive">Inactive</SelectItem>
            <SelectItem value="maintenance">Maintenance</SelectItem>
          </SelectContent>
        </Select>
      </div>
      <Button variant="outline" size="sm" onClick={onReset} className="gap-2">
        <RotateCcw className="h-4 w-4" /> Reset
      </Button>
    </div>
  )
}
