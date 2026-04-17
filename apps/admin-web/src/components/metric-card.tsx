export function MetricCard({
  label,
  value,
  tone = "neutral",
}: {
  label: string;
  value: string;
  tone?: "neutral" | "success" | "warning";
}) {
  return (
    <section className={`metric-card metric-${tone}`}>
      <p>{label}</p>
      <strong>{value}</strong>
    </section>
  );
}
