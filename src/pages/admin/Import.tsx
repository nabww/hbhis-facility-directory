import { useState } from "react";
import { ExcelUploader } from "@/components/ExcelUploader";
import { facilitiesService } from "@/services/facilities";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import * as XLSX from "xlsx";
import { Download } from "lucide-react";

// Template headers match exactly your database column names (ignoring id, created_at, updated_at)
const TEMPLATE_HEADERS = [
  "mfl_code",
  "facility_name",
  "county",
  "subcounty",
  "facility_type",
  "sophos_ip",
  "elastic_ip",
  "sophos_url",
  "elastic_url",
  "status",
  "notes",
];

function downloadTemplate() {
  const ws = XLSX.utils.aoa_to_sheet([TEMPLATE_HEADERS]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, "Facilities");
  XLSX.writeFile(wb, "facility_import_template.xlsx");
}

export function Import() {
  const [data, setData] = useState<any[] | null>(null);
  const [loading, setLoading] = useState(false);

  const handleImport = async () => {
    if (!data || data.length === 0) return;
    setLoading(true);
    try {
      // Safely convert any cell value (number, string, null) to string and trim
      const safeTrim = (val: unknown) => String(val ?? "").trim();

      const mapped = data
        .map((row) => ({
          mfl_code: safeTrim(row["mfl_code"]) || null,
          facility_name: safeTrim(row["facility_name"]),
          county: safeTrim(row["county"]),
          subcounty: safeTrim(row["subcounty"]) || null,
          facility_type: safeTrim(row["facility_type"]) || null,
          sophos_ip: safeTrim(row["sophos_ip"]) || null,
          elastic_ip: safeTrim(row["elastic_ip"]) || null,
          sophos_url: safeTrim(row["sophos_url"]) || null,
          elastic_url: safeTrim(row["elastic_url"]) || null,
          status: safeTrim(row["status"]) || "active", // default to 'active' if empty
          notes: safeTrim(row["notes"]) || null,
        }))
        .filter((f) => f.facility_name !== ""); // skip rows with no facility name

      if (mapped.length === 0) {
        toast.error("No valid rows found. Check file and column headers.");
        setLoading(false);
        return;
      }

      await facilitiesService.bulkImport(mapped as any);

      const skipped = data.length - mapped.length;
      toast.success(
        `Imported ${mapped.length} facilities` +
          (skipped > 0 ? ` (${skipped} blank rows skipped)` : ""),
      );
      setData(null);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Import failed";
      toast.error(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-2xl">
      <h1 className="text-3xl font-bold">Import Facilities</h1>

      {/* Template download card */}
      <Card>
        <CardHeader>
          <CardTitle>Download Template</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-gray-600 mb-3">
            Use the template to ensure your file has the correct column headers.
          </p>
          <Button
            onClick={downloadTemplate}
            variant="outline"
            className="gap-2">
            <Download className="h-4 w-4" />
            Download Template (.xlsx)
          </Button>
        </CardContent>
      </Card>

      {/* Upload card */}
      <Card>
        <CardHeader>
          <CardTitle>Upload Excel File</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <ExcelUploader onUpload={setData} />
          {data && (
            <div>
              <p className="text-sm text-gray-600">
                {data.length} rows detected.
              </p>
              <Button
                onClick={handleImport}
                disabled={loading}
                className="mt-2">
                {loading ? "Importing..." : "Start Import"}
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
