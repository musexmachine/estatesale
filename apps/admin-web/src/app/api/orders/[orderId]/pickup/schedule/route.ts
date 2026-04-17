import { NextResponse } from "next/server";

import { getEstateSaleRepository } from "@/lib/server/repository";

export async function POST(
  request: Request,
  context: { params: Promise<{ orderId: string }> },
) {
  const { orderId } = await context.params;
  const body = (await request.json()) as {
    scheduledFor: string;
    instructions: string;
  };
  const repo = getEstateSaleRepository();
  const pickup = await repo.schedulePickup(orderId, body.scheduledFor, body.instructions);
  return NextResponse.json({ pickup });
}
