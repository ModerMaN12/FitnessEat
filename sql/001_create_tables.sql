-- Eat Fitness: Database migration for user data sync
-- Run this in Supabase SQL Editor (https://supabase.com/dashboard/project/idpnrztaoprjhpscysio/sql/new)

-- 1. foods
create table if not exists foods (
  id text primary key,
  user_id uuid references auth.users not null,
  name text not null,
  image_url text,
  calories double precision not null default 0,
  proteins double precision not null default 0,
  fats double precision not null default 0,
  carbs double precision not null default 0,
  is_per_100g boolean default true,
  is_composite boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. meals
create table if not exists meals (
  id text primary key,
  user_id uuid references auth.users not null,
  date timestamptz not null,
  type text not null,
  image_url text,
  total_calories double precision default 0,
  total_proteins double precision default 0,
  total_fats double precision default 0,
  total_carbs double precision default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2a. meal_items
create table if not exists meal_items (
  id uuid primary key default gen_random_uuid(),
  meal_id text references meals(id) on delete cascade not null,
  food_item_id text not null,
  grams double precision not null,
  food_name text
);

-- 3. goals (one per user)
create table if not exists goals (
  user_id uuid primary key references auth.users,
  calories double precision default 2000,
  proteins double precision default 150,
  fats double precision default 70,
  carbs double precision default 250,
  water double precision default 2000,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 4. templates
create table if not exists templates (
  id text primary key,
  user_id uuid references auth.users not null,
  name text not null,
  type text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 4a. template_items
create table if not exists template_items (
  id uuid primary key default gen_random_uuid(),
  template_id text references templates(id) on delete cascade not null,
  food_item_id text not null,
  grams double precision not null,
  food_name text
);

-- 5. water_entries
create table if not exists water_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  amount double precision not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- compound ingredients for composite dishes
create table if not exists food_ingredients (
  id uuid primary key default gen_random_uuid(),
  food_id text references foods(id) on delete cascade not null,
  ingredient_food_id text not null,
  grams double precision not null
);

-- ========== Row Level Security ==========
alter table foods enable row level security;
alter table meals enable row level security;
alter table meal_items enable row level security;
alter table goals enable row level security;
alter table templates enable row level security;
alter table template_items enable row level security;
alter table water_entries enable row level security;
alter table food_ingredients enable row level security;

-- ========== RLS Policies ==========
create policy "users can manage their own foods"
  on foods for all using (auth.uid() = user_id);

create policy "users can manage their own meals"
  on meals for all using (auth.uid() = user_id);

create policy "users can manage their meal items"
  on meal_items for all using (
    exists (select 1 from meals where meals.id = meal_items.meal_id and meals.user_id = auth.uid())
  );

create policy "users can manage their own goals"
  on goals for all using (auth.uid() = user_id);

create policy "users can manage their own templates"
  on templates for all using (auth.uid() = user_id);

create policy "users can manage their template items"
  on template_items for all using (
    exists (select 1 from templates where templates.id = template_items.template_id and templates.user_id = auth.uid())
  );

create policy "users can manage their own water entries"
  on water_entries for all using (auth.uid() = user_id);

create policy "users can manage their own food ingredients"
  on food_ingredients for all using (
    exists (select 1 from foods where foods.id = food_ingredients.food_id and foods.user_id = auth.uid())
  );

-- ========== Indexes ==========
create index if not exists idx_foods_user_id on foods(user_id);
create index if not exists idx_meals_user_id on meals(user_id);
create index if not exists idx_meals_date on meals(date);
create index if not exists idx_templates_user_id on templates(user_id);
create index if not exists idx_water_entries_user_id on water_entries(user_id);
create index if not exists idx_water_entries_date on water_entries(date);
create index if not exists idx_foods_updated_at on foods(updated_at);
create index if not exists idx_meals_updated_at on meals(updated_at);
