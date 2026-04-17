import { DashboardShell } from "@/components/dashboard-shell";
import { OrdersPanel } from "@/components/orders-panel";
import { getEstateSaleRepository } from "@/lib/server/repository";

export default async function OrdersPage() {
  const repo = getEstateSaleRepository();
  const data = await repo.getDashboardData();

  return (
    <DashboardShell eyebrow="Fulfillment" title="Orders And Exceptions">
      <OrdersPanel orders={data.orders} />
    </DashboardShell>
  );
}
