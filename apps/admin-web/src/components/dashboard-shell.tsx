import Link from "next/link";
import type { ReactNode } from "react";

export function DashboardShell({
  title,
  eyebrow,
  children,
}: {
  title: string;
  eyebrow: string;
  children: ReactNode;
}) {
  return (
    <main className="page-shell">
      <div className="hero-panel">
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p className="hero-copy">
          Operator-first controls for intake, review, publish, and fulfillment exceptions.
        </p>
        <nav className="nav-row" aria-label="Primary">
          <Link href="/">Overview</Link>
          <Link href="/review">Review Queue</Link>
          <Link href="/orders">Orders</Link>
        </nav>
      </div>
      <div className="content-grid">{children}</div>
    </main>
  );
}
