CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE RESTRICT,
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  name text NOT NULL,
  phone text NOT NULL DEFAULT '',
  national_id text NOT NULL DEFAULT '',
  role text NOT NULL CHECK (role IN ('parent', 'driver', 'school_admin', 'transport_admin')),
  verification_status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, organization_id)
);

CREATE TABLE IF NOT EXISTS sessions (
  token_hash text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sessions_user_id_idx ON sessions(user_id);
CREATE INDEX IF NOT EXISTS sessions_expiry_idx ON sessions(expires_at);

CREATE TABLE IF NOT EXISTS schools (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  name text NOT NULL,
  address text NOT NULL DEFAULT '',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, name),
  UNIQUE (id, organization_id)
);

CREATE TABLE IF NOT EXISTS children (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id uuid NOT NULL REFERENCES schools(id) ON DELETE RESTRICT,
  name text NOT NULL,
  verification_status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, school_id)
);
CREATE INDEX IF NOT EXISTS children_parent_id_idx ON children(parent_id);
CREATE INDEX IF NOT EXISTS children_school_id_idx ON children(school_id);

CREATE TABLE IF NOT EXISTS buses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  school_id uuid,
  driver_id uuid,
  fleet_number text NOT NULL,
  registration_number text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'parked',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, fleet_number),
  UNIQUE (id, organization_id),
  UNIQUE (id, school_id),
  FOREIGN KEY (school_id, organization_id) REFERENCES schools(id, organization_id) ON DELETE RESTRICT,
  FOREIGN KEY (driver_id, organization_id) REFERENCES users(id, organization_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  school_id uuid,
  bus_id uuid,
  name text NOT NULL,
  stops jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, organization_id),
  UNIQUE (id, bus_id),
  FOREIGN KEY (school_id, organization_id) REFERENCES schools(id, organization_id) ON DELETE RESTRICT,
  FOREIGN KEY (bus_id, organization_id) REFERENCES buses(id, organization_id) ON DELETE RESTRICT,
  FOREIGN KEY (bus_id, school_id) REFERENCES buses(id, school_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS child_bus_assignments (
  child_id uuid NOT NULL,
  bus_id uuid NOT NULL,
  school_id uuid NOT NULL,
  active boolean NOT NULL DEFAULT true,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (child_id, bus_id),
  FOREIGN KEY (child_id, school_id) REFERENCES children(id, school_id) ON DELETE CASCADE,
  FOREIGN KEY (bus_id, school_id) REFERENCES buses(id, school_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS child_bus_assignments_bus_id_idx ON child_bus_assignments(bus_id);

CREATE TABLE IF NOT EXISTS journeys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  bus_id uuid NOT NULL,
  route_id uuid,
  status text NOT NULL DEFAULT 'scheduled',
  departure_at timestamptz,
  arrival_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (bus_id, organization_id) REFERENCES buses(id, organization_id) ON DELETE RESTRICT,
  FOREIGN KEY (route_id, organization_id) REFERENCES routes(id, organization_id) ON DELETE RESTRICT,
  FOREIGN KEY (route_id, bus_id) REFERENCES routes(id, bus_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  bus_id uuid,
  severity text NOT NULL DEFAULT 'info',
  title text NOT NULL,
  message text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (bus_id, organization_id) REFERENCES buses(id, organization_id) ON DELETE RESTRICT
);
CREATE TABLE IF NOT EXISTS alert_receipts (
  alert_id uuid NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  acknowledged_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (alert_id, user_id)
);

CREATE TABLE IF NOT EXISTS preferences (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  bus_id uuid NOT NULL,
  device_code text NOT NULL UNIQUE,
  token_hash text NOT NULL UNIQUE,
  variant text NOT NULL CHECK (variant IN ('vision_gps', 'gps_only')),
  active boolean NOT NULL DEFAULT true,
  last_seen_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, bus_id),
  FOREIGN KEY (bus_id, organization_id) REFERENCES buses(id, organization_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS bus_telemetry (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  bus_id uuid NOT NULL,
  latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  speed_kph double precision CHECK (speed_kph IS NULL OR speed_kph BETWEEN 0 AND 250),
  heading double precision CHECK (heading IS NULL OR heading BETWEEN 0 AND 360),
  recorded_at timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (device_id, bus_id) REFERENCES devices(id, bus_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS bus_telemetry_latest_idx ON bus_telemetry(bus_id, recorded_at DESC);
