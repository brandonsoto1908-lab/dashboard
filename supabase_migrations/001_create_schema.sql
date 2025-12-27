BEGIN;

-- Habilita gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tabla users
CREATE TABLE IF NOT EXISTS public.users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  email text UNIQUE,
  full_name text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- Tabla accounts_receivable
CREATE TABLE IF NOT EXISTS public.accounts_receivable (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  debtor_name character varying NOT NULL,
  amount numeric NOT NULL CHECK (amount >= 0::numeric),
  reason text NOT NULL,
  expected_date date,
  is_paid boolean DEFAULT false,
  paid_date date,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT accounts_receivable_pkey PRIMARY KEY (id),
  CONSTRAINT accounts_receivable_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- Tabla fixed_expenses
CREATE TABLE IF NOT EXISTS public.fixed_expenses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  name character varying NOT NULL,
  amount numeric NOT NULL CHECK (amount >= 0::numeric),
  description text,
  due_day integer CHECK (due_day >= 1 AND due_day <= 31),
  is_paid boolean DEFAULT false,
  last_paid_date date,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fixed_expenses_pkey PRIMARY KEY (id),
  CONSTRAINT fixed_expenses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- Tabla savings_goals
CREATE TABLE IF NOT EXISTS public.savings_goals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  name character varying NOT NULL,
  target_amount numeric NOT NULL CHECK (target_amount >= 0::numeric),
  current_amount numeric DEFAULT 0 CHECK (current_amount >= 0::numeric),
  target_date date,
  description text,
  is_completed boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT savings_goals_pkey PRIMARY KEY (id),
  CONSTRAINT savings_goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- Tabla savings_transactions
CREATE TABLE IF NOT EXISTS public.savings_transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  savings_goal_id uuid,
  type character varying NOT NULL CHECK (type::text = ANY (ARRAY['deposit'::character varying, 'withdrawal'::character varying]::text[])),
  amount numeric NOT NULL CHECK (amount >= 0::numeric),
  description text,
  date date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT savings_transactions_pkey PRIMARY KEY (id),
  CONSTRAINT savings_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT savings_transactions_savings_goal_id_fkey FOREIGN KEY (savings_goal_id) REFERENCES public.savings_goals(id)
);

-- Tabla transactions
CREATE TABLE IF NOT EXISTS public.transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  type character varying NOT NULL CHECK (type::text = ANY (ARRAY['income'::character varying, 'expense'::character varying]::text[])),
  amount numeric NOT NULL CHECK (amount >= 0::numeric),
  category character varying,
  description text,
  date date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT transactions_pkey PRIMARY KEY (id),
  CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- Índices recomendados para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_user_id ON public.accounts_receivable(user_id);
CREATE INDEX IF NOT EXISTS idx_fixed_expenses_user_id ON public.fixed_expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_goals_user_id ON public.savings_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_transactions_user_id ON public.savings_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_transactions_goal_id ON public.savings_transactions(savings_goal_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id_date ON public.transactions(user_id, date);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(date);

COMMIT;

-- NOTAS RÁPIDAS
-- 1) Supabase maneja autenticación en el esquema auth; si tu código espera una tabla "profiles" o columnas adicionales
--    (ej. user metadata), crea esa tabla o sincronízala con auth.users.
-- 2) Revisa si necesitas ON DELETE CASCADE para algunas FK (por ejemplo si al borrar un usuario quieres eliminar sus datos).
-- 3) Considera añadir columnas updated_at o triggers si necesitas controlar actualizaciones.
-- 4) Si el proyecto usa categorías fijas (ej. tabla categories) o settings por usuario, añade esas tablas según el código.
