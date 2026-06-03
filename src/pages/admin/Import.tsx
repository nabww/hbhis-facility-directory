import { useState } from "react";
import { ExcelUploader } from "@/components/ExcelUploader";
import { facilitiesService } from "@/services/facilities";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import * as XLSX from "xlsx";
import { Download } from "lucide-react";

const TEMPLATE_HEADERS = [
  "MFL Code",
  "Facility Name",
  "County",
  "Subcounty",
  "Facility Type",
  "Sophos IP",
  "Elastic IP",
  "Sophos URL",
  "Elastic URL",
];

function downloadTemplate() {
  // Create a workbook with a single worksheet containing only the header row
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
      const mapped = data
        .map((row) => ({
          mfl_code: (row["MFL Code"] || "").trim() || null,
          facility_name: (row["Facility Name"] || "").trim(),
          county: (row["County"] || "").trim(),
          subcounty: (row["Subcounty"] || "").trim() || null,
          facility_type: (row["Facility Type"] || "").trim() || null,
          sophos_ip: (row["Sophos IP"] || "").trim() || null,
          elastic_ip: (row["Elastic IP"] || "").trim() || null,
          sophos_url: (row["Sophos URL"] || "").trim() || null,
          elastic_url: (row["Elastic URL"] || "").trim() || null,
          status: "active",
          notes: null,
        }))
        .filter((f) => f.facility_name !== "");

      if (mapped.length === 0) {
        toast.error(
          "No valid rows found. Please check the file and column headers.",
        );
        setLoading(false);
        return;
      }

      await facilitiesService.bulkImport(mapped);
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
