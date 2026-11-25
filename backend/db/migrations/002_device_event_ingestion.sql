CREATE TABLE IF NOT EXISTS device_events (
 id bigserial PRIMARY KEY,
 device_id uuid NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
 event_id text NOT NULL CHECK (event_id ~ '^[0-9a-f]{32}$'),
 device_sequence numeric(20,0) NOT NULL CHECK (device_sequence > 0),
 schema_version integer NOT NULL CHECK (schema_version = 1),
 event_type text NOT NULL CHECK (event_type IN ('BOOT','TRIP_STARTED','TRIP_ENDED','STUDENT_BOARDING_MATCHED','STUDENT_BOARDING_UNCERTAIN','STUDENT_BOARDING_UNMATCHED','DRIVER_PICKUP_CONFIRMED','DRIVER_NEXT_STOP','DEVICE_HEALTH','DEVICE_FAULT')),
 trip_id text,
 event_time_utc timestamptz,
 monotonic_time_us numeric(20,0) NOT NULL CHECK (monotonic_time_us >= 0),
 time_quality text NOT NULL CHECK (time_quality IN ('UNSYNCED','RTC','GNSS','NETWORK')),
 firmware_version text NOT NULL CHECK (length(firmware_version) BETWEEN 1 AND 24),
 hardware_revision text NOT NULL CHECK (length(hardware_revision) BETWEEN 1 AND 24),
 variant text NOT NULL CHECK (variant IN ('vision_gps','gps_only')),
 payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(payload) = 'object'),
 received_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(device_id,event_id),
 UNIQUE(device_id,device_sequence)
);
CREATE INDEX IF NOT EXISTS device_events_trip_idx ON device_events(trip_id,received_at DESC);
CREATE INDEX IF NOT EXISTS device_events_received_idx ON device_events(device_id,received_at DESC);
