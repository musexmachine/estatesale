import { NextResponse } from "next/server";

import { getEstateSaleRepository } from "@/lib/server/repository";

export async function POST(
  request: Request,
  context: { params: Promise<{ orderId: string }> },
) {
  const { orderId } = await context.params;
  const body = (await request.json()) as {
    feeSnapshot: Record<string, unknown>;
    proofPolicy: {
      signatureRequired?: boolean;
      pinRequired?: boolean;
      photoRequired?: boolean;
    };
  };
  const repo = getEstateSaleRepository();
  const delivery = await repo.dispatchCourierDelivery(orderId, body);
  return NextResponse.json({ delivery });
}
