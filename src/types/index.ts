export interface Facility {
  id: string
  mfl_code: string | null
  facility_name: string
  county: string
  subcounty: string | null
  facility_type: string | null
  sophos_ip: string | null
  elastic_ip: string | null
  sophos_url: string | null
  elastic_url: string | null
  status: string
  notes: string | null
  created_at: string
  updated_at: string
}

export interface Profile {
  id: string
  full_name: string | null
  role: 'viewer' | 'editor' | 'admin'
}

export interface AuditLog {
  id: string
  facility_id: string | null
  user_id: string | null
  action: string
  changes: Record<string, any> | null
  created_at: string
}

export type FacilityFormValues = Omit<Facility, 'id' | 'created_at' | 'updated_at'>
