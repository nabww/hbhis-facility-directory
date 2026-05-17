# HBHIS Facility Directory

A modern healthcare operations dashboard for managing facility endpoints and EMR access details across counties in Kenya.

---

## Features

### Public Facility Directory
Accessible without login for easy facility lookup and operational visibility.

- Global search across facilities, counties, sub-counties, and EMR systems
- Advanced filtering by county, sub-county, facility type, and EMR
- Paginated directory view (50 facilities per page)
- Export filtered results to CSV and Excel
- Responsive tables and clean facility cards
- Sticky navigation bar for quick access
- Fast client-side performance with cached queries and debounced search

---

### Admin Dashboard
Secure administration portal for healthcare operations teams.

- Secure authentication with Supabase Auth
- Role-based access control:
  - `admin`
  - `editor`
  - `viewer`
- Full CRUD operations for facility records
- Bulk Excel import for large facility uploads
- Audit logging for tracking changes and user activity
- Form validation using Zod + React Hook Form
- Real-time UI feedback with toast notifications

---

## Tech Stack

### Frontend
- React 18
- Vite
- TypeScript
- TailwindCSS
- ShadCN-style UI components
- Radix UI primitives
- Lucide React icons

### Data & State Management
- TanStack React Query
- TanStack React Table
- React Hook Form
- Zod

### Backend & Authentication
- Supabase
  - PostgreSQL database
  - Authentication
  - Row Level Security (RLS)
  - Storage (optional)

### Utilities
- SheetJS / xlsx
- Sonner toast notifications

---

# Getting Started

## Prerequisites

Before setting up the project, ensure you have:

- Node.js >= 18
- npm
- A Supabase account

Create a Supabase account here:

- https://supabase.com

---

# Installation

## 1. Clone the Repository

```bash
git clone https://github.com/your-org/hbhis-facility-directory.git

cd hbhis-facility-directory
```

---

## 2. Install Dependencies

```bash
npm install
```

---

## 3. Configure Environment Variables

Create a `.env` file in the project root:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### Where to Find These Values

In your Supabase dashboard:

1. Open your project
2. Navigate to:

```text
Project Settings → API
```

3. Copy:
   - Project URL → `VITE_SUPABASE_URL`
   - anon public key → `VITE_SUPABASE_ANON_KEY`

---

## 4. Run Database Migration

Apply the initial schema located at:

```text
supabase/migrations/00001_initial_schema.sql
```

You can run it using the Supabase SQL Editor or Supabase CLI.

### Using Supabase SQL Editor

1. Open Supabase Dashboard
2. Go to:

```text
SQL Editor
```

3. Paste the migration contents
4. Run the query

### Using Supabase CLI (Optional)

```bash
supabase db push
```

---

## 5. Start Development Server

```bash
npm run dev
```

The application will start on:

```text
http://localhost:5173
```

---

# Creating an Admin User

## 1. Enable Email/Password Authentication

In Supabase:

```text
Authentication → Providers → Email
```

Enable:

- Email Provider
- Email/Password Sign-In

---

## 2. Create a User

Navigate to:

```text
Authentication → Users
```

Create a new user manually.

Example:

```text
Email: admin@hbhis.org
Password: ********
```

---

## 3. Assign Admin Role

Insert the user profile into your `profiles` table.

Example SQL:

```sql
INSERT INTO profiles (
  id,
  full_name,
  role
)
VALUES (
  'USER_UUID_FROM_AUTH',
  'System Administrator',
  'admin'
);
```

Replace:

```text
USER_UUID_FROM_AUTH
```

with the actual Auth user ID from Supabase.

---

# Project Structure

```text
hbhis-facility-directory/
│
├── public/
│
├── src/
│   ├── components/
│   │   ├── ui/
│   │   ├── tables/
│   │   ├── forms/
│   │   └── layout/
│   │
│   ├── pages/
│   │   ├── public/
│   │   └── admin/
│   │
│   ├── hooks/
│   ├── services/
│   ├── lib/
│   ├── types/
│   ├── utils/
│   ├── context/
│   └── main.tsx
│
├── supabase/
│   ├── migrations/
│   │   └── 00001_initial_schema.sql
│   │
│   └── functions/
│
├── .env
├── package.json
├── vite.config.ts
├── tailwind.config.ts
└── README.md
```

---

# Performance Optimizations

The application is optimized for smooth performance and operational efficiency.

- Debounced search input
- React Query caching
- Efficient client-side pagination
- Lazy-loaded routes/components
- Optimized table rendering with TanStack Table
- Minimal re-renders using memoization patterns

---

# UI & Branding

The interface is designed for operational clarity and speed.

- Purple-based healthcare branding
- Responsive mobile-first layout
- Sticky top navigation
- Clean cards and tables
- Accessible UI primitives using Radix
- Modern utility-first styling with TailwindCSS

---

# Deployment

## Frontend Deployment

The frontend can be deployed to:

- Netlify
- Vercel

### Build Command

```bash
npm run build
```

### Publish Directory

```text
dist
```

---

## Netlify Configuration

### Build Settings

```text
Build command: npm run build
Publish directory: dist
```

### Redirects

Add a `_redirects` file inside `public/`:

```text
/* /index.html 200
```

---

## Vercel Configuration

Framework preset:

```text
Vite
```

Build command:

```bash
npm run build
```

Output directory:

```text
dist
```

---

## Supabase Configuration

Update your redirect URLs in Supabase:

```text
Authentication → URL Configuration
```

Add:

### Site URL

```text
https://your-production-domain.com
```

### Redirect URLs

```text
http://localhost:5173
https://your-production-domain.com
```

---

# Security Notes

- Enable Row Level Security (RLS) on all tables
- Restrict admin routes using role checks
- Store sensitive configuration in environment variables
- Never expose service role keys in frontend code

---

# License

This project is intended for internal healthcare operations and facility management workflows.

Unauthorized redistribution or commercial resale is not permitted.

---

# Acknowledgements

Built using:

- React
- Vite
- Supabase
- TailwindCSS
- TanStack
- Radix UI
- ShadCN-inspired component architecture

For healthcare operations teams supporting EMR coordination and facility endpoint management across Kenya.
