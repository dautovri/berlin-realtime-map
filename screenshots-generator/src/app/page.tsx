"use client";
import { useEffect, useRef, useState } from "react";
import { toPng } from "html-to-image";

// ─── Canvas dimensions (design at largest, export at target) ────────────────
const W = 1320; const H = 2868; // 6.9" iPhone — largest required

// ─── Export sizes ────────────────────────────────────────────────────────────
const IPHONE_SIZES = [
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.7"', w: 1290, h: 2796 },
  { label: '6.5"', w: 1284, h: 2778 },
  { label: '6.3"', w: 1206, h: 2622 },
  { label: '6.1"', w: 1179, h: 2556 },
] as const;

// ─── iPhone mockup pre-measured values ───────────────────────────────────────
const MK_W = 1022; const MK_H = 2082;
const SC_L  = (52   / MK_W) * 100;
const SC_T  = (46   / MK_H) * 100;
const SC_W  = (918  / MK_W) * 100;
const SC_H  = (1990 / MK_H) * 100;
const SC_RX = (126  / 918)  * 100;
const SC_RY = (126  / 1990) * 100;

// ─── Locales ─────────────────────────────────────────────────────────────────
const LOCALES = ["en", "de"] as const;
type Locale = typeof LOCALES[number];

// ─── Copy ────────────────────────────────────────────────────────────────────
const COPY: Record<Locale, {
  label: string;
  slides: { label: string; headline: string[]; sub?: string }[];
}> = {
  en: {
    label: "Berlin Transit",
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
    label: "Berlin Transit",
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

// ─── Screen assignment per slide ─────────────────────────────────────────────
const SLIDE_SCREENS = ["01_map", "01_map", "02_departures", "03_favorites", "02_departures", "01_map"];

// ─── Brand colors ─────────────────────────────────────────────────────────────
const BERLIN_BLUE       = "#115D97";
const BERLIN_BLUE_DARK  = "#0A3D6B";
const BERLIN_BLUE_LIGHT = "#1A7BC4";
const OFF_WHITE = "#F0F4F8";

// ─── Slide styles ─────────────────────────────────────────────────────────────
type SlideStyle = "light" | "dark";
const SLIDE_STYLES: SlideStyle[] = ["light", "dark", "light", "light", "dark", "dark"];

// ─── Image preloading ─────────────────────────────────────────────────────────
const IMAGE_PATHS = [
  "/mockup.png",
  "/app-icon.png",
  ...LOCALES.flatMap((l) =>
    ["01_map", "02_departures", "03_favorites"].map((s) => `/screenshots/${l}/${s}.png`)
  ),
];

const imageCache: Record<string, string> = {};

async function preloadAllImages() {
  await Promise.all(
    IMAGE_PATHS.map(async (path) => {
      try {
        const resp = await fetch(path);
        const blob = await resp.blob();
        const dataUrl = await new Promise<string>((resolve) => {
          const reader = new FileReader();
          reader.onloadend = () => resolve(reader.result as string);
          reader.readAsDataURL(blob);
        });
        imageCache[path] = dataUrl;
      } catch {
        console.warn("Failed to preload", path);
      }
    })
  );
}

function img(path: string): string {
  return imageCache[path] || path;
}

// ─── Phone frame ──────────────────────────────────────────────────────────────
function Phone({ src, alt, style }: { src: string; alt: string; style?: React.CSSProperties }) {
  return (
    <div style={{ position: "relative", aspectRatio: `${MK_W}/${MK_H}`, ...style }}>
      <img src={img("/mockup.png")} alt="" style={{ display: "block", width: "100%", height: "100%" }} draggable={false} />
      <div style={{
        position: "absolute", zIndex: 10, overflow: "hidden",
        left: `${SC_L}%`, top: `${SC_T}%`,
        width: `${SC_W}%`, height: `${SC_H}%`,
        borderRadius: `${SC_RX}% / ${SC_RY}%`,
      }}>
        <img src={src} alt={alt} style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }} draggable={false} />
      </div>
    </div>
  );
}

// ─── Caption ──────────────────────────────────────────────────────────────────
function Caption({ label, headline, sub, isDark, cW }: {
  label: string; headline: string[]; sub?: string; isDark: boolean; cW: number;
}) {
  const textColor  = isDark ? "#fff" : "#0D1B2A";
  const labelColor = isDark ? "rgba(255,255,255,0.65)" : BERLIN_BLUE;
  const subColor   = isDark ? "rgba(255,255,255,0.7)" : "#4A5568";

  return (
    <div style={{ textAlign: "center" }}>
      <div style={{ fontSize: cW * 0.028, fontWeight: 600, letterSpacing: "0.12em", color: labelColor, textTransform: "uppercase", marginBottom: cW * 0.02 }}>
        {label}
      </div>
      {headline.map((line, i) => (
        <div key={i} style={{ fontSize: cW * 0.092, fontWeight: 800, lineHeight: 1.0, color: textColor, letterSpacing: "-0.02em" }}>
          {line}
        </div>
      ))}
      {sub && (
        <div style={{ marginTop: cW * 0.028, fontSize: cW * 0.038, fontWeight: 400, lineHeight: 1.4, color: subColor, maxWidth: "85%", margin: `${cW * 0.028}px auto 0` }}>
          {sub}
        </div>
      )}
    </div>
  );
}

// ─── Decorative blob ──────────────────────────────────────────────────────────
function Blob({ color, opacity, cW, style }: { color: string; opacity: number; cW: number; style: React.CSSProperties }) {
  return (
    <div style={{ position: "absolute", width: cW * 1.2, height: cW * 1.2, borderRadius: "50%", background: color, opacity, filter: `blur(${cW * 0.25}px)`, ...style }} />
  );
}

// ─── Slide ────────────────────────────────────────────────────────────────────
function Slide({ cW, cH, locale, idx }: { cW: number; cH: number; locale: Locale; idx: number }) {
  const slide   = COPY[locale].slides[idx];
  const screen  = SLIDE_SCREENS[idx];
  const isDark  = SLIDE_STYLES[idx] === "dark";
  const phoneW  = 0.80 * cW;

  const bgGradient = isDark
    ? `linear-gradient(160deg, ${BERLIN_BLUE_DARK} 0%, ${BERLIN_BLUE} 50%, ${BERLIN_BLUE_LIGHT} 100%)`
    : `linear-gradient(175deg, ${OFF_WHITE} 0%, #DAEAF7 100%)`;

  const fadeColor = isDark ? BERLIN_BLUE_DARK : "#DAEAF7";

  return (
    <div style={{ width: cW, height: cH, position: "relative", background: bgGradient, overflow: "hidden" }}>
      {/* Blobs */}
      {isDark ? (
        <>
          <Blob color="#1A7BC4" opacity={0.5} cW={cW} style={{ top: -cW * 0.3, right: -cW * 0.4 }} />
          <Blob color="#0A3D6B" opacity={0.6} cW={cW} style={{ bottom: cH * 0.1, left: -cW * 0.5 }} />
        </>
      ) : (
        <>
          <Blob color={BERLIN_BLUE} opacity={0.08} cW={cW} style={{ top: -cW * 0.4, right: -cW * 0.3 }} />
          <Blob color={BERLIN_BLUE_LIGHT} opacity={0.12} cW={cW} style={{ bottom: cH * 0.05, left: -cW * 0.4 }} />
        </>
      )}

      {/* Caption */}
      <div style={{ position: "absolute", top: cH * 0.07, left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", zIndex: 10 }}>
        {idx === 0 && (
          <img
            src={img("/app-icon.png")}
            alt="Berlin Transit"
            style={{ width: cW * 0.18, height: cW * 0.18, borderRadius: cW * 0.038, marginBottom: cW * 0.04, boxShadow: `0 ${cW * 0.02}px ${cW * 0.06}px rgba(0,0,0,0.25)` }}
            draggable={false}
          />
        )}
        <Caption label={slide.label} headline={slide.headline} sub={slide.sub} isDark={isDark} cW={cW} />
      </div>

      {/* Phone */}
      <Phone
        src={img(`/screenshots/${locale}/${screen}.png`)}
        alt={slide.headline.join(" ")}
        style={{ position: "absolute", width: phoneW, left: (cW - phoneW) / 2, bottom: -cH * 0.12, zIndex: 5 }}
      />

      {/* Bottom fade */}
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: cH * 0.14, background: `linear-gradient(to top, ${fadeColor}, transparent)`, zIndex: 6 }} />
    </div>
  );
}

// ─── ScreenshotPreview ────────────────────────────────────────────────────────
function ScreenshotPreview({ cW, cH, locale, idx, exportRef }: {
  cW: number; cH: number; locale: Locale; idx: number;
  exportRef: React.RefObject<HTMLDivElement | null>;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);

  useEffect(() => {
    if (!containerRef.current) return;
    const ro = new ResizeObserver(([entry]) => {
      const { width } = entry.contentRect;
      setScale(width / cW);
    });
    ro.observe(containerRef.current);
    return () => ro.disconnect();
  }, [cW, cH]);

  return (
    <div ref={containerRef} style={{ width: "100%", paddingBottom: `${(cH / cW) * 100}%`, position: "relative", overflow: "hidden", borderRadius: 12, boxShadow: "0 2px 16px rgba(0,0,0,0.15)" }}>
      <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
        <div style={{ transform: `scale(${scale})`, transformOrigin: "top left" }}>
          <Slide cW={cW} cH={cH} locale={locale} idx={idx} />
        </div>
      </div>
      {/* Offscreen export target */}
      <div ref={exportRef} style={{ position: "absolute", left: "-9999px", top: 0, opacity: 0, zIndex: -1 }}>
        <Slide cW={cW} cH={cH} locale={locale} idx={idx} />
      </div>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────
export default function ScreenshotsPage() {
  const [ready, setReady] = useState(false);
  const [locale, setLocale] = useState<Locale>("en");
  const [sizeIdx, setSizeIdx] = useState(0);
  const [exporting, setExporting] = useState<string | null>(null);

  const exportRefs = useRef<Array<React.RefObject<HTMLDivElement | null>>>(
    Array.from({ length: 6 }, () => ({ current: null }))
  );

  useEffect(() => {
    preloadAllImages().then(() => setReady(true));
  }, []);

  const size = IPHONE_SIZES[sizeIdx];

  async function captureSlide(el: HTMLElement, w: number, h: number): Promise<string> {
    el.style.left = "0px";
    el.style.opacity = "1";
    el.style.zIndex = "-1";
    const opts = { width: w, height: h, pixelRatio: 1, cacheBust: true };
    await toPng(el, opts);
    const dataUrl = await toPng(el, opts);
    el.style.left = "-9999px";
    el.style.opacity = "0";
    el.style.zIndex = "-1";
    return dataUrl;
  }

  async function exportAll() {
    for (let i = 0; i < 6; i++) {
      setExporting(`${i + 1}/6`);
      const el = exportRefs.current[i]?.current;
      if (!el) continue;
      const dataUrl = await captureSlide(el, size.w, size.h);
      const a = document.createElement("a");
      a.href = dataUrl;
      const slug = COPY[locale].slides[i].headline.join("-").toLowerCase().replace(/[^a-z0-9-]/g, "").slice(0, 40);
      a.download = `${String(i + 1).padStart(2, "0")}-${slug}-${locale}-${size.w}x${size.h}.png`;
      a.click();
      await new Promise((r) => setTimeout(r, 300));
    }
    setExporting(null);
  }

  if (!ready) {
    return (
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100vh", background: "#f3f4f6" }}>
        <p style={{ color: "#6b7280", fontSize: 16, fontFamily: "system-ui" }}>Loading images…</p>
      </div>
    );
  }

  return (
    <div style={{ minHeight: "100vh", background: "#f3f4f6", position: "relative", overflowX: "hidden" }}>
      {/* Toolbar */}
      <div style={{ position: "sticky", top: 0, zIndex: 50, background: "white", borderBottom: "1px solid #e5e7eb", display: "flex", alignItems: "center" }}>
        <div style={{ flex: 1, display: "flex", alignItems: "center", gap: 10, padding: "10px 16px", overflowX: "auto", minWidth: 0 }}>
          <span style={{ fontWeight: 700, fontSize: 14, whiteSpace: "nowrap", color: "#111" }}>Berlin Transit · Screenshots</span>
          <select value={locale} onChange={(e) => setLocale(e.target.value as Locale)} style={{ fontSize: 12, border: "1px solid #e5e7eb", borderRadius: 6, padding: "5px 10px", cursor: "pointer" }}>
            {LOCALES.map((l) => <option key={l} value={l}>{l.toUpperCase()}</option>)}
          </select>
          <select value={sizeIdx} onChange={(e) => setSizeIdx(Number(e.target.value))} style={{ fontSize: 12, border: "1px solid #e5e7eb", borderRadius: 6, padding: "5px 10px", cursor: "pointer" }}>
            {IPHONE_SIZES.map((s, i) => <option key={i} value={i}>{s.label} — {s.w}×{s.h}</option>)}
          </select>
          <span style={{ fontSize: 12, color: "#9ca3af", whiteSpace: "nowrap" }}>6 slides · iPhone · EN + DE</span>
        </div>
        <div style={{ flexShrink: 0, padding: "10px 16px", borderLeft: "1px solid #e5e7eb" }}>
          <button onClick={exportAll} disabled={!!exporting} style={{ padding: "7px 20px", background: exporting ? "#93c5fd" : BERLIN_BLUE, color: "white", border: "none", borderRadius: 8, fontSize: 12, fontWeight: 600, cursor: exporting ? "default" : "pointer", whiteSpace: "nowrap" }}>
            {exporting ? `Exporting… ${exporting}` : "Export All"}
          </button>
        </div>
      </div>

      {/* Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 20, padding: 20, maxWidth: 1400, margin: "0 auto" }}>
        {Array.from({ length: 6 }, (_, i) => (
          <div key={i}>
            <div style={{ marginBottom: 8, fontSize: 12, fontWeight: 600, color: "#374151" }}>
              {String(i + 1).padStart(2, "0")} — {COPY[locale].slides[i].headline.join(" ")}
            </div>
            <ScreenshotPreview cW={W} cH={H} locale={locale} idx={i} exportRef={exportRefs.current[i]} />
          </div>
        ))}
      </div>
    </div>
  );
}
