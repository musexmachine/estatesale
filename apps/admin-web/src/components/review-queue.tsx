import type { CandidateItem } from "@/lib/types";

export function ReviewQueue({ items }: { items: CandidateItem[] }) {
  return (
    <section className="panel">
      <div className="panel-header">
        <h2>Review Queue</h2>
        <span>{items.length} items</span>
      </div>
      <div className="stack-list">
        {items.map((item) => (
          <article key={item.id} className="list-card">
            <div>
              <h3>{item.title}</h3>
              <p>{item.conditionSummary}</p>
            </div>
            <div className="meta-grid">
              <span>State: {item.state}</span>
              <span>Confidence: {(item.confidence * 100).toFixed(0)}%</span>
              <span>Mode: {item.fulfillmentMode}</span>
              <span>
                Range: ${(item.priceLowCents / 100).toFixed(0)}-${(item.priceHighCents / 100).toFixed(0)}
              </span>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
