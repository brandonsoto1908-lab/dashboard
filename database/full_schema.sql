-- ==============================
-- Full database schema (executable)
-- Run this in Supabase -> SQL Editor or any Postgres client
-- ==============================

-- Enable required extension for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------
-- Table: users
-- ------------------------------
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------
-- Table: transactions
-- ------------------------------
CREATE TABLE IF NOT EXISTS transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(10) CHECK (type IN ('income','expense')) NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  category VARCHAR(100) NOT NULL,
  description TEXT,
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------
-- Table: categories (optional)
-- ------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  type VARCHAR(10) CHECK (type IN ('income','expense')) NOT NULL,
  color VARCHAR(7) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------
-- Table: fixed_expenses
-- ------------------------------
CREATE TABLE IF NOT EXISTS fixed_expenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  category VARCHAR(100) NOT NULL,
  description TEXT,
  due_day INTEGER NOT NULL CHECK (due_day >= 1 AND due_day <= 31),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------
-- Table: fixed_expense_payments
-- ------------------------------
CREATE TABLE IF NOT EXISTS fixed_expense_payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fixed_expense_id UUID REFERENCES fixed_expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2000),
  paid_amount DECIMAL(12,2) NOT NULL CHECK (paid_amount > 0),
  paid_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(fixed_expense_id, month, year)
);

-- ------------------------------
-- Table: accounts_receivable
-- ------------------------------
CREATE TABLE IF NOT EXISTS accounts_receivable (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  debtor_name VARCHAR(255) NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  description TEXT,
  expected_date DATE,
  is_paid BOOLEAN DEFAULT false,
  paid_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------
-- Table: savings_goals
-- ------------------------------
CREATE TABLE IF NOT EXISTS savings_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  target_amount DECIMAL(12,2) NOT NULL CHECK (target_amount > 0),
  current_amount DECIMAL(12,2) DEFAULT 0 CHECK (current_amount >= 0),
  description TEXT,
  target_date DATE,
  is_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------
-- Table: savings_movements
-- ------------------------------
CREATE TABLE IF NOT EXISTS savings_movements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  savings_goal_id UUID REFERENCES savings_goals(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(10) CHECK (type IN ('deposit','withdrawal')) NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  description TEXT,
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------
-- Indexes
-- ------------------------------
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category);
CREATE INDEX IF NOT EXISTS idx_fixed_expenses_user_id ON fixed_expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_fixed_expense_payments_user_id ON fixed_expense_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_fixed_expense_payments_month_year ON fixed_expense_payments(month, year);
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_user_id ON accounts_receivable(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_is_paid ON accounts_receivable(is_paid);
CREATE INDEX IF NOT EXISTS idx_savings_goals_user_id ON savings_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_goals_is_completed ON savings_goals(is_completed);
CREATE INDEX IF NOT EXISTS idx_savings_movements_user_id ON savings_movements(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_movements_goal_id ON savings_movements(savings_goal_id);

-- ------------------------------
-- Default categories (safe to run multiple times)
-- ------------------------------
INSERT INTO categories (name, type, color)
VALUES
  ('Salario', 'income', '#22c55e'),
  ('Freelance', 'income', '#3b82f6'),
  ('Inversiones', 'income', '#8b5cf6'),
  ('Bonos', 'income', '#06b6d4'),
  ('Otros ingresos', 'income', '#84cc16')
ON CONFLICT (name) DO NOTHING;

INSERT INTO categories (name, type, color)
VALUES
  ('Comida', 'expense', '#ef4444'),
  ('Transporte', 'expense', '#f97316'),
  ('Entretenimiento', 'expense', '#ec4899'),
  ('Salud', 'expense', '#14b8a6'),
  ('Servicios', 'expense', '#6366f1'),
  ('Compras', 'expense', '#f59e0b'),
  ('Otros gastos', 'expense', '#64748b')
ON CONFLICT (name) DO NOTHING;

-- ------------------------------
-- Row Level Security (RLS) and simple policies for development
-- NOTE: In production you should create proper policies tied to auth.
-- ------------------------------
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixed_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixed_expense_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts_receivable ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations on users" ON users
  FOR ALL USING (true);

CREATE POLICY "Allow all operations on transactions" ON transactions
  FOR ALL USING (true);

CREATE POLICY "Allow all operations on categories" ON categories
  FOR ALL USING (true);

CREATE POLICY "Allow all operations on fixed_expenses" ON fixed_expenses
  FOR ALL USING (true);

CREATE POLICY "Allow all operations on fixed_expense_payments" ON fixed_expense_payments
  FOR ALL USING (true);

CREATE POLICY "Allow all operations on accounts_receivable" ON accounts_receivable
  FOR ALL USING (true);

CREATE POLICY "Allow all operations on savings_goals" ON savings_goals
  FOR ALL USING (true);

CREATE POLICY "Allow all operations on savings_movements" ON savings_movements
  FOR ALL USING (true);

-- ------------------------------
-- Optional: demo user (safe: ON CONFLICT DO NOTHING)
-- Replace or remove in production
-- ------------------------------
INSERT INTO users (id, name, email)
VALUES ('123e4567-e89b-12d3-a456-426614174000', 'Demo User', 'demo@example.com')
ON CONFLICT (id) DO NOTHING;

-- Done
SELECT 'OK: full_schema applied' AS result;
