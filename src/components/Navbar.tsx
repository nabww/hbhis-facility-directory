import { Link, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/hooks/useAuth";
import { LogIn, LogOut, Shield, Building2 } from "lucide-react";

export function Navbar() {
  const { user, profile, signOut } = useAuth();
  const navigate = useNavigate();

  return (
    <nav className="sticky top-0 z-40 w-full border-b bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/60">
      <div className="flex h-16 items-center justify-between px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-2">
          <Building2 className="h-6 w-6 text-brand-600" />
          <Link to="/" className="text-xl font-bold text-gray-900">
            HBHIS <span className="text-brand-600">Directory</span>
          </Link>
        </div>
        <div className="flex items-center gap-3">
          {user && profile?.role !== "viewer" ? (
            <>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => navigate("/admin")}>
                <Shield className="mr-2 h-4 w-4" /> Admin
              </Button>
              <Button variant="outline" size="sm" onClick={signOut}>
                <LogOut className="mr-2 h-4 w-4" /> Sign Out
              </Button>
            </>
          ) : (
            <Button
              variant="outline"
              size="sm"
              onClick={() => navigate("/login")}>
              <LogIn className="mr-2 h-4 w-4" /> Admin Login
            </Button>
          )}
        </div>
      </div>
    </nav>
  );
}
