import { Link } from "@tanstack/react-router";
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  BellRing,
  Bus,
  Building2,
  Clock,
  Cloud,
  Cpu,
  Database,
  Eye,
  Gauge,
  History,
  KeyRound,
  LayoutDashboard,
  Lock,
  MapPin,
  MessageSquare,
  Radio,
  Route as RouteIcon,
  Satellite,
  ShieldCheck,
  Signal,
  Smartphone,
  Timer,
  Users,
  Wifi,
  Zap,
} from "lucide-react";

import { MapPreview } from "@/components/tread/map-preview";
import {
  AlertCard,
  BulletList,
  Eyebrow,
  FeatureCard,
  Section,
  SectionHeading,
  StatCard,
} from "@/components/tread/primitives";
import { Button } from "@/components/ui/button";

/* ------------------------------- Trust strip ------------------------------ */

const TRUST_ITEMS = [
  { icon: Eye, label: "Real-time visibility" },
  { icon: Satellite, label: "Smart tracking" },
  { icon: BellRing, label: "School-to-family updates" },
  { icon: History, label: "Journey history" },
  { icon: ShieldCheck, label: "School safety" },
];

export function TrustStrip() {
  return (
    <div className="border-y border-border/70 bg-surface-gradient py-6">
      <div className="mx-auto flex w-full max-w-7xl flex-wrap items-center justify-center gap-x-10 gap-y-4 px-5 sm:px-8">
        {TRUST_ITEMS.map(({ icon: Icon, label }) => (
          <span
            key={label}
            className="inline-flex items-center gap-2.5 text-sm font-medium text-muted-foreground"
          >
            <Icon className="size-4 text-primary" />
            {label}
          </span>
        ))}
      </div>
    </div>
  );
}

/* ------------------------------ How it works ------------------------------ */

const STEPS = [
  {
    n: "01",
    title: "Connect",
    icon: Cpu,
    text: "A compact Edu Ride tracking device is installed in the school bus.",
  },
  {
    n: "02",
    title: "Track",
    icon: Satellite,
    text: "The device collects location and journey information.",
  },
  {
    n: "03",
    title: "Process",
    icon: Cloud,
    text: "Data is securely transmitted to the Edu Ride cloud platform.",
  },
  {
    n: "04",
    title: "Notify",
    icon: BellRing,
    text: "Schools share relevant journey alerts with families through SMS and app notifications.",
  },
];

const FLOW = [
  { label: "Bus device", icon: Cpu },
  { label: "Network", icon: Signal },
  { label: "Edu Ride server", icon: Cloud },
  { label: "School / Family updates", icon: Users },
];

export function HowItWorks({ withHeaderSpacing = false }: { withHeaderSpacing?: boolean }) {
  return (
    <Section id="how-it-works" className={withHeaderSpacing ? "pt-16 md:pt-24" : undefined}>
      <SectionHeading
        align="center"
        eyebrow="How Edu Ride works"
        title="Four steps from bus to notification"
        description="A simple, repeatable flow designed for daily school operations."
      />

      <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {STEPS.map(({ n, title, text, icon: Icon }) => (
          <article
            key={n}
            className="panel group relative overflow-hidden p-6 transition-all duration-300 hover:-translate-y-1 hover:border-primary/40"
          >
            <span className="font-display text-4xl font-bold text-primary/25">{n}</span>
            <div className="mt-4 inline-flex size-10 items-center justify-center rounded-xl border border-primary/25 bg-primary/10 text-primary">
              <Icon className="size-5" />
            </div>
            <h3 className="mt-4 text-lg font-semibold tracking-wide uppercase">{title}</h3>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{text}</p>
          </article>
        ))}
      </div>

      <div className="panel mt-8 overflow-hidden p-6 md:p-8">
        <p className="text-xs font-semibold tracking-[0.2em] text-muted-foreground uppercase">
          Journey data flow
        </p>
        <div className="mt-6 flex flex-col items-stretch gap-3 md:flex-row md:items-center">
          {FLOW.map(({ label, icon: Icon }, i) => (
            <div key={label} className="flex flex-1 items-center gap-3">
              <div className="flex flex-1 items-center gap-3 rounded-xl border border-border bg-background/50 px-4 py-3">
                <Icon className="size-4 shrink-0 text-primary" />
                <span className="text-sm font-medium">{label}</span>
              </div>
              {i < FLOW.length - 1 ? (
                <ArrowRight className="size-4 shrink-0 rotate-90 text-primary/60 md:rotate-0" />
              ) : null}
            </div>
          ))}
        </div>
      </div>
    </Section>
  );
}

/* ---------------------------- Technology section -------------------------- */

const TECH_STACK = [
  { icon: Cpu, label: "Custom-coded PCB" },
  { icon: Satellite, label: "GPS / GNSS" },
  { icon: Radio, label: "Cellular communication" },
  { icon: Cloud, label: "Cloud server" },
  { icon: KeyRound, label: "Secure APIs" },
  { icon: Activity, label: "Real-time tracking" },
  { icon: MessageSquare, label: "SMS notifications" },
  { icon: LayoutDashboard, label: "Web dashboard" },
  { icon: Smartphone, label: "Mobile application" },
  { icon: History, label: "Journey logging" },
];

const DIAGRAM = [
  { label: "Edu Ride device", icon: Cpu, note: "Coded controller inside the bus" },
  { label: "GPS + Sensors", icon: Satellite, note: "Position and journey signals" },
  { label: "Cellular Network", icon: Radio, note: "Mobile data transmission" },
  { label: "Secure API", icon: KeyRound, note: "Authenticated data intake" },
  { label: "Cloud Server", icon: Database, note: "Storage and processing" },
  { label: "Edu Ride platform", icon: LayoutDashboard, note: "Dashboards and alerts" },
  { label: "School teams / Families", icon: Users, note: "Operations and school-managed updates" },
];

export function TechnologySection({ withHeaderSpacing = false }: { withHeaderSpacing?: boolean }) {
  return (
    <Section id="technology" muted className={withHeaderSpacing ? "pt-16 md:pt-24" : undefined}>
      <SectionHeading
        eyebrow="Technology"
        title="Built on connected technology."
        description="Edu Ride brings hardware, connectivity, cloud infrastructure and communication together into one transport safety platform."
      />

      <div className="mt-12 grid gap-8 lg:grid-cols-[1fr_1.05fr] lg:items-start">
        <div className="grid gap-3 sm:grid-cols-2">
          {TECH_STACK.map(({ icon: Icon, label }) => (
            <div
              key={label}
              className="flex items-center gap-3 rounded-xl border border-border bg-background/40 px-4 py-3.5 transition-colors hover:border-primary/40"
            >
              <Icon className="size-4 shrink-0 text-primary" />
              <span className="text-sm font-medium">{label}</span>
            </div>
          ))}
        </div>

        <div className="panel p-6 md:p-8">
          <p className="text-xs font-semibold tracking-[0.2em] text-muted-foreground uppercase">
            Platform architecture
          </p>
          <ol className="mt-6 space-y-2">
            {DIAGRAM.map(({ label, icon: Icon, note }, i) => (
              <li key={label}>
                <div className="flex items-center gap-4 rounded-xl border border-border bg-background/50 p-4">
                  <span className="inline-flex size-9 shrink-0 items-center justify-center rounded-lg bg-accent-gradient text-primary-foreground">
                    <Icon className="size-4" />
                  </span>
                  <div>
                    <p className="text-sm font-semibold">{label}</p>
                    <p className="text-xs text-muted-foreground">{note}</p>
                  </div>
                </div>
                {i < DIAGRAM.length - 1 ? (
                  <div className="ml-8 h-4 w-px bg-primary/40" aria-hidden="true" />
                ) : null}
              </li>
            ))}
          </ol>
        </div>
      </div>
    </Section>
  );
}

/* ----------------------------- Features section --------------------------- */

const FEATURES = [
  {
    icon: Bus,
    title: "Bus location tracking",
    description: "Give authorized school teams visibility into registered buses.",
  },
  {
    icon: MapPin,
    title: "Arrival notifications",
    description: "Record arrivals at designated stops and notify the right people.",
  },
  {
    icon: BellRing,
    title: "Family communications",
    description: "Let schools send relevant journey updates to families through SMS and app channels.",
  },
  {
    icon: RouteIcon,
    title: "Route monitoring",
    description: "Monitor planned and actual routes.",
  },
  {
    icon: History,
    title: "Journey history",
    description: "Review previous journeys and transportation activity.",
  },
  {
    icon: LayoutDashboard,
    title: "School dashboard",
    description: "Give administrators a centralized view of their transport fleet.",
  },
  {
    icon: Wifi,
    title: "Device monitoring",
    description: "Monitor the status and connectivity of installed tracking devices.",
  },
];

export function FeaturesSection({ withHeaderSpacing = false }: { withHeaderSpacing?: boolean }) {
  return (
    <Section id="features" className={withHeaderSpacing ? "pt-16 md:pt-24" : undefined}>
      <SectionHeading
        align="center"
        eyebrow="Services"
        title="School transport services in one connected platform"
        description="Tools for schools and transport operators to monitor vehicles, manage routes, keep journey records and coordinate school-approved family updates."
      />
      <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {FEATURES.map((f) => (
          <FeatureCard key={f.title} {...f} />
        ))}
      </div>
    </Section>
  );
}

/* --------------------------- School dashboard ---------------------------- */

const DASH_ALERTS = [
  {
    title: "Arrival confirmed",
    message: "EDU RIDE BUS 017 reached Greenfield Campus.",
    time: "7:38 AM",
    tone: "signal" as const,
    icon: MapPin,
  },
  {
    title: "Delay detected",
    message: "EDU RIDE BUS 042 is running 6 minutes behind schedule on Route West.",
    time: "7:31 AM",
    tone: "alert" as const,
    icon: Timer,
  },
  {
    title: "Device reconnected",
    message: "Device on EDU RIDE BUS 023 restored connectivity.",
    time: "7:12 AM",
    tone: "primary" as const,
    icon: Wifi,
  },
];

const CHART_DATA = [
  { day: "Mon", value: 82 },
  { day: "Tue", value: 91 },
  { day: "Wed", value: 74 },
  { day: "Thu", value: 96 },
  { day: "Fri", value: 88 },
];

export function SchoolDashboardSection({
  withHeaderSpacing = false,
}: {
  withHeaderSpacing?: boolean;
}) {
  return (
    <Section id="schools" className={withHeaderSpacing ? "pt-16 md:pt-24" : undefined}>
      <SectionHeading
        eyebrow="For schools"
        title="One platform for smarter school transport."
        description="Administrators get a live operational view of their fleet, plus the records they need after the journey ends."
      />

      <div className="mt-12 grid gap-5 lg:grid-cols-3">
        <div className="panel p-6 lg:col-span-2">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <p className="font-display text-lg font-semibold">Fleet overview</p>
            <span className="text-xs text-muted-foreground">Demo data · today</span>
          </div>
          <div className="mt-5 grid gap-3 sm:grid-cols-3 lg:grid-cols-5">
            <StatCard label="Active buses" value="24" />
            <StatCard label="On route" value="18" tone="signal" />
            <StatCard label="Arrivals" value="11" tone="signal" />
            <StatCard label="Delays" value="2" tone="alert" />
            <StatCard label="Devices online" value="23/24" />
          </div>

          <div className="mt-6 grid gap-5 md:grid-cols-2">
            <div className="rounded-xl border border-border bg-background/40 p-5">
              <p className="text-xs font-semibold tracking-[0.18em] text-muted-foreground uppercase">
                On-time journeys
              </p>
              <div className="mt-6 flex h-32 items-end gap-3">
                {CHART_DATA.map((d) => (
                  <div key={d.day} className="flex flex-1 flex-col items-center gap-2">
                    <div
                      className="w-full rounded-t-md bg-accent-gradient transition-all"
                      style={{ height: `${d.value}%` }}
                      aria-hidden="true"
                    />
                    <span className="text-xs text-muted-foreground">{d.day}</span>
                  </div>
                ))}
              </div>
              <p className="mt-3 text-xs text-muted-foreground">
                Illustrative on-time percentage per weekday.
              </p>
            </div>
            <MapPreview compact />
          </div>
        </div>

        <div className="panel p-6">
          <p className="font-display text-lg font-semibold">Recent alerts</p>
          <div className="mt-5 grid gap-3">
            {DASH_ALERTS.map((a) => (
              <AlertCard key={a.title} {...a} />
            ))}
          </div>
          <div className="mt-5 rounded-xl border border-border bg-background/40 p-4">
            <p className="text-xs font-semibold tracking-[0.18em] text-muted-foreground uppercase">
              Journey history
            </p>
            <ul className="mt-3 space-y-2 text-sm text-muted-foreground">
              <li className="flex justify-between gap-3">
                <span>Route West · AM</span>
                <span className="text-signal">Completed</span>
              </li>
              <li className="flex justify-between gap-3">
                <span>Route North · AM</span>
                <span className="text-signal">Completed</span>
              </li>
              <li className="flex justify-between gap-3">
                <span>Route East · PM</span>
                <span className="text-primary">Scheduled</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </Section>
  );
}

/* ---------------------------- For schools benefits ------------------------ */

const SCHOOL_BENEFITS = [
  { icon: Eye, title: "Fleet visibility", description: "See every registered bus in one view." },
  {
    icon: Gauge,
    title: "Driver & vehicle monitoring",
    description: "Follow assigned vehicles and journey activity.",
  },
  { icon: RouteIcon, title: "Route management", description: "Compare planned and actual routes." },
  { icon: History, title: "Journey records", description: "Keep a reviewable transport log." },
  {
    icon: MessageSquare,
    title: "School-managed family updates",
    description: "Send consistent journey updates through configured channels.",
  },
  {
    icon: Building2,
    title: "Centralized administration",
    description: "Manage buses, routes and users in one place.",
  },
  {
    icon: BellRing,
    title: "Alerts and notifications",
    description: "Escalate delays and arrivals quickly.",
  },
];

export function ForSchoolsSection() {
  return (
    <Section muted>
      <SectionHeading
        align="center"
        eyebrow="School benefits"
        title="Built for the people running school transport"
        description="Edu Ride supports the daily operational reality of school transport teams."
      />
      <div className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {SCHOOL_BENEFITS.map((b) => (
          <FeatureCard key={b.title} {...b} />
        ))}
      </div>
      <div className="mt-10 flex justify-center">
        <Button asChild variant="hero" size="lg">
          <a href="#contact">
            Talk to Edu Ride
            <ArrowRight />
          </a>
        </Button>
      </div>
    </Section>
  );
}

/* ------------------------------ Safety section ---------------------------- */

const SAFETY_POINTS = [
  "Transport visibility",
  "Communication",
  "Accountability",
  "Response time",
  "Journey monitoring",
  "School-to-family communication",
];

export function SafetySection() {
  return (
    <Section id="safety" muted>
      <div className="grid gap-12 lg:grid-cols-2 lg:items-center">
        <div className="relative flex items-center justify-center">
          <div className="bg-hero-glow absolute inset-0 rounded-full blur-3xl" aria-hidden="true" />
          <svg
            viewBox="0 0 320 320"
            className="relative w-full max-w-sm"
            role="img"
            aria-label="Shield and route illustration"
          >
            <defs>
              <linearGradient id="shield-grad" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0%" stopColor="var(--color-primary)" />
                <stop offset="100%" stopColor="var(--color-signal)" />
              </linearGradient>
            </defs>
            <path
              d="M160 26 268 64v92c0 66-46 110-108 138-62-28-108-72-108-138V64L160 26Z"
              fill="url(#shield-grad)"
              opacity="0.12"
            />
            <path
              d="M160 26 268 64v92c0 66-46 110-108 138-62-28-108-72-108-138V64L160 26Z"
              fill="none"
              stroke="url(#shield-grad)"
              strokeWidth="3"
            />
            <path
              d="M96 232c28-18 26-46 26-72s16-46 38-56"
              fill="none"
              stroke="var(--color-primary)"
              strokeWidth="4"
              strokeLinecap="round"
              strokeDasharray="14 16"
              className="animate-route-dash"
            />
            <circle cx="160" cy="104" r="10" fill="var(--color-signal)" />
            <circle cx="160" cy="104" r="24" fill="var(--color-signal)" opacity="0.25" className="animate-ping-slow" />
          </svg>
        </div>
        <div>
          <SectionHeading
            eyebrow="Safety"
            title="Designed around safety."
            description="Edu Ride helps schools and transport operators monitor journeys, coordinate responses and share relevant updates with families."
          />
          <div className="mt-8">
            <BulletList items={SAFETY_POINTS} />
          </div>
        </div>
      </div>
    </Section>
  );
}

/* ------------------------------ Device section ---------------------------- */

const DEVICE_PARTS = [
  { icon: Satellite, label: "GPS / GNSS", note: "Location acquisition" },
  { icon: Radio, label: "Cellular communication", note: "Data transmission" },
  { icon: Cpu, label: "Microcontroller", note: "Coded device logic" },
  { icon: Zap, label: "Power management", note: "Stable vehicle power" },
  { icon: Activity, label: "Sensors", note: "Journey signals" },
  { icon: KeyRound, label: "Secure identification", note: "Device identity" },
];

export function DeviceSection() {
  return (
    <Section id="device">
      <SectionHeading
        align="center"
        eyebrow="Edu Ride device"
        title="The compact link between bus and platform"
        description="The Edu Ride device acts as the connection between the physical school bus and the digital safety platform."
      />

      <div className="mt-12 grid gap-8 lg:grid-cols-[1.1fr_1fr] lg:items-center">
        <div className="panel bg-hero-glow relative overflow-hidden p-6 md:p-8">
          <svg viewBox="0 0 480 300" className="h-auto w-full" role="img" aria-label="Conceptual Edu Ride circuit board illustration">
            <rect x="20" y="20" width="440" height="260" rx="22" fill="var(--color-background)" opacity="0.7" />
            <rect
              x="20"
              y="20"
              width="440"
              height="260"
              rx="22"
              fill="none"
              stroke="var(--color-primary)"
              strokeOpacity="0.4"
              strokeWidth="2"
            />
            <g stroke="var(--color-primary)" strokeOpacity="0.35" strokeWidth="2" fill="none">
              <path d="M60 90h90v50h120" />
              <path d="M60 200h70v-40h100" />
              <path d="M330 90v120h70" />
              <path d="M240 60v40" />
            </g>
            <g fill="var(--color-primary)" opacity="0.8">
              {[60, 130, 200, 270, 340, 410].map((x) => (
                <circle key={x} cx={x} cy={250} r="3" />
              ))}
            </g>
            <rect x="190" y="110" width="110" height="80" rx="12" fill="var(--color-surface)" stroke="var(--color-primary)" strokeWidth="2" />
            <text x="245" y="156" textAnchor="middle" fontSize="18" fontFamily="var(--font-display)" fill="var(--color-primary)">
              Edu Ride
            </text>
            <rect x="330" y="60" width="70" height="46" rx="10" fill="var(--color-surface)" stroke="var(--color-signal)" strokeWidth="2" />
            <text x="365" y="88" textAnchor="middle" fontSize="11" fill="var(--color-signal)" fontFamily="var(--font-sans)">
              GNSS
            </text>
            <rect x="70" y="60" width="70" height="46" rx="10" fill="var(--color-surface)" stroke="var(--color-primary)" strokeWidth="2" />
            <text x="105" y="88" textAnchor="middle" fontSize="11" fill="var(--color-primary)" fontFamily="var(--font-sans)">
              LTE
            </text>
            <circle cx="365" cy="215" r="8" fill="var(--color-signal)" />
            <circle cx="365" cy="215" r="18" fill="var(--color-signal)" opacity="0.25" className="animate-ping-slow" />
          </svg>
          <p className="mt-4 text-xs text-muted-foreground">
            Conceptual illustration of the Edu Ride device layout.
          </p>
        </div>

        <div className="grid gap-3 sm:grid-cols-2">
          {DEVICE_PARTS.map(({ icon: Icon, label, note }) => (
            <div key={label} className="rounded-xl border border-border bg-background/40 p-4">
              <Icon className="size-4 text-primary" />
              <p className="mt-3 text-sm font-semibold">{label}</p>
              <p className="mt-1 text-xs text-muted-foreground">{note}</p>
            </div>
          ))}
        </div>
      </div>
    </Section>
  );
}

/* ----------------------------- Security section --------------------------- */

const SECURITY_ITEMS = [
  { icon: Lock, title: "Secure communication", description: "Data moves between device, platform and clients over encrypted channels." },
  { icon: Users, title: "Protected user accounts", description: "Accounts are authenticated before any transport data is shown." },
  { icon: KeyRound, title: "Role-based access", description: "School teams access the transport information required for their role." },
  { icon: Cloud, title: "Secure APIs", description: "Platform interfaces require authenticated, authorized requests." },
  { icon: Database, title: "Data protection", description: "Journey information is stored with access controls and retention rules." },
  { icon: Eye, title: "Controlled visibility", description: "Transportation information is shared on a need-to-know basis." },
];

export function SecuritySection() {
  return (
    <Section id="security">
      <SectionHeading
        align="center"
        eyebrow="Security & privacy"
        title="Careful with children's information"
        description="Edu Ride treats transport data as sensitive by default and limits who can see it."
      />
      <div className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {SECURITY_ITEMS.map((s) => (
          <FeatureCard key={s.title} {...s} />
        ))}
      </div>
    </Section>
  );
}
