# EstateSale Build 1 Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Ship the first production-shaped EstateSale build across iPhone, web admin, backend, and async workers for intake, review, eBay publish, and all three fulfillment modes.

**Architecture:** Use Supabase as the system of record and auth/storage layer, a Python worker service for async media processing plus external-provider jobs, a SwiftUI iPhone app for seller workflows, and a Next.js admin web app for operator and exception workflows. Keep all marketplace and fulfillment integrations behind backend-owned adapter boundaries; clients never talk to eBay, EasyPost, or Uber directly.

**Tech Stack:** SwiftUI, Swift packages, XCTest, Next.js + TypeScript, Supabase Auth/Postgres/Storage, Python worker + pytest, eBay APIs, EasyPost, Uber Direct.

---

This plan is preserved here so implementation can stay source-aligned as the repo grows. The current scaffold implements the initial repo structure, core contracts, seed data, worker flow, admin app routes, and iOS package modules described by the plan.
