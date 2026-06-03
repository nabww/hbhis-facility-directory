import { useState } from "react";
import { ExcelUploader } from "@/components/ExcelUploader";
import { facilitiesService } from "@/services/facilities";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

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
        .filter((f) => f.facility_name !== ""); // ← ignores blank facility name rows

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
