create extension if not exists pgcrypto;

create type public.app_role as enum ('operator', 'admin');
create type public.intake_asset_type as enum ('photo', 'walkthrough_video');
create type public.processing_job_type as enum ('intake_pipeline', 'ebay_publish', 'easypost_purchase_label', 'uber_dispatch', 'pickup_schedule');
create type public.processing_job_status as enum ('pending', 'running', 'succeeded', 'failed', 'dead_letter');
create type public.candidate_item_state as enum ('needs_review', 'approved', 'rejected', 'grouped', 'needs_photo');
create type public.listing_state as enum ('draft', 'ready_to_publish', 'published', 'sold', 'delisted', 'failed', 'stale_pending');
create type public.fulfillment_mode as enum ('shipping', 'local_delivery', 'pickup');
create type public.order_state as enum ('awaiting_payment', 'paid', 'fulfillment_pending', 'shipped', 'courier_dispatched', 'pickup_scheduled', 'delivered', 'completed', 'return_requested', 'returned', 'refunded');
create type public.provider_kind as enum ('ebay', 'easypost', 'uber_direct');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  email text not null,
  full_name text not null,
  role public.app_role not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.current_user_role()
returns public.app_role
language sql
stable
as $$
  select role
  from public.user_profiles
  where user_id = auth.uid()
  limit 1
$$;

create or replace function public.current_user_organization_id()
returns uuid
language sql
stable
as $$
  select organization_id
  from public.user_profiles
  where user_id = auth.uid()
  limit 1
$$;

create table public.properties (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  address_line1 text not null,
  city text not null,
  state text not null,
  postal_code text not null,
  sale_deadline date,
  notes text,
  created_by uuid references public.user_profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.intake_assets (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  uploaded_by uuid references public.user_profiles(id),
  asset_type public.intake_asset_type not null,
  storage_path text not null,
  original_filename text not null,
  duration_seconds integer,
  upload_status text not null default 'uploaded',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.processing_jobs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid references public.properties(id) on delete cascade,
  intake_asset_id uuid references public.intake_assets(id) on delete cascade,
  job_type public.processing_job_type not null,
  status public.processing_job_status not null default 'pending',
  idempotency_key text not null,
  priority integer not null default 100,
  attempt_count integer not null default 0,
  max_attempts integer not null default 5,
  available_at timestamptz not null default timezone('utc', now()),
  locked_at timestamptz,
  locked_by text,
  last_error text,
  payload jsonb not null default '{}'::jsonb,
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (job_type, idempotency_key)
);

create table public.candidate_groups (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  title text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.candidate_items (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  intake_asset_id uuid references public.intake_assets(id) on delete set null,
  group_id uuid references public.candidate_groups(id) on delete set null,
  state public.candidate_item_state not null default 'needs_review',
  title text not null,
  category text not null,
  brand text,
  condition_summary text,
  price_low_cents integer not null default 0,
  price_high_cents integer not null default 0,
  fulfillment_mode public.fulfillment_mode,
  confidence numeric(4, 3) not null default 0,
  needs_photo boolean not null default false,
  risk_flags text[] not null default '{}',
  evidence jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.item_images (
  id uuid primary key default gen_random_uuid(),
  candidate_item_id uuid not null references public.candidate_items(id) on delete cascade,
  storage_path text not null,
  angle text not null,
  quality_score numeric(5, 2) not null default 0,
  is_primary boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.listing_drafts (
  id uuid primary key default gen_random_uuid(),
  candidate_item_id uuid not null unique references public.candidate_items(id) on delete cascade,
  listing_state public.listing_state not null default 'draft',
  title text not null,
  description text not null,
  shipping_profile jsonb not null default '{}'::jsonb,
  marketplace_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.channel_listings (
  id uuid primary key default gen_random_uuid(),
  listing_draft_id uuid not null references public.listing_drafts(id) on delete cascade,
  provider public.provider_kind not null,
  provider_listing_id text,
  status public.listing_state not null default 'draft',
  external_url text,
  payload_snapshot jsonb not null default '{}'::jsonb,
  last_synced_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  listing_draft_id uuid not null references public.listing_drafts(id) on delete cascade,
  provider public.provider_kind not null,
  provider_order_id text,
  buyer_name text not null,
  buyer_email text,
  buyer_phone text,
  shipping_address jsonb not null default '{}'::jsonb,
  state public.order_state not null default 'awaiting_payment',
  fulfillment_mode public.fulfillment_mode not null,
  sale_price_cents integer not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.shipments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  provider public.provider_kind not null default 'easypost',
  provider_shipment_id text,
  provider_rate_id text,
  tracking_number text,
  label_url text,
  rate_snapshot jsonb not null default '{}'::jsonb,
  provider_snapshot jsonb not null default '{}'::jsonb,
  purchased_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.courier_deliveries (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  provider public.provider_kind not null default 'uber_direct',
  provider_delivery_id text,
  tracking_url text,
  proof_policy jsonb not null default '{}'::jsonb,
  fee_snapshot jsonb not null default '{}'::jsonb,
  status text not null default 'quoted',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.pickup_appointments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  scheduled_for timestamptz not null,
  pickup_code text not null,
  instructions text not null,
  released_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.provider_events (
  id uuid primary key default gen_random_uuid(),
  provider public.provider_kind not null,
  provider_event_id text not null,
  entity_type text not null,
  entity_id text,
  payload jsonb not null default '{}'::jsonb,
  normalized_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  unique (provider, provider_event_id)
);

create table public.workflow_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index processing_jobs_status_available_idx on public.processing_jobs(status, available_at);
create index candidate_items_property_state_idx on public.candidate_items(property_id, state);
create index channel_listings_listing_provider_idx on public.channel_listings(listing_draft_id, provider);
create index provider_events_provider_entity_idx on public.provider_events(provider, entity_type, entity_id);

create trigger set_organizations_updated_at before update on public.organizations for each row execute function public.set_updated_at();
create trigger set_user_profiles_updated_at before update on public.user_profiles for each row execute function public.set_updated_at();
create trigger set_properties_updated_at before update on public.properties for each row execute function public.set_updated_at();
create trigger set_intake_assets_updated_at before update on public.intake_assets for each row execute function public.set_updated_at();
create trigger set_processing_jobs_updated_at before update on public.processing_jobs for each row execute function public.set_updated_at();
create trigger set_candidate_groups_updated_at before update on public.candidate_groups for each row execute function public.set_updated_at();
create trigger set_candidate_items_updated_at before update on public.candidate_items for each row execute function public.set_updated_at();
create trigger set_listing_drafts_updated_at before update on public.listing_drafts for each row execute function public.set_updated_at();
create trigger set_channel_listings_updated_at before update on public.channel_listings for each row execute function public.set_updated_at();
create trigger set_orders_updated_at before update on public.orders for each row execute function public.set_updated_at();
create trigger set_shipments_updated_at before update on public.shipments for each row execute function public.set_updated_at();
create trigger set_courier_deliveries_updated_at before update on public.courier_deliveries for each row execute function public.set_updated_at();
create trigger set_pickup_appointments_updated_at before update on public.pickup_appointments for each row execute function public.set_updated_at();

alter table public.organizations enable row level security;
alter table public.user_profiles enable row level security;
alter table public.properties enable row level security;
alter table public.intake_assets enable row level security;
alter table public.processing_jobs enable row level security;
alter table public.candidate_groups enable row level security;
alter table public.candidate_items enable row level security;
alter table public.item_images enable row level security;
alter table public.listing_drafts enable row level security;
alter table public.channel_listings enable row level security;
alter table public.orders enable row level security;
alter table public.shipments enable row level security;
alter table public.courier_deliveries enable row level security;
alter table public.pickup_appointments enable row level security;
alter table public.provider_events enable row level security;
alter table public.workflow_events enable row level security;

create policy "organization members can read their organization"
on public.organizations
for select
using (id = public.current_user_organization_id());

create policy "admins can manage organization"
on public.organizations
for all
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

create policy "users can read own profile"
on public.user_profiles
for select
using (organization_id = public.current_user_organization_id());

create policy "admins manage profiles"
on public.user_profiles
for all
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

create policy "organization scoped select"
on public.properties
for select
using (organization_id = public.current_user_organization_id());

create policy "organization scoped manage properties"
on public.properties
for all
using (organization_id = public.current_user_organization_id())
with check (organization_id = public.current_user_organization_id());

create policy "organization scoped intake assets"
on public.intake_assets
for all
using (
  exists (
    select 1
    from public.properties
    where properties.id = intake_assets.property_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.properties
    where properties.id = intake_assets.property_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "organization scoped processing jobs"
on public.processing_jobs
for all
using (organization_id = public.current_user_organization_id())
with check (organization_id = public.current_user_organization_id());

create policy "organization scoped candidate groups"
on public.candidate_groups
for all
using (
  exists (
    select 1
    from public.properties
    where properties.id = candidate_groups.property_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.properties
    where properties.id = candidate_groups.property_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "organization scoped candidate items"
on public.candidate_items
for all
using (
  exists (
    select 1
    from public.properties
    where properties.id = candidate_items.property_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.properties
    where properties.id = candidate_items.property_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "organization scoped item images"
on public.item_images
for all
using (
  exists (
    select 1
    from public.candidate_items
    join public.properties on properties.id = candidate_items.property_id
    where candidate_items.id = item_images.candidate_item_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.candidate_items
    join public.properties on properties.id = candidate_items.property_id
    where candidate_items.id = item_images.candidate_item_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "organization scoped drafts"
on public.listing_drafts
for all
using (
  exists (
    select 1
    from public.candidate_items
    join public.properties on properties.id = candidate_items.property_id
    where candidate_items.id = listing_drafts.candidate_item_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.candidate_items
    join public.properties on properties.id = candidate_items.property_id
    where candidate_items.id = listing_drafts.candidate_item_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "organization scoped channel listings"
on public.channel_listings
for all
using (
  exists (
    select 1
    from public.listing_drafts
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where listing_drafts.id = channel_listings.listing_draft_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.listing_drafts
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where listing_drafts.id = channel_listings.listing_draft_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "organization scoped orders"
on public.orders
for all
using (
  exists (
    select 1
    from public.listing_drafts
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where listing_drafts.id = orders.listing_draft_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.listing_drafts
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where listing_drafts.id = orders.listing_draft_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "organization scoped shipments"
on public.shipments
for all
using (
  exists (
    select 1
    from public.orders
    join public.listing_drafts on listing_drafts.id = orders.listing_draft_id
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where orders.id = shipments.order_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.orders
    join public.listing_drafts on listing_drafts.id = orders.listing_draft_id
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where orders.id = shipments.order_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "organization scoped courier deliveries"
on public.courier_deliveries
for all
using (
  exists (
    select 1
    from public.orders
    join public.listing_drafts on listing_drafts.id = orders.listing_draft_id
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where orders.id = courier_deliveries.order_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.orders
    join public.listing_drafts on listing_drafts.id = orders.listing_draft_id
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where orders.id = courier_deliveries.order_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "organization scoped pickup appointments"
on public.pickup_appointments
for all
using (
  exists (
    select 1
    from public.orders
    join public.listing_drafts on listing_drafts.id = orders.listing_draft_id
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where orders.id = pickup_appointments.order_id
      and properties.organization_id = public.current_user_organization_id()
  )
)
with check (
  exists (
    select 1
    from public.orders
    join public.listing_drafts on listing_drafts.id = orders.listing_draft_id
    join public.candidate_items on candidate_items.id = listing_drafts.candidate_item_id
    join public.properties on properties.id = candidate_items.property_id
    where orders.id = pickup_appointments.order_id
      and properties.organization_id = public.current_user_organization_id()
  )
);

create policy "admins can read provider events"
on public.provider_events
for select
using (public.current_user_role() = 'admin');

create policy "admins can read workflow events"
on public.workflow_events
for select
using (organization_id = public.current_user_organization_id());

insert into storage.buckets (id, name, public)
values
  ('intake-assets', 'intake-assets', false),
  ('listing-artifacts', 'listing-artifacts', false),
  ('provider-artifacts', 'provider-artifacts', false)
on conflict (id) do nothing;
