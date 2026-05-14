import { useState, useMemo } from "react";
import { useFacilities } from "@/hooks/useFacilities";
import { useDebounce } from "@/hooks/useDebounce";
import { FacilityTable } from "@/components/FacilityTable";
import { SearchBar } from "@/components/SearchBar";
import { FiltersPanel } from "@/components/FiltersPanel";
import { LoadingSpinner } from "@/components/LoadingSpinner";
import { EmptyState } from "@/components/EmptyState";
import { exportToCSV, exportToExcel } from "@/utils/export";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
} from "@/components/ui/dropdown-menu";
import {
  Building2,
  MapPin,
  Activity,
  Filter,
  Download,
  ChevronDown,
} from "lucide-react";

export function FacilityDirectory() {
  const { data: facilities, isLoading } = useFacilities();
  const [search, setSearch] = useState("");
  const debouncedSearch = useDebounce(search, 300);
  const [filters, setFilters] = useState({
    county: "all",
    subcounty: "all",
    status: "all",
  });
  const [showFilters, setShowFilters] = useState(false);

  const counties = useMemo(() => {
    if (!facilities) return [];
    return [...new Set(facilities.map((f) => f.county))].sort();
  }, [facilities]);

  const subcounties = useMemo(() => {
    if (!facilities) return [];
    const base =
      filters.county === "all"
        ? facilities
        : facilities.filter((f) => f.county === filters.county);
    return [
      ...new Set(base.map((f) => f.subcounty).filter(Boolean) as string[]),
    ].sort();
  }, [facilities, filters.county]);

  const filtered = useMemo(() => {
    if (!facilities) return [];
    return facilities.filter((f) => {
      const matchesSearch =
        !debouncedSearch ||
        f.facility_name.toLowerCase().includes(debouncedSearch.toLowerCase()) ||
        f.mfl_code?.toLowerCase().includes(debouncedSearch.toLowerCase()) ||
        f.county.toLowerCase().includes(debouncedSearch.toLowerCase()) ||
        f.sophos_ip?.toLowerCase().includes(debouncedSearch.toLowerCase()) ||
        f.elastic_ip?.toLowerCase().includes(debouncedSearch.toLowerCase());
      const matchesCounty =
        filters.county === "all" || f.county === filters.county;
      const matchesSubcounty =
        filters.subcounty === "all" || f.subcounty === filters.subcounty;
      const matchesStatus =
        filters.status === "all" || f.status === filters.status;
      return (
        matchesSearch && matchesCounty && matchesSubcounty && matchesStatus
      );
    });
  }, [facilities, debouncedSearch, filters]);

  const updateFilter = (key: keyof typeof filters, value: string) => {
    setFilters((prev) => ({ ...prev, [key]: value }));
  };

  const resetFilters = () => {
    setFilters({ county: "all", subcounty: "all", status: "all" });
    setShowFilters(false);
  };

  // Stats
  const totalCount = facilities?.length || 0;
  const countyCount = counties.length;
  const activeCount =
    facilities?.filter((f) => f.status === "active").length || 0;

  if (isLoading) return <LoadingSpinner />;

  return (
    <div className="space-y-8">
      {/* Header + Stats */}
      <div className="bg-white rounded-2xl shadow-sm border overflow-hidden">
        <div className="bg-gradient-to-r from-brand-600 to-brand-800 px-6 py-8 sm:px-8">
          <h1 className="text-3xl font-bold tracking-tight text-white">
            HBHIS Facility Directory
          </h1>
          <p className="mt-2 text-brand-100">
            Explore healthcare facility endpoints across Kenya
          </p>
        </div>

        {/* Quick stats */}
        <div className="grid grid-cols-3 divide-x border-b">
          <div className="flex items-center gap-3 p-4 sm:p-5">
            <div className="p-2 bg-brand-50 rounded-lg">
              <Building2 className="h-5 w-5 text-brand-600" />
            </div>
            <div>
              <p className="text-xs font-medium text-gray-500 uppercase">
                Facilities
              </p>
              <p className="text-lg font-bold text-gray-900">{totalCount}</p>
            </div>
          </div>
          <div className="flex items-center gap-3 p-4 sm:p-5">
            <div className="p-2 bg-brand-50 rounded-lg">
              <MapPin className="h-5 w-5 text-brand-600" />
            </div>
            <div>
              <p className="text-xs font-medium text-gray-500 uppercase">
                Counties
              </p>
              <p className="text-lg font-bold text-gray-900">{countyCount}</p>
            </div>
          </div>
          <div className="flex items-center gap-3 p-4 sm:p-5">
            <div className="p-2 bg-green-50 rounded-lg">
              <Activity className="h-5 w-5 text-green-600" />
            </div>
            <div>
              <p className="text-xs font-medium text-gray-500 uppercase">
                Active
              </p>
              <p className="text-lg font-bold text-gray-900">{activeCount}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Toolbar: Search, Filter toggle, Download */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <SearchBar value={search} onChange={setSearch} />

        <div className="flex items-center gap-2">
          {/* Filter toggle */}
          <Button
            variant={showFilters ? "default" : "outline"}
            size="sm"
            onClick={() => setShowFilters(!showFilters)}
            className="gap-2">
            <Filter className="h-4 w-4" />
            Filters
            {showFilters && <ChevronDown className="h-4 w-4" />}
          </Button>

          {/* Download dropdown */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm" className="gap-2">
                <Download className="h-4 w-4" />
                Export
                <ChevronDown className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-40">
              <DropdownMenuItem onClick={() => exportToCSV(filtered)}>
                CSV
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => exportToExcel(filtered)}>
                Excel
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      {/* Collapsible filter panel */}
      {showFilters && (
        <div className="animate-in slide-in-from-top-2 duration-200">
          <FiltersPanel
            filters={filters}
            counties={counties}
            subcounties={subcounties}
            onFilterChange={updateFilter}
            onReset={resetFilters}
          />
        </div>
      )}

      {/* Table or empty state */}
      {filtered.length === 0 ? (
        <EmptyState
          title="No facilities found"
          description="Try adjusting your search or filters."
        />
      ) : (
        <FacilityTable data={filtered} />
      )}
    </div>
  );
}
