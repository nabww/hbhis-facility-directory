import { z } from "zod";

const ipv4Regex = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;

export const facilitySchema = z.object({
  mfl_code: z.string().optional(),
  facility_name: z.string().min(1, "Facility name is required"),
  county: z.string().min(1, "County is required"),
  subcounty: z.string().optional(),
  facility_type: z.string().optional(),
  sophos_ip: z
    .string()
    .refine((val) => !val || ipv4Regex.test(val), "Invalid IPv4 address")
    .optional()
    .or(z.literal("")),
  elastic_ip: z
    .string()
    .refine((val) => !val || ipv4Regex.test(val), "Invalid IPv4 address")
    .optional()
    .or(z.literal("")),
  sophos_url: z.string().url().optional().or(z.literal("")),
  elastic_url: z.string().url().optional().or(z.literal("")),
  status: z.string().optional(),
  notes: z.string().optional(),
});

export type FacilityFormData = z.infer<typeof facilitySchema>;
