"use client";
// Single-slide export page — used by Puppeteer for headless capture
// URL: /slide?locale=en&idx=0&w=1290&h=2796
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";

// ─── Re-export the same slide rendering logic ─────────────────────────────────
const MK_W = 1022; const MK_H = 2082;
const SC_L  = (52   / MK_W) * 100;
const SC_T  = (46   / MK_H) * 100;
const SC_W  = (918  / MK_W) * 100;
const SC_H  = (1990 / MK_H) * 100;
const SC_RX = (126  / 918)  * 100;
const SC_RY = (126  / 1990) * 100;

type Locale = "en" | "de";

const COPY: Record<Locale, { slides: { label: string; headline: string[]; sub?: string }[] }> = {
  en: {
    slides: [
      { label: "BERLIN TRANSIT MAP", headline: ["See your bus.", "Before it arrives."], sub: "Live positions for every U-Bahn, S-Bahn, tram & bus." },
      { label: "REAL-TIME DATA", headline: ["Every vehicle.", "Live on the map."] },
      { label: "DEPARTURES", headline: ["Beat every", "delay."], sub: "Departure boards pulled directly from BVG — not timetables." },
      { label: "SAVE YOUR STOPS", headline: ["Your daily stops.", "Always ready."], sub: "Tap any stop, save it. There every time you open the app." },
      { label: "DELAY INFO", headline: ["Know before", "you leave."] },
      { label: "FREE · NO ADS · NO ACCOUNT", headline: ["The whole BVG", "network. Live."], sub: "U-Bahn, S-Bahn, tram, bus, regional — one map." },
    ],
  },
  de: {
    slides: [
      { label: "BERLIN TRANSIT MAP", headline: ["Deinen Bus sehen,", "bevor er kommt."], sub: "Live-Positionen für U-Bahn, S-Bahn, Tram und Bus." },
      { label: "ECHTZEIT-DATEN", headline: ["Jedes Fahrzeug.", "Live auf der Karte."] },
      { label: "ABFAHRTEN", headline: ["Verspätungen", "sofort erkennen."], sub: "Abfahrtszeiten direkt von BVG — keine statischen Fahrpläne." },
      { label: "HALTESTELLEN SPEICHERN", headline: ["Deine Haltestellen.", "Sofort parat."], sub: "Tippe auf eine Haltestelle, speichere sie — fertig." },
      { label: "VERSPÄTUNGS-INFO", headline: ["Wissen, bevor", "du losgehst."] },
      { label: "KOSTENLOS · KEINE WERBUNG", headline: ["Das gesamte BVG-", "Netz. Live."], sub: "U-Bahn, S-Bahn, Tram, Bus, Regional — eine Karte." },
    ],
  },
};

const SLIDE_SCREENS = ["01_map", "01_map", "02_departures", "03_favorites", "02_departures", "01_map"];
const SLIDE_STYLES  = ["light", "dark", "light", "light", "dark", "dark"] as const;

const BERLIN_BLUE       = "#115D97";
const BERLIN_BLUE_DARK  = "#0A3D6B";
const BERLIN_BLUE_LIGHT = "#1A7BC4";
const OFF_WHITE = "#F0F4F8";

const imageCache: Record<string, string> = {};

async function loadImage(path: string): Promise<string> {
  if (imageCache[path]) return imageCache[path];
  const resp = await fetch(path);
  const blob = await resp.blob();
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onloadend = () => {
      imageCache[path] = reader.result as string;
      resolve(reader.result as string);
    };
    reader.readAsDataURL(blob);
  });
}

function SlideView({ locale, idx, cW, cH }: { locale: Locale; idx: number; cW: number; cH: number }) {
  const [images, setImages] = useState<Record<string, string>>({});

  const screen  = SLIDE_SCREENS[idx];
  const isDark  = SLIDE_STYLES[idx] === "dark";
  const slide   = COPY[locale].slides[idx];
  const phoneW  = 0.80 * cW;

  useEffect(() => {
    const paths = ["/mockup.png", "/app-icon.png", `/screenshots/${locale}/${screen}.png`];
    Promise.all(paths.map(async (p) => [p, await loadImage(p)] as [string, string]))
      .then((entries) => setImages(Object.fromEntries(entries)));
  }, [locale, screen]);

  const bgGradient = isDark
    ? `linear-gradient(160deg, ${BERLIN_BLUE_DARK} 0%, ${BERLIN_BLUE} 50%, ${BERLIN_BLUE_LIGHT} 100%)`
    : `linear-gradient(175deg, ${OFF_WHITE} 0%, #DAEAF7 100%)`;

  const fadeColor = isDark ? BERLIN_BLUE_DARK : "#DAEAF7";
  const textColor  = isDark ? "#fff" : "#0D1B2A";
  const labelColor = isDark ? "rgba(255,255,255,0.65)" : BERLIN_BLUE;
  const subColor   = isDark ? "rgba(255,255,255,0.7)" : "#4A5568";

  if (!images["/mockup.png"]) {
    return <div style={{ width: cW, height: cH, background: bgGradient }} data-loading="true" />;
  }

  return (
    <div
      id="slide"
      data-ready="true"
      style={{ width: cW, height: cH, position: "relative", background: bgGradient, overflow: "hidden", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', system-ui, sans-serif" }}
    >
      {/* Blobs */}
      {isDark ? (
        <>
          <div style={{ position: "absolute", width: cW * 1.2, height: cW * 1.2, borderRadius: "50%", background: "#1A7BC4", opacity: 0.5, filter: `blur(${cW * 0.25}px)`, top: -cW * 0.3, right: -cW * 0.4 }} />
          <div style={{ position: "absolute", width: cW * 1.2, height: cW * 1.2, borderRadius: "50%", background: "#0A3D6B", opacity: 0.6, filter: `blur(${cW * 0.25}px)`, bottom: cH * 0.1, left: -cW * 0.5 }} />
        </>
      ) : (
        <>
          <div style={{ position: "absolute", width: cW * 1.2, height: cW * 1.2, borderRadius: "50%", background: BERLIN_BLUE, opacity: 0.08, filter: `blur(${cW * 0.25}px)`, top: -cW * 0.4, right: -cW * 0.3 }} />
          <div style={{ position: "absolute", width: cW * 1.2, height: cW * 1.2, borderRadius: "50%", background: BERLIN_BLUE_LIGHT, opacity: 0.12, filter: `blur(${cW * 0.25}px)`, bottom: cH * 0.05, left: -cW * 0.4 }} />
        </>
      )}

      {/* Caption */}
      <div style={{ position: "absolute", top: cH * 0.07, left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", zIndex: 10, textAlign: "center" }}>
        {idx === 0 && images["/app-icon.png"] && (
          <img
            src={images["/app-icon.png"]}
            alt=""
            style={{ width: cW * 0.18, height: cW * 0.18, borderRadius: cW * 0.038, marginBottom: cW * 0.04, boxShadow: `0 ${cW * 0.02}px ${cW * 0.06}px rgba(0,0,0,0.25)` }}
            draggable={false}
          />
        )}
        <div style={{ fontSize: cW * 0.028, fontWeight: 600, letterSpacing: "0.12em", color: labelColor, textTransform: "uppercase", marginBottom: cW * 0.02 }}>
          {slide.label}
        </div>
        {slide.headline.map((line, i) => (
          <div key={i} style={{ fontSize: cW * 0.092, fontWeight: 800, lineHeight: 1.0, color: textColor, letterSpacing: "-0.02em" }}>
            {line}
          </div>
        ))}
        {slide.sub && (
          <div style={{ marginTop: cW * 0.028, fontSize: cW * 0.038, fontWeight: 400, lineHeight: 1.4, color: subColor, maxWidth: "85%", margin: `${cW * 0.028}px auto 0` }}>
            {slide.sub}
          </div>
        )}
      </div>

      {/* Phone */}
      {images["/mockup.png"] && (
        <div style={{ position: "absolute", width: phoneW, left: (cW - phoneW) / 2, bottom: -cH * 0.12, zIndex: 5, aspectRatio: `${MK_W}/${MK_H}` }}>
          <img src={images["/mockup.png"]} alt="" style={{ display: "block", width: "100%", height: "100%" }} draggable={false} />
          <div style={{ position: "absolute", zIndex: 10, overflow: "hidden", left: `${SC_L}%`, top: `${SC_T}%`, width: `${SC_W}%`, height: `${SC_H}%`, borderRadius: `${SC_RX}% / ${SC_RY}%` }}>
            {images[`/screenshots/${locale}/${screen}.png`] && (
              <img
                src={images[`/screenshots/${locale}/${screen}.png`]}
                alt=""
                style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
                draggable={false}
              />
            )}
          </div>
        </div>
      )}

      {/* Bottom fade */}
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: cH * 0.14, background: `linear-gradient(to top, ${fadeColor}, transparent)`, zIndex: 6 }} />
    </div>
  );
}

function SlidePageInner() {
  const params = useSearchParams();
  const locale = (params.get("locale") || "en") as Locale;
  const idx    = parseInt(params.get("idx") || "0", 10);
  const cW     = parseInt(params.get("w") || "1290", 10);
  const cH     = parseInt(params.get("h") || "2796", 10);

  return (
    <div style={{ width: cW, height: cH, overflow: "hidden" }}>
      <SlideView locale={locale} idx={idx} cW={cW} cH={cH} />
    </div>
  );
}

export default function SlidePage() {
  return (
    <Suspense fallback={<div data-loading="true" />}>
      <SlidePageInner />
    </Suspense>
  );
}
