import type { OrderRecord } from "@/lib/types";

export function OrdersPanel({ orders }: { orders: OrderRecord[] }) {
  return (
    <section className="panel">
      <div className="panel-header">
        <h2>Orders</h2>
        <span>{orders.length} active</span>
      </div>
      <div className="stack-list">
        {orders.map((order) => (
          <article key={order.id} className="list-card">
            <div>
              <h3>{order.buyerName}</h3>
              <p>{order.id}</p>
            </div>
            <div className="meta-grid">
              <span>State: {order.state}</span>
              <span>Mode: {order.fulfillmentMode}</span>
              <span>Value: ${(order.salePriceCents / 100).toFixed(2)}</span>
              <span>{order.highValue ? "High-value proof required" : "Standard handling"}</span>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
