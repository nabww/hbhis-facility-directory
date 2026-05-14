import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { facilitiesService } from '@/services/facilities'
import type { FacilityFormValues } from '@/types'

export function useFacilities() {
  return useQuery({
    queryKey: ['facilities'],
    queryFn: facilitiesService.getAll,
  })
}

export function useFacility(id: string) {
  return useQuery({
    queryKey: ['facility', id],
    queryFn: () => facilitiesService.getById(id),
    enabled: !!id,
  })
}

export function useCreateFacility() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (values: FacilityFormValues) => facilitiesService.create(values),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['facilities'] }),
  })
}

export function useUpdateFacility() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...values }: Partial<FacilityFormValues> & { id: string }) =>
      facilitiesService.update(id, values),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['facilities'] }),
  })
}

export function useDeleteFacility() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => facilitiesService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['facilities'] }),
  })
}
