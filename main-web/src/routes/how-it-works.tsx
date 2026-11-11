import { createFileRoute } from "@tanstack/react-router";

import { CTASection } from "@/components/tread/primitives";
import { HowItWorks, TechnologySection } from "@/components/tread/sections";

export const Route = createFileRoute("/how-it-works")({
  head: () => ({
    meta: [
      { title: "How Edu Ride Works — Connect, Track, Process, Notify" },
      {
        name: "description",
        content:
          "See how the Edu Ride device, cloud platform and notification service support school transport operations and school-managed family updates.",
      },
      { property: "og:title", content: "How Edu Ride Works — Connect, Track, Process, Notify" },
      {
        property: "og:description",
        content:
          "From bus device to network, cloud and notifications—a look at how Edu Ride supports school transport teams.",
      },
    ],
  }),
  component: HowItWorksPage,
});

function HowItWorksPage() {
  return (
    <main>
      <HowItWorks withHeaderSpacing />
      <TechnologySection />
      <CTASection
        title="See how Edu Ride supports your operation"
        description="Book a walkthrough of the connected device, school dashboard and school-managed family notification service."
      />
    </main>
  );
}
