import { Menu, X } from "lucide-react";
import { useEffect, useState } from "react";

import { Logo } from "@/components/tread/primitives";
import { Button } from "@/components/ui/button";

const NAV_ITEMS = [
  { href: "#top", label: "Home" },
  { href: "#features", label: "Services" },
  { href: "/how-it-works", label: "How It Works" },
  { href: "#contact", label: "Contact" },
] as const;

export function Navbar() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={`sticky top-0 z-50 w-full transition-all duration-300 ${
        scrolled
          ? "border-b border-border/70 bg-background/85 backdrop-blur-xl"
          : "border-b border-transparent bg-background/40 backdrop-blur-sm"
      }`}
    >
      <div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between gap-4 px-5 sm:px-8 lg:h-18">
        <Logo />

        <nav aria-label="Main navigation" className="hidden items-center gap-1 xl:flex">
          {NAV_ITEMS.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="rounded-full px-3.5 py-2 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent/60 hover:text-foreground"
            >
              {item.label}
            </a>
          ))}
        </nav>

        <div className="hidden items-center gap-2 lg:flex">
          <Button asChild variant="hero" size="sm">
            <a href="#contact">Request a Demo</a>
          </Button>
        </div>

        <Button
          variant="ghost"
          size="icon"
          className="xl:hidden"
          aria-label={open ? "Close menu" : "Open menu"}
          aria-expanded={open}
          onClick={() => setOpen((v) => !v)}
        >
          {open ? <X /> : <Menu />}
        </Button>
      </div>

      {open ? (
        <div className="border-t border-border bg-background/95 backdrop-blur-xl xl:hidden">
          <nav
            aria-label="Mobile navigation"
            className="mx-auto grid max-w-7xl gap-1 px-5 py-4 sm:px-8"
          >
            {NAV_ITEMS.map((item) => (
              <a
                key={item.href}
                href={item.href}
                onClick={() => setOpen(false)}
                className="rounded-xl px-3 py-3 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent/60 hover:text-foreground"
              >
                {item.label}
              </a>
            ))}
            <div className="mt-3 grid gap-2">
              <Button asChild variant="hero">
                <a href="#contact" onClick={() => setOpen(false)}>
                  Request a Demo
                </a>
              </Button>
            </div>
          </nav>
        </div>
      ) : null}
    </header>
  );
}
