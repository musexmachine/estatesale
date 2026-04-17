# EstateSale Worker

The worker owns long-running and privileged async jobs:

- intake processing for photos and walkthrough video
- listing publish jobs
- shipping label purchase jobs
- local courier dispatch jobs
- pickup scheduling jobs

The implementation in this repo is deliberately adapter-first. The worker never assumes a concrete OCR, detection, eBay, EasyPost, or Uber implementation; it relies on typed provider boundaries so model vendors and provider SDKs can change without rewriting workflow state logic.
