import { supabase } from '@/lib/supabase'
import type { Facility, FacilityFormValues, AuditLog } from '@/types'

export const facilitiesService = {
  async getAll(): Promise<Facility[]> {
    const { data, error } = await supabase
      .from('facilities')
      .select('*')
      .order('facility_name', { ascending: true })
    if (error) throw error
    return data
  },

  async getById(id: string): Promise<Facility> {
    const { data, error } = await supabase
      .from('facilities')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async create(values: FacilityFormValues): Promise<Facility> {
    const { data, error } = await supabase
      .from('facilities')
      .insert(values)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async update(id: string, values: Partial<FacilityFormValues>): Promise<Facility> {
    const { data, error } = await supabase
      .from('facilities')
      .update(values)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from('facilities').delete().eq('id', id)
    if (error) throw error
  },

  async bulkImport(facilities: FacilityFormValues[]): Promise<void> {
    const { error } = await supabase.from('facilities').insert(facilities)
    if (error) throw error
  },

  async getAuditLogs(facilityId: string): Promise<AuditLog[]> {
    const { data, error } = await supabase
      .from('audit_logs')
      .select('*')
      .eq('facility_id', facilityId)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  }
}
