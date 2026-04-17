import { NextResponse } from "next/server";

import { getEstateSaleRepository } from "@/lib/server/repository";

export async function POST(
  _request: Request,
  context: { params: Promise<{ listingId: string }> },
) {
  const { listingId } = await context.params;
  const repo = getEstateSaleRepository();
  const listing = await repo.publishListing(listingId);
  return NextResponse.json({ listing });
}
