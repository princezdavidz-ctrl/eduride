import { Bus, MapPin, Navigation } from "lucide-react";

import { cn } from "@/lib/utils";

export type MapStop = { id: string; label: string; x: number; y: number; done?: boolean };

const DEFAULT_STOPS: MapStop[] = [
  { id: "depot", label: "Depot", x: 44, y: 232, done: true },
  { id: "westlands", label: "Westlands", x: 152, y: 168, done: true },
  { id: "riverside", label: "Riverside", x: 268, y: 196 },
  { id: "school", label: "School", x: 396, y: 96 },
];

const ROUTE_PATH =
  "M44 232 C 96 224, 118 186, 152 168 C 200 142, 226 200, 268 196 C 320 190, 342 122, 396 96";

/**
 * Mock map visual. Demo geometry only — replace the path/stops with data from
 * the Edu Ride tracking API when the backend is connected.
 */
export function MapPreview({
  stops = DEFAULT_STOPS,
  className,
  busPosition = { x: 268, y: 196 },
  compact = false,
}: {
  stops?: MapStop[];
  className?: string;
  busPosition?: { x: number; y: number };
  compact?: boolean;
}) {
  return (
    <div
      className={cn("panel relative overflow-hidden", compact ? "p-3" : "p-4", className)}
      role="img"
      aria-label="Demo map showing an example school bus route, stops and simulated bus position"
    >
      <div className="bg-grid pointer-events-none absolute inset-0 opacity-60" aria-hidden="true" />
      <div className="relative">
        <div className="mb-3 flex items-center justify-between gap-3">
          <span className="inline-flex items-center gap-2 text-xs font-semibold tracking-[0.16em] text-muted-foreground uppercase">
            <Navigation className="size-3.5 text-primary" />
            Demo route · 042
          </span>
          <span className="inline-flex items-center gap-2 rounded-full border border-signal/30 bg-signal/10 px-2.5 py-1 text-xs font-medium text-signal">
            <span className="size-1.5 rounded-full bg-signal" />
            Example
          </span>
        </div>

        <svg viewBox="0 0 440 280" className="h-auto w-full">
          <defs>
            <linearGradient id="route-grad" x1="0" y1="0" x2="1" y2="0">
              <stop offset="0%" stopColor="var(--color-primary)" />
              <stop offset="100%" stopColor="var(--color-signal)" />
            </linearGradient>
          </defs>

          {/* mock streets */}
          <g stroke="var(--color-border)" strokeWidth="8" strokeLinecap="round" opacity="0.7">
            <path d="M0 90 H440" />
            <path d="M0 214 H440" />
            <path d="M110 0 V280" />
            <path d="M320 0 V280" />
          </g>

          <path
            d={ROUTE_PATH}
            fill="none"
            stroke="var(--color-primary)"
            strokeWidth="10"
            opacity="0.14"
            strokeLinecap="round"
          />
          <path
            d={ROUTE_PATH}
            fill="none"
            stroke="url(#route-grad)"
            strokeWidth="3"
            strokeLinecap="round"
          />
          <path
            d={ROUTE_PATH}
            fill="none"
            stroke="var(--color-signal)"
            strokeWidth="3.5"
            strokeLinecap="round"
            strokeDasharray="10 18"
            className="animate-route-dash"
          />

          {stops.map((stop) => (
            <g key={stop.id}>
              <circle
                cx={stop.x}
                cy={stop.y}
                r="6"
                fill={stop.done ? "var(--color-signal)" : "var(--color-background)"}
                stroke={stop.done ? "var(--color-signal)" : "var(--color-primary)"}
                strokeWidth="2.5"
              />
              <text
                x={stop.x}
                y={stop.y - 14}
                textAnchor="middle"
                fontSize="11"
                fill="var(--color-muted-foreground)"
                fontFamily="var(--font-sans)"
              >
                {stop.label}
              </text>
            </g>
          ))}

          <g transform={`translate(${busPosition.x} ${busPosition.y})`}>
            <circle
              r="16"
              fill="var(--color-primary)"
              opacity="0.22"
              className="animate-ping-slow"
            />
            <circle r="13" fill="var(--color-primary)" />
          </g>
        </svg>

        <div className="mt-3 flex flex-wrap items-center gap-x-5 gap-y-2 text-xs text-muted-foreground">
          <span className="inline-flex items-center gap-1.5">
            <Bus className="size-3.5 text-primary" /> EDU RIDE BUS 042
          </span>
          <span className="inline-flex items-center gap-1.5">
            <MapPin className="size-3.5 text-signal" /> Westlands → School
          </span>
          <span>ETA 12 min</span>
        </div>
      </div>
    </div>
  );
}
