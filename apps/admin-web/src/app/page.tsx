import { DashboardShell } from "@/components/dashboard-shell";
import { MetricCard } from "@/components/metric-card";
import { OrdersPanel } from "@/components/orders-panel";
import { ReviewQueue } from "@/components/review-queue";
import { getEstateSaleRepository } from "@/lib/server/repository";

export default async function HomePage() {
  const repo = getEstateSaleRepository();
  const data = await repo.getDashboardData();
  const publishableCount = data.reviewQueue.filter(
    (item) => item.state === "approved" && item.riskFlags.length === 0,
  ).length;

  return (
    <DashboardShell eyebrow="Build 1 Admin" title="EstateSale Operations">
      <div className="metrics-row">
        <MetricCard label="Properties" value={String(data.properties.length)} />
        <MetricCard label="Needs Review" value={String(data.reviewQueue.length)} tone="warning" />
        <MetricCard label="Ready To Publish" value={String(publishableCount)} tone="success" />
        <MetricCard label="Orders" value={String(data.orders.length)} />
      </div>
      <ReviewQueue items={data.reviewQueue} />
      <OrdersPanel orders={data.orders} />
    </DashboardShell>
  );
}
