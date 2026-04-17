import { DemoEstateSaleRepository } from "@/lib/server/demo-repository";

export function getEstateSaleRepository() {
  return new DemoEstateSaleRepository();
}
