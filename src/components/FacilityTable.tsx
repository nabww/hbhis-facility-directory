import { useMemo, useState } from "react";
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  flexRender,
  type SortingState,
} from "@tanstack/react-table";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { StatusBadge } from "@/components/StatusBadge";
import { CopyButton } from "@/components/CopyButton";
import { Monitor, Tablet } from "lucide-react";
import { Link } from "react-router-dom";
import type { Facility } from "@/types";

interface FacilityTableProps {
  data: Facility[];
}

export function FacilityTable({ data }: FacilityTableProps) {
  const [sorting, setSorting] = useState<SortingState>([]);

  const columns = useMemo(
    () => [
      {
        accessorKey: "facility_name",
        header: "Facility Name",
        cell: (info: any) => (
          <div className="max-w-[250px]">
            <Link
              to={`/facility/${info.row.original.id}`}
              className="font-medium text-gray-900 hover:text-brand-600 transition-colors whitespace-normal break-words">
              {info.getValue()}
            </Link>
          </div>
        ),
      },
      { accessorKey: "county", header: "County" },
      { accessorKey: "subcounty", header: "Subcounty" },
      // { accessorKey: "facility_type", header: "Type" },
      {
        id: "sophos_ip",
        header: () => <div className="text-center w-full">Sophos Address</div>,
        cell: ({ row }: any) => (
          <div className="flex justify-center">
            <div className="flex items-center gap-2">
              {/* <span className="font-mono text-sm">
                {row.original.sophos_ip || "—"}
              </span> */}
              {/* {row.original.sophos_ip && <CopyButton text={row.original.sophos_ip} />} */}
              {row.original.sophos_url && (
                <a
                  href={row.original.sophos_url}
                  target="_blank"
                  rel="noreferrer"
                  className="text-gray-400 hover:text-brand-600 transition-colors"
                  title="Open Sophos URL">
                  <Monitor className="h-5 w-5" />
                </a>
              )}
            </div>
          </div>
        ),
      },
      {
        id: "elastic_ip",
        header: () => <div className="text-center w-full">Tablet Address</div>,
        cell: ({ row }: any) => (
          <div className="flex justify-center">
            <div className="flex items-center gap-2">
              {/* <span className="font-mono text-sm">
                {row.original.elastic_ip || "—"}
              </span> */}
              {/* {row.original.elastic_ip && <CopyButton text={row.original.elastic_ip} />} */}
              {row.original.elastic_url && (
                <a
                  href={row.original.elastic_url}
                  target="_blank"
                  rel="noreferrer"
                  className="text-gray-400 hover:text-brand-600 transition-colors"
                  title="Open Elastic URL">
                  <Tablet className="h-5 w-5" />
                </a>
              )}
            </div>
          </div>
        ),
      },
      // {
      //   accessorKey: "status",
      //   header: "Status",
      //   cell: ({ row }: any) => <StatusBadge status={row.original.status} />,
      // },
    ],
    [],
  );

  const table = useReactTable({
    data,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
  });

  return (
    <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
      <div className="overflow-auto">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id} className="bg-gray-50/50">
                {headerGroup.headers.map((header) => (
                  <TableHead
                    key={header.id}
                    className="font-semibold text-gray-700">
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext(),
                        )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  className="hover:bg-brand-50/30 transition-colors">
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext(),
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="text-center py-10 text-gray-400">
                  No facilities found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      <div className="flex items-center justify-between px-4 py-3 border-t bg-gray-50/50">
        <Button
          variant="outline"
          size="sm"
          onClick={() => table.previousPage()}
          disabled={!table.getCanPreviousPage()}>
          Previous
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => table.nextPage()}
          disabled={!table.getCanNextPage()}>
          Next
        </Button>
      </div>
    </div>
  );
}
