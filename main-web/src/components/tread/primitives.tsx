import { Link } from "@tanstack/react-router";
import type { LucideIcon } from "lucide-react";
import type { ReactNode } from "react";
import { ArrowRight } from "lucide-react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function Logo({ className }: { className?: string }) {
  return (
    <Link
      to="/"
      className={cn("group flex items-center gap-3", className)}
      aria-label="Edu Ride home"
    >
      <img
        src="/edu-ride-logo.jpeg"
        alt=""
        className="size-10 rounded-full object-cover transition-transform duration-300 group-hover:scale-105"
      />
      <span className="font-display text-xl font-bold tracking-tight text-foreground">
        Edu Ride
      </span>
    </Link>
  );
}

export function Eyebrow({ children, icon: Icon }: { children: ReactNode; icon?: LucideIcon }) {
  return (
    <span className="inline-flex items-center gap-2 rounded-full border border-primary/25 bg-primary/8 px-3.5 py-1.5 text-xs font-semibold tracking-[0.18em] text-primary uppercase">
      {Icon ? <Icon className="size-3.5" /> : null}
      {children}
    </span>
  );
}

export function SectionHeading({
  eyebrow,
  title,
  description,
  align = "left",
  className,
}: {
  eyebrow?: string;
  title: ReactNode;
  description?: ReactNode;
  align?: "left" | "center";
  className?: string;
}) {
  return (
    <div
      className={cn(
        "flex flex-col gap-4",
        align === "center" ? "mx-auto max-w-3xl items-center text-center" : "max-w-3xl",
        className,
      )}
    >
      {eyebrow ? <Eyebrow>{eyebrow}</Eyebrow> : null}
      <h2 className="text-balance text-3xl font-bold leading-[1.1] sm:text-4xl md:text-[2.75rem]">
        {title}
      </h2>
      {description ? (
        <p className="text-pretty text-base leading-relaxed text-muted-foreground md:text-lg">
          {description}
        </p>
      ) : null}
    </div>
  );
}

export function Section({
  id,
  children,
  className,
  muted = false,
}: {
  id?: string;
  children: ReactNode;
  className?: string;
  muted?: boolean;
}) {
  return (
    <section
      id={id}
      className={cn(
        "section-y relative scroll-mt-24",
        muted && "bg-surface-gradient border-y border-border/60",
        className,
      )}
    >
      <div className="mx-auto w-full max-w-7xl px-5 sm:px-8">{children}</div>
    </section>
  );
}

export function FeatureCard({
  icon: Icon,
  title,
  description,
  className,
}: {
  icon: LucideIcon;
  title: string;
  description: string;
  className?: string;
}) {
  return (
    <article
      className={cn(
        "panel group relative overflow-hidden p-6 transition-all duration-300 hover:-translate-y-1 hover:border-primary/40 hover:shadow-glow",
        className,
      )}
    >
      <div className="mb-5 inline-flex size-11 items-center justify-center rounded-xl border border-primary/25 bg-primary/10 text-primary transition-colors group-hover:bg-primary/18">
        <Icon className="size-5" />
      </div>
      <h3 className="text-lg font-semibold">{title}</h3>
      <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{description}</p>
    </article>
  );
}

export function StatCard({
  label,
  value,
  hint,
  tone = "primary",
}: {
  label: string;
  value: string;
  hint?: string;
  tone?: "primary" | "signal" | "alert";
}) {
  const toneClass =
    tone === "signal" ? "text-signal" : tone === "alert" ? "text-alert" : "text-primary";
  return (
    <div className="rounded-xl border border-border bg-background/50 p-4">
      <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">{label}</p>
      <p className={cn("mt-2 font-display text-2xl font-bold", toneClass)}>{value}</p>
      {hint ? <p className="mt-1 text-xs text-muted-foreground">{hint}</p> : null}
    </div>
  );
}

export function AlertCard({
  title,
  message,
  time,
  tone = "primary",
  icon: Icon,
}: {
  title: string;
  message: string;
  time: string;
  tone?: "primary" | "signal" | "alert";
  icon?: LucideIcon;
}) {
  const ring =
    tone === "signal"
      ? "border-signal/35 bg-signal/8 text-signal"
      : tone === "alert"
        ? "border-alert/35 bg-alert/8 text-alert"
        : "border-primary/35 bg-primary/8 text-primary";
  return (
    <div className="flex items-start gap-3 rounded-xl border border-border bg-background/50 p-4">
      <span
        className={cn(
          "mt-0.5 inline-flex size-8 shrink-0 items-center justify-center rounded-lg border",
          ring,
        )}
      >
        {Icon ? <Icon className="size-4" /> : <ArrowRight className="size-4" />}
      </span>
      <div className="min-w-0">
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <p className="text-sm font-semibold">{title}</p>
          <span className="text-xs text-muted-foreground">{time}</span>
        </div>
        <p className="mt-1 text-sm leading-relaxed text-muted-foreground">{message}</p>
      </div>
    </div>
  );
}

export function CTASection({
  title,
  description,
  primaryLabel = "Request a Demo",
  secondaryLabel,
  secondaryTo,
}: {
  title: string;
  description: string;
  primaryLabel?: string;
  secondaryLabel?: string;
  secondaryTo?: "/how-it-works" | "/technology" | "/schools" | "/features" | "/about";
}) {
  return (
    <Section>
      <div className="panel bg-hero-glow relative overflow-hidden px-6 py-14 text-center md:px-16 md:py-20">
        <div
          className="bg-grid pointer-events-none absolute inset-0 opacity-40"
          aria-hidden="true"
        />
        <div className="relative mx-auto max-w-2xl">
          <h2 className="text-balance text-3xl font-bold leading-tight sm:text-4xl">{title}</h2>
          <p className="mt-4 text-pretty text-muted-foreground md:text-lg">{description}</p>
          <div className="mt-8 flex flex-wrap justify-center gap-3">
            <Button asChild variant="hero" size="lg">
              <a href="#contact">
                {primaryLabel}
                <ArrowRight />
              </a>
            </Button>
            {secondaryLabel && secondaryTo ? (
              <Button asChild variant="outlineGlow" size="lg">
                <Link to={secondaryTo}>{secondaryLabel}</Link>
              </Button>
            ) : null}
          </div>
        </div>
      </div>
    </Section>
  );
}

export function BulletList({ items }: { items: string[] }) {
  return (
    <ul className="grid gap-3 sm:grid-cols-2">
      {items.map((item) => (
        <li key={item} className="flex items-start gap-3 text-sm text-muted-foreground">
          <span
            className="mt-1.5 size-2 shrink-0 rounded-full bg-accent-gradient"
            aria-hidden="true"
          />
          <span className="text-foreground/90">{item}</span>
        </li>
      ))}
    </ul>
  );
}
