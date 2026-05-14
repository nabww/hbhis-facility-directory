import { useNavigate, useParams } from "react-router-dom";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { facilitySchema, type FacilityFormData } from "@/utils/validation";
import {
  useCreateFacility,
  useUpdateFacility,
  useFacility,
} from "@/hooks/useFacilities";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LoadingSpinner } from "@/components/LoadingSpinner";
import { toast } from "sonner";

export function FacilityForm() {
  const { id } = useParams<{ id: string }>();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  // Query facility only when editing
  const { data: facility, isLoading: isFacilityLoading } = useFacility(id!);

  const createMutation = useCreateFacility();
  const updateMutation = useUpdateFacility();

  // Build default values directly from fetched data (or empty for new)
  const defaultValues: FacilityFormData =
    isEdit && facility
      ? {
          facility_name: facility.facility_name,
          county: facility.county,
          subcounty: facility.subcounty || "",
          facility_type: facility.facility_type || "",
          mfl_code: facility.mfl_code || "",
          sophos_ip: facility.sophos_ip || "",
          elastic_ip: facility.elastic_ip || "",
          sophos_url: facility.sophos_url || "",
          elastic_url: facility.elastic_url || "",
          status: facility.status,
          notes: facility.notes || "",
        }
      : {
          facility_name: "",
          county: "",
          subcounty: "",
          facility_type: "",
          mfl_code: "",
          sophos_ip: "",
          elastic_ip: "",
          sophos_url: "",
          elastic_url: "",
          status: "active",
          notes: "",
        };

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FacilityFormData>({
    resolver: zodResolver(facilitySchema),
    defaultValues,
    // important: don't reset form after submit, we'll navigate away
  });

  const onSubmit = async (data: FacilityFormData) => {
    try {
      if (isEdit && id) {
        await updateMutation.mutateAsync({ id, ...data });
        toast.success("Facility updated");
      } else {
        await createMutation.mutateAsync(data);
        toast.success("Facility created");
      }
      navigate("/admin/facilities");
    } catch (err: any) {
      toast.error(err.message || "Something went wrong");
    }
  };

  // Show loading spinner only when editing and facility data is still loading
  if (isEdit && isFacilityLoading) {
    return <LoadingSpinner />;
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <h1 className="text-3xl font-bold">
        {isEdit ? "Edit Facility" : "New Facility"}
      </h1>
      <Card>
        <CardHeader>
          <CardTitle>Facility Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="facility_name">Facility Name *</Label>
                <Input id="facility_name" {...register("facility_name")} />
                {errors.facility_name && (
                  <p className="text-red-500 text-xs">
                    {errors.facility_name.message}
                  </p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="mfl_code">MFL Code</Label>
                <Input id="mfl_code" {...register("mfl_code")} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="county">County *</Label>
                <Input id="county" {...register("county")} />
                {errors.county && (
                  <p className="text-red-500 text-xs">
                    {errors.county.message}
                  </p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="subcounty">Subcounty</Label>
                <Input id="subcounty" {...register("subcounty")} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="facility_type">Facility Type</Label>
                <Input id="facility_type" {...register("facility_type")} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="status">Status</Label>
                <Input id="status" {...register("status")} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="sophos_ip">Sophos IP</Label>
                <Input
                  id="sophos_ip"
                  placeholder="192.168.1.1"
                  {...register("sophos_ip")}
                />
                {errors.sophos_ip && (
                  <p className="text-red-500 text-xs">
                    {errors.sophos_ip.message}
                  </p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="elastic_ip">Elastic IP</Label>
                <Input
                  id="elastic_ip"
                  placeholder="10.0.0.1"
                  {...register("elastic_ip")}
                />
                {errors.elastic_ip && (
                  <p className="text-red-500 text-xs">
                    {errors.elastic_ip.message}
                  </p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="sophos_url">Sophos URL</Label>
                <Input
                  id="sophos_url"
                  placeholder="https://"
                  {...register("sophos_url")}
                />
                {errors.sophos_url && (
                  <p className="text-red-500 text-xs">
                    {errors.sophos_url.message}
                  </p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="elastic_url">Elastic URL</Label>
                <Input
                  id="elastic_url"
                  placeholder="https://"
                  {...register("elastic_url")}
                />
                {errors.elastic_url && (
                  <p className="text-red-500 text-xs">
                    {errors.elastic_url.message}
                  </p>
                )}
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="notes">Notes</Label>
              <Input id="notes" {...register("notes")} />
            </div>
            <div className="flex gap-3 justify-end">
              <Button
                variant="outline"
                type="button"
                onClick={() => navigate("/admin/facilities")}>
                Cancel
              </Button>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Saving..." : isEdit ? "Update" : "Create"}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
