import { useParams, Link } from "react-router-dom";
import { useFacility } from "@/hooks/useFacilities";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StatusBadge } from "@/components/StatusBadge";
import { CopyButton } from "@/components/CopyButton";
import { LoadingSpinner } from "@/components/LoadingSpinner";
import { ArrowLeft, Monitor, Tablet, Globe } from "lucide-react";

export function FacilityDetail() {
  const { id } = useParams<{ id: string }>();
  const { data: facility, isLoading } = useFacility(id!);

  if (isLoading) return <LoadingSpinner />;
  if (!facility)
    return (
      <div className="text-center py-20 text-gray-500">Facility not found.</div>
    );

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <Link
        to="/"
        className="inline-flex items-center text-sm font-medium text-brand-600 hover:text-brand-700 transition-colors">
        <ArrowLeft className="mr-1 h-4 w-4" /> Back to directory
      </Link>

      <Card className="overflow-hidden rounded-xl shadow-sm border">
        <CardHeader className="bg-brand-50/50 border-b px-6 py-5">
          <div className="flex items-start justify-between">
            <div>
              <CardTitle className="text-2xl font-bold text-gray-900">
                {facility.facility_name}
              </CardTitle>
              <p className="text-sm text-gray-600 mt-1">
                {facility.county}
                {facility.subcounty ? `, ${facility.subcounty}` : ""}
                {facility.facility_type ? ` · ${facility.facility_type}` : ""}
              </p>
            </div>
            <StatusBadge status={facility.status} />
          </div>
        </CardHeader>

        <CardContent className="p-6 space-y-6">
          {/* Basic information */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">
            <InfoItem label="MFL Code" value={facility.mfl_code} />
            <InfoItem label="Facility Type" value={facility.facility_type} />
          </div>

          {/* IP addresses with actions */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Sophos card */}
            <div className="bg-gray-50 rounded-lg p-4">
              <h4 className="text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2">
                <Monitor className="h-4 w-4" /> Sophos IP
              </h4>
              <div className="flex items-center gap-3">
                <span className="font-mono text-lg">
                  {facility.sophos_ip || "—"}
                </span>
                {facility.sophos_ip && <CopyButton text={facility.sophos_ip} />}
                {facility.sophos_url && (
                  <a
                    href={facility.sophos_url}
                    target="_blank"
                    rel="noreferrer"
                    className="text-gray-500 hover:text-brand-600 transition-colors"
                    title="Open Sophos URL">
                    <Monitor className="h-5 w-5" />
                  </a>
                )}
              </div>
              {facility.sophos_url && (
                <p className="text-xs text-gray-500 mt-2 truncate flex items-center gap-1">
                  <Globe className="h-3 w-3" /> {facility.sophos_url}
                </p>
              )}
            </div>

            {/* Elastic card */}
            <div className="bg-gray-50 rounded-lg p-4">
              <h4 className="text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2">
                <Tablet className="h-4 w-4" /> Elastic IP
              </h4>
              <div className="flex items-center gap-3">
                <span className="font-mono text-lg">
                  {facility.elastic_ip || "—"}
                </span>
                {facility.elastic_ip && (
                  <CopyButton text={facility.elastic_ip} />
                )}
                {facility.elastic_url && (
                  <a
                    href={facility.elastic_url}
                    target="_blank"
                    rel="noreferrer"
                    className="text-gray-500 hover:text-brand-600 transition-colors"
                    title="Open Elastic URL">
                    <Tablet className="h-5 w-5" />
                  </a>
                )}
              </div>
              {facility.elastic_url && (
                <p className="text-xs text-gray-500 mt-2 truncate flex items-center gap-1">
                  <Globe className="h-3 w-3" /> {facility.elastic_url}
                </p>
              )}
            </div>
          </div>

          {/* Notes */}
          {facility.notes && (
            <div>
              <h4 className="text-sm font-medium text-gray-500 mb-1">Notes</h4>
              <p className="text-sm text-gray-800 whitespace-pre-wrap border-l-2 border-brand-200 pl-3 italic">
                {facility.notes}
              </p>
            </div>
          )}

          {/* Timestamp */}
          <div className="text-xs text-gray-400 flex items-center justify-end border-t pt-4 mt-4">
            Last updated: {new Date(facility.updated_at).toLocaleString()}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function InfoItem({
  label,
  value,
}: {
  label: string;
  value: string | null | undefined;
}) {
  return (
    <div>
      <dt className="text-sm font-medium text-gray-500">{label}</dt>
      <dd className="mt-1 text-sm text-gray-900">{value || "—"}</dd>
    </div>
  );
}
