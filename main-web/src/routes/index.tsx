import { createFileRoute } from "@tanstack/react-router";
import { ArrowRight, Clock3, Smartphone } from "lucide-react";
import { useState } from "react";

import { MapPreview } from "@/components/tread/map-preview";
import { Logo, Section } from "@/components/tread/primitives";
import { Navbar } from "@/components/tread/navbar";
import { Button } from "@/components/ui/button";
import { FeaturesSection } from "@/components/tread/sections";

// No head() here: the home route inherits title/description/og/twitter from
// __root.tsx, and ships no og:image so serve-time hosting can inject the
// project's social preview (explicit og:image or latest screenshot).
export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Edu Ride | Every School Journey, Connected" },
      {
        name: "description",
        content:
          "Edu Ride provides schools and transport operators with bus tracking, route monitoring, journey records and school-managed family notifications.",
      },
      { property: "og:title", content: "Edu Ride | Every School Journey, Connected" },
      {
        property: "og:description",
        content: "School transport services for schools and transport operators.",
      },
    ],
  }),
  component: Index,
});

function Index() {
  return (
    <div id="top" className="min-h-screen overflow-hidden bg-background">
      <Navbar />
      <main>
        <Hero />
        <FeaturesSection />
        <ContactSection />
      </main>
      <Footer />
    </div>
  );
}

function Hero() {
  return (
    <section className="relative isolate bg-hero-glow px-5 pb-16 pt-20 sm:px-8 md:pb-24 md:pt-28">
      <div className="bg-grid pointer-events-none absolute inset-0 -z-10 opacity-30" />
      <div className="mx-auto grid max-w-7xl items-center gap-14 lg:grid-cols-[0.9fr_1.1fr]">
        <div className="animate-rise">
          <p className="mb-6 inline-flex items-center gap-2 text-xs font-semibold tracking-[0.22em] text-primary uppercase">
            <span className="size-2 rounded-full bg-signal shadow-[0_0_16px_var(--color-signal)]" />
            Services for schools and transport operators
          </p>
          <h1 className="max-w-3xl text-balance text-5xl font-bold leading-[0.98] tracking-tight sm:text-6xl md:text-7xl">
            Run school transport with{" "}
            <span className="text-accent-gradient">greater visibility.</span>
          </h1>
          <p className="mt-7 max-w-xl text-pretty text-lg leading-relaxed text-muted-foreground md:text-xl">
            Edu Ride combines connected bus devices, a school operations dashboard, route and
            journey monitoring, and timely updates that schools can share with families.
          </p>
          <div className="mt-9 flex flex-wrap gap-3">
            <Button asChild variant="hero" size="lg">
              <a href="#contact">
                Request a Demo <ArrowRight />
              </a>
            </Button>
            <Button asChild variant="outlineGlow" size="lg">
              <a href="#features">Explore Services</a>
            </Button>
          </div>
        </div>
        <div className="relative animate-rise [animation-delay:120ms]">
          <div className="absolute -inset-8 -z-10 rounded-full bg-primary/10 blur-3xl" />
          <div className="panel bg-surface-gradient p-3 shadow-glow sm:p-5">
            <div className="mb-4 flex items-center justify-between border-b border-border pb-4">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-primary/15 p-2 text-primary">
                  <Smartphone className="size-4" />
                </div>
                <div>
                  <p className="text-sm font-semibold">Route 042 dashboard</p>
                  <p className="text-xs text-muted-foreground">Example school-day view</p>
                </div>
              </div>
              <span className="inline-flex items-center gap-2 rounded-full border border-signal/30 bg-signal/10 px-3 py-1.5 text-xs font-medium text-signal">
                <span className="size-1.5 rounded-full bg-signal" /> Sample data
              </span>
            </div>
            <MapPreview />
            <div className="mt-3 grid grid-cols-3 gap-3">
              <div className="rounded-xl border border-border bg-background/60 p-3">
                <p className="text-[10px] tracking-widest text-muted-foreground uppercase">
                  Buses live
                </p>
                <p className="mt-1 font-display text-xl font-bold">24</p>
              </div>
              <div className="rounded-xl border border-border bg-background/60 p-3">
                <p className="text-[10px] tracking-widest text-muted-foreground uppercase">
                  On time
                </p>
                <p className="mt-1 font-display text-xl font-bold text-signal">96%</p>
              </div>
              <div className="rounded-xl border border-border bg-background/60 p-3">
                <p className="text-[10px] tracking-widest text-muted-foreground uppercase">
                  Alerts
                </p>
                <p className="mt-1 font-display text-xl font-bold text-alert">02</p>
              </div>
            </div>
          </div>
          <div className="panel absolute -bottom-7 -left-4 hidden w-56 animate-float p-4 sm:block md:-left-10">
            <div className="flex items-start gap-3">
              <div className="rounded-lg bg-signal/15 p-2 text-signal">
                <Clock3 className="size-4" />
              </div>
              <div>
                <p className="text-xs font-semibold">Arrival update sent</p>
                <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
                  Bus 042 is 12 minutes away.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function ContactSection() {
  const [status, setStatus] = useState<"idle" | "submitting" | "success">("idle");

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("submitting");
    window.setTimeout(() => setStatus("success"), 700);
  }

  return (
    <Section id="contact" muted>
      <div className="grid gap-12 lg:grid-cols-[0.8fr_1.2fr] lg:items-start">
        <div>
          <p className="inline-flex rounded-full border border-primary/25 bg-primary/8 px-3.5 py-1.5 text-xs font-semibold tracking-[0.18em] text-primary uppercase">
            Start a conversation
          </p>
          <h2 className="mt-5 text-4xl font-bold leading-tight sm:text-5xl">
            Bring smarter school transport to your community.
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-muted-foreground">
            Tell us a little about your transport operation and we will arrange a focused
            walkthrough of the Edu Ride platform.
          </p>
        </div>
        <form
          className="panel grid gap-4 p-6 md:grid-cols-2 md:p-8"
          onSubmit={handleSubmit}
          aria-busy={status === "submitting"}
        >
          {status === "success" ? (
            <div
              className="md:col-span-2 rounded-xl border border-signal/30 bg-signal/10 p-5 text-signal"
              role="status"
              aria-live="polite"
            >
              <p className="font-semibold">Thanks, your request is ready for the Edu Ride team.</p>
              <p className="mt-1 text-sm text-foreground/70">
                We will follow up using the details provided.
              </p>
            </div>
          ) : null}
          <label htmlFor="full-name" className="grid gap-2 text-sm font-medium">
            Full Name
            <input
              id="full-name"
              name="fullName"
              required
              className="h-11 rounded-xl border border-input bg-background/60 px-3 text-foreground outline-none focus:ring-2 focus:ring-ring"
              placeholder="Your name"
            />
          </label>
          <label htmlFor="organization" className="grid gap-2 text-sm font-medium">
            School / Organization
            <input
              id="organization"
              name="organization"
              required
              className="h-11 rounded-xl border border-input bg-background/60 px-3 text-foreground outline-none focus:ring-2 focus:ring-ring"
              placeholder="Organization name"
            />
          </label>
          <label htmlFor="email" className="grid gap-2 text-sm font-medium">
            Email
            <input
              id="email"
              name="email"
              required
              type="email"
              className="h-11 rounded-xl border border-input bg-background/60 px-3 text-foreground outline-none focus:ring-2 focus:ring-ring"
              placeholder="you@organization.org"
            />
          </label>
          <label htmlFor="message" className="grid gap-2 text-sm font-medium md:col-span-2">
            Message
            <textarea
              id="message"
              name="message"
              rows={4}
              className="rounded-xl border border-input bg-background/60 px-3 py-3 text-foreground outline-none focus:ring-2 focus:ring-ring"
              placeholder="What would you like to improve about school transport?"
            />
          </label>
          <Button
            type="submit"
            variant="hero"
            size="lg"
            className="md:col-span-2 md:w-fit"
            disabled={status === "submitting" || status === "success"}
          >
            {status === "submitting"
              ? "Sending request..."
              : status === "success"
                ? "Request received"
                : "Request a Demo"}
            {status === "idle" ? <ArrowRight /> : null}
          </Button>
        </form>
      </div>
    </Section>
  );
}

function Footer() {
  const socialHandles = [
    { platform: "Instagram", handle: "@EduRide" },
    { platform: "Facebook", handle: "@EduRide" },
    { platform: "LinkedIn", handle: "Edu Ride" },
  ];

  return (
    <footer className="border-t border-border px-5 py-10 sm:px-8">
      <div className="mx-auto flex max-w-7xl flex-col justify-between gap-7 sm:flex-row sm:items-start">
        <div>
          <Logo />
          <p className="mt-3 text-sm text-muted-foreground">Every Journey. Safely Tracked.</p>
        </div>
        <div className="grid gap-6 sm:grid-cols-2 sm:gap-12">
          <nav aria-label="Footer navigation" className="flex flex-col gap-3 text-sm">
            <a href="#features" className="text-muted-foreground hover:text-foreground">
              Services
            </a>
            <a href="/how-it-works" className="text-muted-foreground hover:text-foreground">
              How It Works
            </a>
            <a href="#contact" className="text-muted-foreground hover:text-foreground">
              Contact
            </a>
          </nav>
          <div>
            <p className="text-sm font-semibold">Follow Edu Ride</p>
            <ul className="mt-3 flex flex-wrap gap-2">
              {socialHandles.map(({ platform, handle }) => (
                <li
                  key={platform}
                  className="rounded-full border border-border px-3 py-1.5 text-xs text-muted-foreground"
                >
                  <span className="sr-only">{platform}: </span>
                  {handle}
                  <span className="sr-only"> on {platform}</span>
                </li>
              ))}
            </ul>
            <p className="mt-2 text-xs text-muted-foreground">
              Social handles are placeholders; replace with official account links.
            </p>
          </div>
        </div>
      </div>
      <div className="mx-auto mt-8 max-w-7xl border-t border-border pt-5 text-xs text-muted-foreground">
        © 2026 Edu Ride. Connected technology for safer school transportation.
      </div>
    </footer>
  );
}
