import { NextResponse } from "next/server";

import { getEstateSaleRepository } from "@/lib/server/repository";

export async function POST(request: Request) {
  const body = (await request.json()) as { soldListingId?: string };
  if (!body.soldListingId) {
    return NextResponse.json({ error: "soldListingId is required" }, { status: 400 });
  }

  const repo = getEstateSaleRepository();
  const listings = await repo.recordSale(body.soldListingId);
  return NextResponse.json({ listings });
}
