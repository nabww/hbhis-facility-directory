import * as XLSX from 'xlsx'
import type { Facility } from '@/types'

export function exportToCSV(data: Facility[], filename = 'facilities.csv') {
  const headers = ['MFL Code', 'Facility Name', 'County', 'Subcounty', 'Type', 'Sophos IP', 'Elastic IP', 'Sophos URL', 'Elastic URL', 'Status']
  const rows = data.map(f => [
    f.mfl_code ?? '',
    f.facility_name,
    f.county,
    f.subcounty ?? '',
    f.facility_type ?? '',
    f.sophos_ip ?? '',
    f.elastic_ip ?? '',
    f.sophos_url ?? '',
    f.elastic_url ?? '',
    f.status
  ])
  const csvContent = [headers, ...rows].map(e => e.join(',')).join('\n')
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.setAttribute('download', filename)
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

export function exportToExcel(data: Facility[], filename = 'facilities.xlsx') {
  const ws = XLSX.utils.json_to_sheet(data)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, 'Facilities')
  XLSX.writeFile(wb, filename)
}
