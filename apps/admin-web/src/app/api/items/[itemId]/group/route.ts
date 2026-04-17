import { NextResponse } from "next/server";

import { getEstateSaleRepository } from "@/lib/server/repository";

export async function POST(
  request: Request,
  context: { params: Promise<{ itemId: string }> },
) {
  const { itemId } = await context.params;
  const repo = getEstateSaleRepository();
  const body = (await request.json()) as { itemIds?: string[] };
  const items = await repo.groupItems([itemId, ...(body.itemIds ?? [])]);
  return NextResponse.json({ items });
}
