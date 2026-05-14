#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Fix script for HBHIS Facility Directory – replaces boilerplate with app code
# ------------------------------------------------------------------------------

echo "🔄 Removing old src folder..."
rm -rf src

echo "📁 Creating new directory structure..."
mkdir -p src/{components/ui,layouts,pages/admin,hooks,services,contexts,types,utils,lib,routes}

# ---------- Configuration updates ----------
echo "⚙️  Updating vite.config.ts..."
cat > vite.config.ts << 'VITE'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
VITE

echo "⚙️  Updating tsconfig.json..."
cat > tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
TSCONFIG

echo "⚙️  Replacing src/index.css..."
cat > src/index.css << 'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;
CSS

# ---------- Core lib/utils/supabase/types ----------
echo "🔧 Writing core modules..."

cat > src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF

cat > src/lib/supabase.ts << 'EOF'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
EOF

cat > src/types/index.ts << 'EOF'
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
EOF

cat > src/services/facilities.ts << 'EOF'
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
EOF

# ---------- Hooks ----------
echo "🪝  Creating hooks..."

cat > src/hooks/useDebounce.ts << 'EOF'
import { useState, useEffect } from 'react'

export function useDebounce<T>(value: T, delay: number = 300): T {
  const [debouncedValue, setDebouncedValue] = useState(value)

  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay)
    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}
EOF

cat > src/hooks/useFacilities.ts << 'EOF'
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
EOF

cat > src/contexts/AuthContext.tsx << 'EOF'
import { createContext, useEffect, useState, type ReactNode } from 'react'
import { supabase } from '@/lib/supabase'
import type { User, Session } from '@supabase/supabase-js'
import type { Profile } from '@/types'

interface AuthContextType {
  user: User | null
  profile: Profile | null
  session: Session | null
  isLoading: boolean
  signOut: () => Promise<void>
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [session, setSession] = useState<Session | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setUser(session?.user ?? null)
      if (session?.user) fetchProfile(session.user.id)
      setIsLoading(false)
    })

    const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
      setUser(session?.user ?? null)
      if (session?.user) {
        fetchProfile(session.user.id)
      } else {
        setProfile(null)
      }
    })

    return () => authListener.subscription.unsubscribe()
  }, [])

  async function fetchProfile(userId: string) {
    const { data } = await supabase.from('profiles').select('*').eq('id', userId).single()
    setProfile(data ?? null)
  }

  const signOut = async () => {
    await supabase.auth.signOut()
    setUser(null)
    setProfile(null)
    setSession(null)
  }

  return (
    <AuthContext.Provider value={{ user, profile, session, isLoading, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}
EOF

cat > src/hooks/useAuth.ts << 'EOF'
import { useContext } from 'react'
import { AuthContext } from '@/contexts/AuthContext'

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
EOF

# ---------- Utils ----------
echo "🛠  Creating utils..."

cat > src/utils/validation.ts << 'EOF'
import { z } from 'zod'

export const facilitySchema = z.object({
  mfl_code: z.string().optional(),
  facility_name: z.string().min(1, 'Facility name is required'),
  county: z.string().min(1, 'County is required'),
  subcounty: z.string().optional(),
  facility_type: z.string().optional(),
  sophos_ip: z.string().ip({ version: 'v4', message: 'Invalid IPv4 address' }).optional().or(z.literal('')),
  elastic_ip: z.string().ip({ version: 'v4', message: 'Invalid IPv4 address' }).optional().or(z.literal('')),
  sophos_url: z.string().url().optional().or(z.literal('')),
  elastic_url: z.string().url().optional().or(z.literal('')),
  status: z.string().optional(),
  notes: z.string().optional(),
})

export type FacilityFormData = z.infer<typeof facilitySchema>
EOF

cat > src/utils/export.ts << 'EOF'
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
EOF

# ---------- UI Components ----------
echo "🧩 Building UI components..."

cat > src/components/ui/button.tsx << 'EOF'
import * as React from 'react'
import { Slot } from '@radix-ui/react-slot'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-brand-600 text-white hover:bg-brand-700',
        destructive: 'bg-red-600 text-white hover:bg-red-700',
        outline: 'border border-gray-200 bg-white hover:bg-gray-100',
        secondary: 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        ghost: 'hover:bg-gray-100',
        link: 'text-brand-600 underline-offset-4 hover:underline',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = 'Button'
export { Button, buttonVariants }
EOF

cat > src/components/ui/input.tsx << 'EOF'
import * as React from 'react'
import { cn } from '@/lib/utils'

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          'flex h-10 w-full rounded-md border border-gray-200 bg-white px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-gray-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = 'Input'
export { Input }
EOF

cat > src/components/ui/label.tsx << 'EOF'
import * as React from 'react'
import * as LabelPrimitive from '@radix-ui/react-label'
import { cn } from '@/lib/utils'

const Label = React.forwardRef<
  React.ElementRef<typeof LabelPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof LabelPrimitive.Root>
>(({ className, ...props }, ref) => (
  <LabelPrimitive.Root
    ref={ref}
    className={cn(
      'text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70',
      className
    )}
    {...props}
  />
))
Label.displayName = LabelPrimitive.Root.displayName
export { Label }
EOF

cat > src/components/ui/dialog.tsx << 'EOF'
import * as React from 'react'
import * as DialogPrimitive from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils'

const Dialog = DialogPrimitive.Root
const DialogTrigger = DialogPrimitive.Trigger
const DialogPortal = DialogPrimitive.Portal
const DialogClose = DialogPrimitive.Close

const DialogOverlay = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Overlay>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Overlay>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Overlay
    ref={ref}
    className={cn(
      'fixed inset-0 z-50 bg-black/80 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0',
      className
    )}
    {...props}
  />
))
DialogOverlay.displayName = DialogPrimitive.Overlay.displayName

const DialogContent = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Content>
>(({ className, children, ...props }, ref) => (
  <DialogPortal>
    <DialogOverlay />
    <DialogPrimitive.Content
      ref={ref}
      className={cn(
        'fixed left-[50%] top-[50%] z-50 grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4 border bg-white p-6 shadow-lg duration-200 sm:rounded-lg',
        className
      )}
      {...props}
    >
      {children}
      <DialogPrimitive.Close className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2">
        <X className="h-4 w-4" />
        <span className="sr-only">Close</span>
      </DialogPrimitive.Close>
    </DialogPrimitive.Content>
  </DialogPortal>
))
DialogContent.displayName = DialogPrimitive.Content.displayName

const DialogHeader = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn('flex flex-col space-y-1.5 text-center sm:text-left', className)} {...props} />
)
const DialogFooter = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn('flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2', className)} {...props} />
)
const DialogTitle = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Title>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Title>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Title ref={ref} className={cn('text-lg font-semibold', className)} {...props} />
))
const DialogDescription = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Description>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Description>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Description ref={ref} className={cn('text-sm text-gray-500', className)} {...props} />
))

export {
  Dialog,
  DialogPortal,
  DialogOverlay,
  DialogClose,
  DialogTrigger,
  DialogContent,
  DialogHeader,
  DialogFooter,
  DialogTitle,
  DialogDescription,
}
EOF

cat > src/components/ui/select.tsx << 'EOF'
import * as React from 'react'
import * as SelectPrimitive from '@radix-ui/react-select'
import { Check, ChevronDown } from 'lucide-react'
import { cn } from '@/lib/utils'

const Select = SelectPrimitive.Root
const SelectGroup = SelectPrimitive.Group
const SelectValue = SelectPrimitive.Value

const SelectTrigger = React.forwardRef<
  React.ElementRef<typeof SelectPrimitive.Trigger>,
  React.ComponentPropsWithoutRef<typeof SelectPrimitive.Trigger>
>(({ className, children, ...props }, ref) => (
  <SelectPrimitive.Trigger
    ref={ref}
    className={cn(
      'flex h-10 w-full items-center justify-between rounded-md border border-gray-200 bg-white px-3 py-2 text-sm ring-offset-background placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
      className
    )}
    {...props}
  >
    {children}
    <SelectPrimitive.Icon asChild>
      <ChevronDown className="h-4 w-4 opacity-50" />
    </SelectPrimitive.Icon>
  </SelectPrimitive.Trigger>
))
SelectTrigger.displayName = SelectPrimitive.Trigger.displayName

const SelectContent = React.forwardRef<
  React.ElementRef<typeof SelectPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof SelectPrimitive.Content>
>(({ className, children, position = 'popper', ...props }, ref) => (
  <SelectPrimitive.Portal>
    <SelectPrimitive.Content
      ref={ref}
      className={cn(
        'relative z-50 min-w-[8rem] overflow-hidden rounded-md border bg-white text-popover-foreground shadow-md data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95',
        position === 'popper' && 'data-[side=bottom]:translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1 data-[side=top]:-translate-y-1',
        className
      )}
      position={position}
      {...props}
    >
      <SelectPrimitive.Viewport
        className={cn('p-1', position === 'popper' && 'h-[var(--radix-select-trigger-height)] w-full min-w-[var(--radix-select-trigger-width)]')}
      >
        {children}
      </SelectPrimitive.Viewport>
    </SelectPrimitive.Content>
  </SelectPrimitive.Portal>
))
SelectContent.displayName = SelectPrimitive.Content.displayName

const SelectItem = React.forwardRef<
  React.ElementRef<typeof SelectPrimitive.Item>,
  React.ComponentPropsWithoutRef<typeof SelectPrimitive.Item>
>(({ className, children, ...props }, ref) => (
  <SelectPrimitive.Item
    ref={ref}
    className={cn(
      'relative flex w-full cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none focus:bg-gray-100 focus:text-gray-900 data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
      className
    )}
    {...props}
  >
    <span className="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
      <SelectPrimitive.ItemIndicator>
        <Check className="h-4 w-4" />
      </SelectPrimitive.ItemIndicator>
    </span>
    <SelectPrimitive.ItemText>{children}</SelectPrimitive.ItemText>
  </SelectPrimitive.Item>
))
SelectItem.displayName = SelectPrimitive.Item.displayName

export { Select, SelectGroup, SelectValue, SelectTrigger, SelectContent, SelectItem }
EOF

cat > src/components/ui/badge.tsx << 'EOF'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const badgeVariants = cva(
  'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors',
  {
    variants: {
      variant: {
        default: 'border-transparent bg-brand-100 text-brand-800',
        secondary: 'border-transparent bg-gray-100 text-gray-800',
        destructive: 'border-transparent bg-red-100 text-red-800',
        outline: 'text-gray-800',
      },
    },
    defaultVariants: {
      variant: 'default',
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />
}

export { Badge, badgeVariants }
EOF

cat > src/components/ui/card.tsx << 'EOF'
import { cn } from '@/lib/utils'

const Card = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn('rounded-lg border bg-white text-gray-950 shadow-sm', className)} {...props} />
)
const CardHeader = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn('flex flex-col space-y-1.5 p-6', className)} {...props} />
)
const CardTitle = ({ className, ...props }: React.HTMLAttributes<HTMLHeadingElement>) => (
  <h3 className={cn('text-2xl font-semibold leading-none tracking-tight', className)} {...props} />
)
const CardDescription = ({ className, ...props }: React.HTMLAttributes<HTMLParagraphElement>) => (
  <p className={cn('text-sm text-gray-500', className)} {...props} />
)
const CardContent = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn('p-6 pt-0', className)} {...props} />
)
const CardFooter = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn('flex items-center p-6 pt-0', className)} {...props} />
)

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent }
EOF

cat > src/components/ui/table.tsx << 'EOF'
import { cn } from '@/lib/utils'

const Table = ({ className, ...props }: React.HTMLAttributes<HTMLTableElement>) => (
  <div className="relative w-full overflow-auto">
    <table className={cn('w-full caption-bottom text-sm', className)} {...props} />
  </div>
)
const TableHeader = ({ className, ...props }: React.HTMLAttributes<HTMLTableSectionElement>) => (
  <thead className={cn('[&_tr]:border-b', className)} {...props} />
)
const TableBody = ({ className, ...props }: React.HTMLAttributes<HTMLTableSectionElement>) => (
  <tbody className={cn('[&_tr:last-child]:border-0', className)} {...props} />
)
const TableRow = ({ className, ...props }: React.HTMLAttributes<HTMLTableRowElement>) => (
  <tr className={cn('border-b transition-colors hover:bg-gray-50 data-[state=selected]:bg-gray-100', className)} {...props} />
)
const TableHead = ({ className, ...props }: React.ThHTMLAttributes<HTMLTableCellElement>) => (
  <th className={cn('h-12 px-4 text-left align-middle font-medium text-gray-500 [&:has([role=checkbox])]:pr-0', className)} {...props} />
)
const TableCell = ({ className, ...props }: React.TdHTMLAttributes<HTMLTableCellElement>) => (
  <td className={cn('p-4 align-middle [&:has([role=checkbox])]:pr-0', className)} {...props} />
)

export { Table, TableHeader, TableBody, TableRow, TableHead, TableCell }
EOF

# ---------- Reusable Components ----------
cat > src/components/StatusBadge.tsx << 'EOF'
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
EOF

cat > src/components/CopyButton.tsx << 'EOF'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Copy, Check } from 'lucide-react'

export function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <Button variant="ghost" size="icon" onClick={handleCopy} title="Copy">
      {copied ? <Check className="h-4 w-4 text-green-600" /> : <Copy className="h-4 w-4" />}
    </Button>
  )
}
EOF

cat > src/components/EmptyState.tsx << 'EOF'
import { FileQuestion } from 'lucide-react'

interface EmptyStateProps {
  title?: string
  description?: string
  icon?: React.ReactNode
}

export function EmptyState({ title = 'No data', description = 'There are no records to display.', icon }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <div className="rounded-full bg-gray-100 p-3 mb-4">
        {icon || <FileQuestion className="h-6 w-6 text-gray-400" />}
      </div>
      <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
      <p className="text-sm text-gray-500 mt-1">{description}</p>
    </div>
  )
}
EOF

cat > src/components/LoadingSpinner.tsx << 'EOF'
import { Loader2 } from 'lucide-react'

export function LoadingSpinner() {
  return (
    <div className="flex items-center justify-center py-12">
      <Loader2 className="h-8 w-8 animate-spin text-brand-600" />
    </div>
  )
}
EOF

cat > src/components/ConfirmDialog.tsx << 'EOF'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'

interface ConfirmDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description: string
  onConfirm: () => void
  confirmLabel?: string
  variant?: 'default' | 'destructive'
}

export function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  onConfirm,
  confirmLabel = 'Confirm',
  variant = 'default',
}: ConfirmDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>{description}</DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button variant={variant === 'destructive' ? 'destructive' : 'default'} onClick={onConfirm}>
            {confirmLabel}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
EOF

cat > src/components/SearchBar.tsx << 'EOF'
import { Input } from '@/components/ui/input'
import { Search } from 'lucide-react'

interface SearchBarProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
}

export function SearchBar({ value, onChange, placeholder = 'Search facilities...' }: SearchBarProps) {
  return (
    <div className="relative w-full max-w-sm">
      <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
      <Input
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="pl-9"
      />
    </div>
  )
}
EOF

cat > src/components/FiltersPanel.tsx << 'EOF'
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
EOF

cat > src/components/FacilityTable.tsx << 'EOF'
import { useMemo, useState } from 'react'
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  flexRender,
  type SortingState,
} from '@tanstack/react-table'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { StatusBadge } from '@/components/StatusBadge'
import { CopyButton } from '@/components/CopyButton'
import { ExternalLink, Eye } from 'lucide-react'
import { Link } from 'react-router-dom'
import type { Facility } from '@/types'

interface FacilityTableProps {
  data: Facility[]
}

export function FacilityTable({ data }: FacilityTableProps) {
  const [sorting, setSorting] = useState<SortingState>([])

  const columns = useMemo(() => [
    { accessorKey: 'facility_name', header: 'Facility Name', cell: (info: any) => info.getValue() },
    { accessorKey: 'county', header: 'County' },
    { accessorKey: 'subcounty', header: 'Subcounty' },
    { accessorKey: 'facility_type', header: 'Type' },
    {
      accessorKey: 'sophos_ip',
      header: 'Sophos IP',
      cell: ({ row }: any) => (
        <div className="flex items-center gap-1">
          {row.original.sophos_ip || '—'}
          {row.original.sophos_ip && <CopyButton text={row.original.sophos_ip} />}
        </div>
      ),
    },
    {
      accessorKey: 'elastic_ip',
      header: 'Elastic IP',
      cell: ({ row }: any) => (
        <div className="flex items-center gap-1">
          {row.original.elastic_ip || '—'}
          {row.original.elastic_ip && <CopyButton text={row.original.elastic_ip} />}
        </div>
      ),
    },
    {
      accessorKey: 'status',
      header: 'Status',
      cell: ({ row }: any) => <StatusBadge status={row.original.status} />,
    },
    {
      id: 'actions',
      header: '',
      cell: ({ row }: any) => (
        <div className="flex items-center gap-1">
          {row.original.sophos_url && (
            <a href={row.original.sophos_url} target="_blank" rel="noreferrer" title="Open Sophos">
              <Button variant="ghost" size="icon"><ExternalLink className="h-4 w-4" /></Button>
            </a>
          )}
          {row.original.elastic_url && (
            <a href={row.original.elastic_url} target="_blank" rel="noreferrer" title="Open Elastic">
              <Button variant="ghost" size="icon"><ExternalLink className="h-4 w-4" /></Button>
            </a>
          )}
          <Link to={`/facility/${row.original.id}`}>
            <Button variant="ghost" size="icon"><Eye className="h-4 w-4" /></Button>
          </Link>
        </div>
      ),
    },
  ], [])

  const table = useReactTable({
    data,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
  })

  return (
    <div>
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map(headerGroup => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map(header => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(header.column.columnDef.header, header.getContext())}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map(row => (
                <TableRow key={row.id}>
                  {row.getVisibleCells().map(cell => (
                    <TableCell key={cell.id}>
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={columns.length} className="text-center py-8 text-gray-500">
                  No facilities found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      <div className="flex items-center justify-end space-x-2 py-4">
        <Button
          variant="outline"
          size="sm"
          onClick={() => table.previousPage()}
          disabled={!table.getCanPreviousPage()}
        >
          Previous
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => table.nextPage()}
          disabled={!table.getCanNextPage()}
        >
          Next
        </Button>
      </div>
    </div>
  )
}
EOF

cat > src/components/ExcelUploader.tsx << 'EOF'
import { useState, useCallback } from 'react'
import { Upload, FileSpreadsheet } from 'lucide-react'
import * as XLSX from 'xlsx'
import { Button } from '@/components/ui/button'

interface ExcelUploaderProps {
  onUpload: (data: any[]) => void
}

export function ExcelUploader({ onUpload }: ExcelUploaderProps) {
  const [fileName, setFileName] = useState<string | null>(null)

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    const file = e.dataTransfer.files[0]
    processFile(file)
  }, [onUpload])

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) processFile(file)
  }

  const processFile = (file: File) => {
    setFileName(file.name)
    const reader = new FileReader()
    reader.onload = (ev) => {
      const bstr = ev.target?.result
      const wb = XLSX.read(bstr, { type: 'binary' })
      const wsname = wb.SheetNames[0]
      const ws = wb.Sheets[wsname]
      const data = XLSX.utils.sheet_to_json(ws, { header: 1 })
      const headers = data[0] as string[]
      const rows = data.slice(1).map((row: any) => {
        const obj: Record<string, any> = {}
        headers.forEach((h, i) => { obj[h.trim()] = row[i] ?? '' })
        return obj
      })
      onUpload(rows)
    }
    reader.readAsBinaryString(file)
  }

  return (
    <div
      onDragOver={(e) => e.preventDefault()}
      onDrop={handleDrop}
      className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 p-8 text-center hover:border-brand-500 transition-colors"
    >
      {fileName ? (
        <div className="flex items-center gap-2">
          <FileSpreadsheet className="h-6 w-6 text-brand-600" />
          <span className="text-sm font-medium">{fileName}</span>
          <Button variant="ghost" size="sm" onClick={() => setFileName(null)}>Remove</Button>
        </div>
      ) : (
        <>
          <Upload className="h-8 w-8 text-gray-400 mb-2" />
          <p className="text-sm text-gray-600">Drag & drop an Excel file here, or</p>
          <label className="cursor-pointer text-sm text-brand-600 hover:underline mt-1">
            browse files
            <input type="file" accept=".xlsx,.xls" onChange={handleFileInput} className="hidden" />
          </label>
        </>
      )}
    </div>
  )
}
EOF

cat > src/components/Navbar.tsx << 'EOF'
import { Link, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/hooks/useAuth'
import { LogIn, LogOut, Shield, Building2 } from 'lucide-react'

export function Navbar() {
  const { user, profile, signOut } = useAuth()
  const navigate = useNavigate()

  return (
    <nav className="sticky top-0 z-40 w-full border-b bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/60">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-2">
          <Building2 className="h-6 w-6 text-brand-600" />
          <Link to="/" className="text-xl font-bold text-gray-900">
            HBHIS <span className="text-brand-600">Directory</span>
          </Link>
        </div>
        <div className="flex items-center gap-3">
          {user && profile?.role !== 'viewer' ? (
            <>
              <Button variant="ghost" size="sm" onClick={() => navigate('/admin')}>
                <Shield className="mr-2 h-4 w-4" /> Admin
              </Button>
              <Button variant="outline" size="sm" onClick={signOut}>
                <LogOut className="mr-2 h-4 w-4" /> Sign Out
              </Button>
            </>
          ) : (
            <Button variant="outline" size="sm" onClick={() => navigate('/login')}>
              <LogIn className="mr-2 h-4 w-4" /> Admin Login
            </Button>
          )}
        </div>
      </div>
    </nav>
  )
}
EOF

# ---------- Layouts ----------
cat > src/layouts/PublicLayout.tsx << 'EOF'
import { Outlet } from 'react-router-dom'
import { Navbar } from '@/components/Navbar'

export function PublicLayout() {
  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Navbar />
      <main className="flex-1 mx-auto max-w-7xl w-full px-4 sm:px-6 lg:px-8 py-8">
        <Outlet />
      </main>
    </div>
  )
}
EOF

cat > src/layouts/AdminLayout.tsx << 'EOF'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { Navbar } from '@/components/Navbar'
import { LayoutDashboard, Building2, Upload, Users, ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'

const navItems = [
  { to: '/admin', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/admin/facilities', label: 'Facilities', icon: Building2 },
  { to: '/admin/import', label: 'Import', icon: Upload },
  { to: '/admin/users', label: 'Users', icon: Users },
]

export function AdminLayout() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Navbar />
      <div className="flex flex-1">
        <aside className="hidden md:flex w-64 flex-col border-r bg-white pt-6">
          <nav className="flex-1 space-y-1 px-3">
            {navItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.end}
                className={({ isActive }) =>
                  `flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors ${
                    isActive ? 'bg-brand-50 text-brand-700' : 'text-gray-700 hover:bg-gray-100'
                  }`
                }
              >
                <item.icon className="h-4 w-4" />
                {item.label}
              </NavLink>
            ))}
          </nav>
          <div className="p-4 border-t">
            <Button variant="ghost" className="w-full justify-start" onClick={() => navigate('/')}>
              <ArrowLeft className="mr-2 h-4 w-4" /> Back to Directory
            </Button>
          </div>
        </aside>
        <main className="flex-1 overflow-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
EOF

# ---------- Pages ----------
cat > src/pages/Login.tsx << 'EOF'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { toast } from 'sonner'

export function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    setLoading(false)
    if (error) {
      toast.error(error.message)
    } else {
      toast.success('Logged in')
      navigate('/admin')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold">Admin Login</CardTitle>
          <CardDescription>Sign in to manage the facility directory</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
            </div>
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? 'Signing in...' : 'Sign In'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
EOF

cat > src/pages/FacilityDirectory.tsx << 'EOF'
import { useState, useMemo } from 'react'
import { useFacilities } from '@/hooks/useFacilities'
import { useDebounce } from '@/hooks/useDebounce'
import { FacilityTable } from '@/components/FacilityTable'
import { SearchBar } from '@/components/SearchBar'
import { FiltersPanel } from '@/components/FiltersPanel'
import { LoadingSpinner } from '@/components/LoadingSpinner'
import { EmptyState } from '@/components/EmptyState'
import { exportToCSV, exportToExcel } from '@/utils/export'
import { Button } from '@/components/ui/button'
import { Download } from 'lucide-react'

export function FacilityDirectory() {
  const { data: facilities, isLoading } = useFacilities()
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search, 300)
  const [filters, setFilters] = useState({ county: 'all', subcounty: 'all', status: 'all' })

  const counties = useMemo(() => {
    if (!facilities) return []
    return [...new Set(facilities.map(f => f.county))].sort()
  }, [facilities])

  const subcounties = useMemo(() => {
    if (!facilities) return []
    const base = filters.county === 'all' ? facilities : facilities.filter(f => f.county === filters.county)
    return [...new Set(base.map(f => f.subcounty).filter(Boolean) as string[])].sort()
  }, [facilities, filters.county])

  const filtered = useMemo(() => {
    if (!facilities) return []
    return facilities.filter(f => {
      const matchesSearch = !debouncedSearch ||
        f.facility_name.toLowerCase().includes(debouncedSearch.toLowerCase()) ||
        f.mfl_code?.toLowerCase().includes(debouncedSearch.toLowerCase()) ||
        f.county.toLowerCase().includes(debouncedSearch.toLowerCase())
      const matchesCounty = filters.county === 'all' || f.county === filters.county
      const matchesSubcounty = filters.subcounty === 'all' || f.subcounty === filters.subcounty
      const matchesStatus = filters.status === 'all' || f.status === filters.status
      return matchesSearch && matchesCounty && matchesSubcounty && matchesStatus
    })
  }, [facilities, debouncedSearch, filters])

  const updateFilter = (key: keyof typeof filters, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }))
  }

  const resetFilters = () => setFilters({ county: 'all', subcounty: 'all', status: 'all' })

  if (isLoading) return <LoadingSpinner />

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-gray-900">Facility Directory</h1>
          <p className="text-gray-600 mt-1">Explore healthcare facility endpoints across Kenya</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => exportToCSV(filtered)} className="gap-2">
            <Download className="h-4 w-4" /> CSV
          </Button>
          <Button variant="outline" size="sm" onClick={() => exportToExcel(filtered)} className="gap-2">
            <Download className="h-4 w-4" /> Excel
          </Button>
        </div>
      </div>

      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <SearchBar value={search} onChange={setSearch} />
        <FiltersPanel
          filters={filters}
          counties={counties}
          subcounties={subcounties}
          onFilterChange={updateFilter}
          onReset={resetFilters}
        />
      </div>

      {filtered.length === 0 ? (
        <EmptyState title="No facilities found" description="Try adjusting your search or filters." />
      ) : (
        <FacilityTable data={filtered} />
      )}
    </div>
  )
}
EOF

cat > src/pages/FacilityDetail.tsx << 'EOF'
import { useParams, Link } from 'react-router-dom'
import { useFacility } from '@/hooks/useFacilities'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { StatusBadge } from '@/components/StatusBadge'
import { CopyButton } from '@/components/CopyButton'
import { Button } from '@/components/ui/button'
import { LoadingSpinner } from '@/components/LoadingSpinner'
import { ArrowLeft, ExternalLink, Globe } from 'lucide-react'

export function FacilityDetail() {
  const { id } = useParams<{ id: string }>()
  const { data: facility, isLoading } = useFacility(id!)

  if (isLoading) return <LoadingSpinner />
  if (!facility) return <div className="text-center py-20 text-gray-500">Facility not found.</div>

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <Link to="/" className="inline-flex items-center text-sm text-brand-600 hover:underline">
        <ArrowLeft className="mr-1 h-4 w-4" /> Back to directory
      </Link>
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-2xl">{facility.facility_name}</CardTitle>
            <StatusBadge status={facility.status} />
          </div>
          <p className="text-sm text-gray-500">
            {facility.county}{facility.subcounty ? `, ${facility.subcounty}` : ''} · {facility.facility_type || 'N/A'}
          </p>
        </CardHeader>
        <CardContent className="grid gap-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <InfoItem label="MFL Code" value={facility.mfl_code} />
            <InfoItem label="Facility Type" value={facility.facility_type} />
            <div className="space-y-1">
              <span className="text-sm font-medium text-gray-500">Sophos IP</span>
              <div className="flex items-center gap-2">
                <span className="font-mono">{facility.sophos_ip || '—'}</span>
                {facility.sophos_ip && <CopyButton text={facility.sophos_ip} />}
              </div>
            </div>
            <div className="space-y-1">
              <span className="text-sm font-medium text-gray-500">Elastic IP</span>
              <div className="flex items-center gap-2">
                <span className="font-mono">{facility.elastic_ip || '—'}</span>
                {facility.elastic_ip && <CopyButton text={facility.elastic_ip} />}
              </div>
            </div>
            <div className="space-y-1">
              <span className="text-sm font-medium text-gray-500">Sophos URL</span>
              <div className="flex items-center gap-2">
                {facility.sophos_url ? (
                  <a href={facility.sophos_url} target="_blank" rel="noreferrer" className="text-brand-600 hover:underline flex items-center gap-1">
                    <Globe className="h-4 w-4" /> Open
                  </a>
                ) : '—'}
              </div>
            </div>
            <div className="space-y-1">
              <span className="text-sm font-medium text-gray-500">Elastic URL</span>
              <div className="flex items-center gap-2">
                {facility.elastic_url ? (
                  <a href={facility.elastic_url} target="_blank" rel="noreferrer" className="text-brand-600 hover:underline flex items-center gap-1">
                    <Globe className="h-4 w-4" /> Open
                  </a>
                ) : '—'}
              </div>
            </div>
          </div>
          {facility.notes && (
            <div>
              <h4 className="text-sm font-medium text-gray-500 mb-1">Notes</h4>
              <p className="text-sm text-gray-700 whitespace-pre-wrap">{facility.notes}</p>
            </div>
          )}
          <div className="text-xs text-gray-400">
            Last updated: {new Date(facility.updated_at).toLocaleString()}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

function InfoItem({ label, value }: { label: string; value: string | null | undefined }) {
  return (
    <div className="space-y-1">
      <span className="text-sm font-medium text-gray-500">{label}</span>
      <p className="text-sm">{value || '—'}</p>
    </div>
  )
}
EOF

cat > src/pages/admin/Dashboard.tsx << 'EOF'
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
EOF

cat > src/pages/admin/FacilitiesList.tsx << 'EOF'
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
EOF

cat > src/pages/admin/FacilityForm.tsx << 'EOF'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { facilitySchema, type FacilityFormData } from '@/utils/validation'
import { useCreateFacility, useUpdateFacility, useFacility } from '@/hooks/useFacilities'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { toast } from 'sonner'
import { useEffect } from 'react'

export function FacilityForm() {
  const { id } = useParams<{ id: string }>()
  const isEdit = Boolean(id)
  const { data: facility } = useFacility(id!)
  const createMutation = useCreateFacility()
  const updateMutation = useUpdateFacility()
  const navigate = useNavigate()

  const { register, handleSubmit, formState: { errors }, reset } = useForm<FacilityFormData>({
    resolver: zodResolver(facilitySchema),
    defaultValues: {
      facility_name: '',
      county: '',
      subcounty: '',
      facility_type: '',
      mfl_code: '',
      sophos_ip: '',
      elastic_ip: '',
      sophos_url: '',
      elastic_url: '',
      status: 'active',
      notes: '',
    },
  })

  useEffect(() => {
    if (facility && isEdit) {
      reset({
        facility_name: facility.facility_name,
        county: facility.county,
        subcounty: facility.subcounty || '',
        facility_type: facility.facility_type || '',
        mfl_code: facility.mfl_code || '',
        sophos_ip: facility.sophos_ip || '',
        elastic_ip: facility.elastic_ip || '',
        sophos_url: facility.sophos_url || '',
        elastic_url: facility.elastic_url || '',
        status: facility.status,
        notes: facility.notes || '',
      })
    }
  }, [facility, isEdit, reset])

  const onSubmit = async (data: FacilityFormData) => {
    try {
      if (isEdit && id) {
        await updateMutation.mutateAsync({ id, ...data })
        toast.success('Facility updated')
      } else {
        await createMutation.mutateAsync(data)
        toast.success('Facility created')
      }
      navigate('/admin/facilities')
    } catch (err: any) {
      toast.error(err.message)
    }
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <h1 className="text-3xl font-bold">{isEdit ? 'Edit Facility' : 'New Facility'}</h1>
      <Card>
        <CardHeader><CardTitle>Facility Details</CardTitle></CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="facility_name">Facility Name *</Label>
                <Input id="facility_name" {...register('facility_name')} />
                {errors.facility_name && <p className="text-red-500 text-xs">{errors.facility_name.message}</p>}
              </div>
              <div className="space-y-2">
                <Label htmlFor="mfl_code">MFL Code</Label>
                <Input id="mfl_code" {...register('mfl_code')} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="county">County *</Label>
                <Input id="county" {...register('county')} />
                {errors.county && <p className="text-red-500 text-xs">{errors.county.message}</p>}
              </div>
              <div className="space-y-2">
                <Label htmlFor="subcounty">Subcounty</Label>
                <Input id="subcounty" {...register('subcounty')} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="facility_type">Facility Type</Label>
                <Input id="facility_type" {...register('facility_type')} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="status">Status</Label>
                <Input id="status" {...register('status')} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="sophos_ip">Sophos IP</Label>
                <Input id="sophos_ip" placeholder="192.168.1.1" {...register('sophos_ip')} />
                {errors.sophos_ip && <p className="text-red-500 text-xs">{errors.sophos_ip.message}</p>}
              </div>
              <div className="space-y-2">
                <Label htmlFor="elastic_ip">Elastic IP</Label>
                <Input id="elastic_ip" placeholder="10.0.0.1" {...register('elastic_ip')} />
                {errors.elastic_ip && <p className="text-red-500 text-xs">{errors.elastic_ip.message}</p>}
              </div>
              <div className="space-y-2">
                <Label htmlFor="sophos_url">Sophos URL</Label>
                <Input id="sophos_url" placeholder="https://" {...register('sophos_url')} />
                {errors.sophos_url && <p className="text-red-500 text-xs">{errors.sophos_url.message}</p>}
              </div>
              <div className="space-y-2">
                <Label htmlFor="elastic_url">Elastic URL</Label>
                <Input id="elastic_url" placeholder="https://" {...register('elastic_url')} />
                {errors.elastic_url && <p className="text-red-500 text-xs">{errors.elastic_url.message}</p>}
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="notes">Notes</Label>
              <Input id="notes" {...register('notes')} />
            </div>
            <div className="flex gap-3 justify-end">
              <Button variant="outline" type="button" onClick={() => navigate('/admin/facilities')}>Cancel</Button>
              <Button type="submit">{isEdit ? 'Update' : 'Create'}</Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
EOF

cat > src/pages/admin/Import.tsx << 'EOF'
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
EOF

cat > src/pages/admin/Users.tsx << 'EOF'
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
EOF

# ---------- Routing ----------
cat > src/routes/index.tsx << 'EOF'
import { createBrowserRouter } from 'react-router-dom'
import { PublicLayout } from '@/layouts/PublicLayout'
import { AdminLayout } from '@/layouts/AdminLayout'
import { FacilityDirectory } from '@/pages/FacilityDirectory'
import { FacilityDetail } from '@/pages/FacilityDetail'
import { Login } from '@/pages/Login'
import { Dashboard } from '@/pages/admin/Dashboard'
import { FacilitiesList } from '@/pages/admin/FacilitiesList'
import { FacilityForm } from '@/pages/admin/FacilityForm'
import { Import } from '@/pages/admin/Import'
import { Users } from '@/pages/admin/Users'
import { ProtectedRoute } from '@/components/ProtectedRoute'

export const router = createBrowserRouter([
  {
    element: <PublicLayout />,
    children: [
      { path: '/', element: <FacilityDirectory /> },
      { path: '/facility/:id', element: <FacilityDetail /> },
      { path: '/login', element: <Login /> },
    ],
  },
  {
    element: (
      <ProtectedRoute requiredRoles={['admin', 'editor']}>
        <AdminLayout />
      </ProtectedRoute>
    ),
    children: [
      { path: '/admin', element: <Dashboard /> },
      { path: '/admin/facilities', element: <FacilitiesList /> },
      { path: '/admin/facilities/new', element: <FacilityForm /> },
      { path: '/admin/facilities/:id/edit', element: <FacilityForm /> },
      { path: '/admin/import', element: <Import /> },
      { path: '/admin/users', element: <Users /> },
    ],
  },
])
EOF

cat > src/components/ProtectedRoute.tsx << 'EOF'
import { Navigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import { LoadingSpinner } from '@/components/LoadingSpinner'

interface ProtectedRouteProps {
  children: React.ReactNode
  requiredRoles?: string[]
}

export function ProtectedRoute({ children, requiredRoles }: ProtectedRouteProps) {
  const { user, profile, isLoading } = useAuth()

  if (isLoading) return <LoadingSpinner />

  if (!user) {
    return <Navigate to="/login" replace />
  }

  if (requiredRoles && profile && !requiredRoles.includes(profile.role)) {
    return <Navigate to="/" replace />
  }

  return <>{children}</>
}
EOF

# ---------- App.tsx and main.tsx ----------
cat > src/App.tsx << 'EOF'
import { RouterProvider } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from '@/contexts/AuthContext'
import { router } from '@/routes'
import { Toaster } from 'sonner'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,
      retry: 1,
    },
  },
})

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <RouterProvider router={router} />
        <Toaster position="top-right" richColors />
      </AuthProvider>
    </QueryClientProvider>
  )
}

export default App
EOF

cat > src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

# Clean up boilerplate files if they still exist
rm -f src/App.css

echo ""
echo "✅ Project source replaced successfully!"
echo "Now update .env with your Supabase credentials and run 'npm run dev'."