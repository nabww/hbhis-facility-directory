import { Badge } from '@/components/ui/badge'

const statusColors: Record<string, 'default' | 'secondary' | 'destructive'> = {
  active: 'default',
  inactive: 'secondary',
  maintenance: 'destructive',
}

export function StatusBadge({ status }: { status: string }) {
  const variant = statusColors[status] || 'secondary'
  return <Badge variant={variant}>{status}</Badge>
}
