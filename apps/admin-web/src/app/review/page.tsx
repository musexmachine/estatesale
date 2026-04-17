import { DashboardShell } from "@/components/dashboard-shell";
import { ReviewQueue } from "@/components/review-queue";
import { getEstateSaleRepository } from "@/lib/server/repository";

export default async function ReviewPage() {
  const repo = getEstateSaleRepository();
  const data = await repo.getDashboardData();

  return (
    <DashboardShell eyebrow="Review" title="Review Queue">
      <ReviewQueue items={data.reviewQueue} />
    </DashboardShell>
  );
}
