import { NextResponse } from "next/server";

import { getEstateSaleRepository } from "@/lib/server/repository";

export async function POST(
  request: Request,
  context: { params: Promise<{ orderId: string }> },
) {
  const { orderId } = await context.params;
  const body = (await request.json()) as {
    weightOz: number;
    lengthIn: number;
    widthIn: number;
    heightIn: number;
  };
  const repo = getEstateSaleRepository();
  const shipment = await repo.purchaseShippingLabel(orderId, body);
  return NextResponse.json({ shipment });
}
