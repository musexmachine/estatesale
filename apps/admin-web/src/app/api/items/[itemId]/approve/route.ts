import { NextResponse } from "next/server";

import { getEstateSaleRepository } from "@/lib/server/repository";

export async function POST(
  _request: Request,
  context: { params: Promise<{ itemId: string }> },
) {
  const { itemId } = await context.params;
  const repo = getEstateSaleRepository();
  const item = await repo.approveItem(itemId);
  return NextResponse.json({ item });
}
