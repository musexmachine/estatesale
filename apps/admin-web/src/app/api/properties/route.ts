import { NextResponse } from "next/server";

import { getEstateSaleRepository } from "@/lib/server/repository";

export async function GET() {
  const repo = getEstateSaleRepository();
  const data = await repo.getDashboardData();
  return NextResponse.json({ properties: data.properties });
}
