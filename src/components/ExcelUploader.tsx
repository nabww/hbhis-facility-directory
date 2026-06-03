import { useState, useCallback } from "react";
import { Upload, FileSpreadsheet } from "lucide-react";
import * as XLSX from "xlsx";
import { Button } from "@/components/ui/button";

interface ExcelUploaderProps {
  onUpload: (data: any[]) => void;
}

export function ExcelUploader({ onUpload }: ExcelUploaderProps) {
  const [fileName, setFileName] = useState<string | null>(null);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      const file = e.dataTransfer.files[0];
      processFile(file);
    },
    [onUpload],
  );

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) processFile(file);
  };

  const processFile = (file: File) => {
    setFileName(file.name);
    const reader = new FileReader();
    reader.onload = (ev) => {
      const bstr = ev.target?.result;
      const wb = XLSX.read(bstr, { type: "binary" });
      const wsname = wb.SheetNames[0];
      const ws = wb.Sheets[wsname];
      const data = XLSX.utils.sheet_to_json(ws, { header: 1 });
      const headers = data[0] as string[];
      const rows = data
        .slice(1)
        .map((row: any) => {
          const obj: Record<string, any> = {};
          headers.forEach((h, i) => {
            obj[h.trim()] = row[i] ?? "";
          });
          return obj;
        })
        // Filter out rows where every value is empty/whitespace
        .filter((row) =>
          Object.values(row).some((val) => String(val).trim() !== ""),
        );

      onUpload(rows);
    };
    reader.readAsBinaryString(file);
  };

  return (
    <div
      onDragOver={(e) => e.preventDefault()}
      onDrop={handleDrop}
      className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 p-8 text-center hover:border-brand-500 transition-colors">
      {fileName ? (
        <div className="flex items-center gap-2">
          <FileSpreadsheet className="h-6 w-6 text-brand-600" />
          <span className="text-sm font-medium">{fileName}</span>
          <Button variant="ghost" size="sm" onClick={() => setFileName(null)}>
            Remove
          </Button>
        </div>
      ) : (
        <>
          <Upload className="h-8 w-8 text-gray-400 mb-2" />
          <p className="text-sm text-gray-600">
            Drag & drop an Excel file here, or
          </p>
          <label className="cursor-pointer text-sm text-brand-600 hover:underline mt-1">
            browse files
            <input
              type="file"
              accept=".xlsx,.xls"
              onChange={handleFileInput}
              className="hidden"
            />
          </label>
        </>
      )}
    </div>
  );
}
