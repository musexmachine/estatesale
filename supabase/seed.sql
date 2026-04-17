insert into public.organizations (id, name, slug)
values ('11111111-1111-1111-1111-111111111111', 'North Bay Estate Ops', 'north-bay-estate-ops')
on conflict (id) do nothing;

insert into public.user_profiles (id, user_id, organization_id, email, full_name, role)
values
  ('21111111-1111-1111-1111-111111111111', '31111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'operator@example.com', 'Avery Operator', 'operator'),
  ('21111111-1111-1111-1111-111111111112', '31111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'admin@example.com', 'Jordan Admin', 'admin')
on conflict (user_id) do nothing;

insert into public.properties (id, organization_id, name, address_line1, city, state, postal_code, sale_deadline, notes, created_by)
values (
  '41111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111',
  'Marin Mid-Century Estate',
  '24 Redwood Lane',
  'San Rafael',
  'CA',
  '94901',
  '2026-04-28',
  'Prioritize artwork, hi-fi equipment, and teak furniture.',
  '21111111-1111-1111-1111-111111111112'
)
on conflict (id) do nothing;

insert into public.intake_assets (id, property_id, uploaded_by, asset_type, storage_path, original_filename, duration_seconds)
values
  ('51111111-1111-1111-1111-111111111111', '41111111-1111-1111-1111-111111111111', '21111111-1111-1111-1111-111111111111', 'walkthrough_video', 'intake-assets/marin/walkthrough-1.mov', 'walkthrough-1.mov', 83),
  ('51111111-1111-1111-1111-111111111112', '41111111-1111-1111-1111-111111111111', '21111111-1111-1111-1111-111111111111', 'photo', 'intake-assets/marin/turntable-front.jpg', 'turntable-front.jpg', null)
on conflict (id) do nothing;

insert into public.processing_jobs (id, organization_id, property_id, intake_asset_id, job_type, status, idempotency_key, payload)
values
  ('61111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', '41111111-1111-1111-1111-111111111111', '51111111-1111-1111-1111-111111111111', 'intake_pipeline', 'pending', 'walkthrough-1', '{"assetIds":["51111111-1111-1111-1111-111111111111"]}'),
  ('61111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', '41111111-1111-1111-1111-111111111111', '51111111-1111-1111-1111-111111111112', 'intake_pipeline', 'running', 'photo-1', '{"assetIds":["51111111-1111-1111-1111-111111111112"]}')
on conflict (job_type, idempotency_key) do nothing;

insert into public.candidate_items (id, property_id, intake_asset_id, state, title, category, brand, condition_summary, price_low_cents, price_high_cents, fulfillment_mode, confidence, needs_photo, risk_flags, evidence, metadata)
values
  (
    '71111111-1111-1111-1111-111111111111',
    '41111111-1111-1111-1111-111111111111',
    '51111111-1111-1111-1111-111111111112',
    'needs_review',
    'Pioneer PL-518 turntable',
    'audio',
    'Pioneer',
    'Used with light lid wear. Power-on not verified.',
    18000,
    26000,
    'shipping',
    0.91,
    false,
    array['untested'],
    '{"labelVisible":true,"powerObserved":false}',
    '{"room":"Den"}'
  ),
  (
    '71111111-1111-1111-1111-111111111112',
    '41111111-1111-1111-1111-111111111111',
    '51111111-1111-1111-1111-111111111111',
    'needs_photo',
    'Teak nesting tables',
    'furniture',
    null,
    'Transcript matched item mention but hero frame is weak.',
    22000,
    34000,
    'pickup',
    0.42,
    true,
    array['needs_photo'],
    '{"transcriptMatched":true,"heroFrameSharpness":0.31}',
    '{"room":"Living Room"}'
  )
on conflict (id) do nothing;

insert into public.item_images (id, candidate_item_id, storage_path, angle, quality_score, is_primary)
values
  ('81111111-1111-1111-1111-111111111111', '71111111-1111-1111-1111-111111111111', 'listing-artifacts/marin/turntable-hero.jpg', 'hero', 0.96, true),
  ('81111111-1111-1111-1111-111111111112', '71111111-1111-1111-1111-111111111111', 'listing-artifacts/marin/turntable-label.jpg', 'label', 0.93, false)
on conflict (id) do nothing;

insert into public.listing_drafts (id, candidate_item_id, listing_state, title, description, shipping_profile, marketplace_payload)
values
  (
    '91111111-1111-1111-1111-111111111111',
    '71111111-1111-1111-1111-111111111111',
    'ready_to_publish',
    'Pioneer PL-518 Direct Drive Turntable',
    'Vintage Pioneer turntable from a Marin estate. Cosmetic wear on the dust cover. Sold as untested.',
    '{"packagePreset":"medium_turntable","mode":"shipping"}',
    '{"marketplace":"ebay","conditionCode":"3000"}'
  )
on conflict (candidate_item_id) do nothing;

insert into public.channel_listings (id, listing_draft_id, provider, provider_listing_id, status, external_url, payload_snapshot, last_synced_at)
values
  (
    'a1111111-1111-1111-1111-111111111111',
    '91111111-1111-1111-1111-111111111111',
    'ebay',
    'EBY-1001',
    'published',
    'https://www.ebay.com/itm/EBY-1001',
    '{"shippingEnabled":true,"facebookCrossPostEligible":true}',
    timezone('utc', now())
  )
on conflict (id) do nothing;

insert into public.orders (id, listing_draft_id, provider, provider_order_id, buyer_name, buyer_email, buyer_phone, shipping_address, state, fulfillment_mode, sale_price_cents)
values
  (
    'b1111111-1111-1111-1111-111111111111',
    '91111111-1111-1111-1111-111111111111',
    'ebay',
    'EBY-ORDER-900',
    'Sam Collector',
    'sam@example.com',
    '+14155550123',
    '{"line1":"18 Pine Street","city":"Oakland","state":"CA","postalCode":"94610"}',
    'paid',
    'shipping',
    23900
  )
on conflict (id) do nothing;

insert into public.shipments (id, order_id, provider, provider_shipment_id, provider_rate_id, tracking_number, label_url, rate_snapshot, provider_snapshot, purchased_at)
values
  (
    'c1111111-1111-1111-1111-111111111111',
    'b1111111-1111-1111-1111-111111111111',
    'easypost',
    'ezp_shp_100',
    'ezp_rate_ground',
    '9400111899223847182634',
    'https://example.com/labels/ezp_shp_100.pdf',
    '{"amountCents":1895,"service":"USPS Ground Advantage"}',
    '{"provider":"easypost","mode":"test"}',
    timezone('utc', now())
  )
on conflict (order_id) do nothing;

insert into public.provider_events (id, provider, provider_event_id, entity_type, entity_id, payload, normalized_payload)
values
  (
    'd1111111-1111-1111-1111-111111111111',
    'ebay',
    'evt-ebay-order-900',
    'order',
    'EBY-ORDER-900',
    '{"event":"order.paid"}',
    '{"state":"paid"}'
  )
on conflict (provider, provider_event_id) do nothing;
