/**
 * Headless screenshot export
 * Uses /slide?locale=X&idx=N route to render each slide at native resolution,
 * then takes a Puppeteer screenshot and saves to ../screenshots/generated/{locale}/
 */

import puppeteer from "puppeteer";
import { mkdir, writeFile } from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const LOCALES = ["en", "de"];
const SLIDE_COUNT = 6;
const EXPORT_W = 1290;
const EXPORT_H = 2796; // 6.7" — IPHONE_67 in ASC

const SLIDE_IDS = ["hero", "live-vehicles", "departures", "save-stops", "delay-info", "full-network"];

const BASE_URL = "http://localhost:3000";
const OUT_BASE = path.join(__dirname, "..", "screenshots", "generated");

async function main() {
  console.log("Launching browser…");
  const browser = await puppeteer.launch({
    headless: true,
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--font-render-hinting=none"],
  });

  try {
    for (const locale of LOCALES) {
      const outDir = path.join(OUT_BASE, locale);
      await mkdir(outDir, { recursive: true });
      console.log(`\nLocale: ${locale.toUpperCase()}`);

      for (let i = 0; i < SLIDE_COUNT; i++) {
        console.log(`  Slide ${i + 1}/${SLIDE_COUNT}: ${SLIDE_IDS[i]}`);

        const page = await browser.newPage();
        await page.setViewport({ width: EXPORT_W, height: EXPORT_H, deviceScaleFactor: 1 });

        const url = `${BASE_URL}/slide?locale=${locale}&idx=${i}&w=${EXPORT_W}&h=${EXPORT_H}`;
        await page.goto(url, { waitUntil: "networkidle2", timeout: 30000 });

        // Wait until the slide signals it's fully rendered
        await page.waitForSelector("#slide[data-ready='true']", { timeout: 15000 });

        // Extra settle time for blur filters and image compositing
        await new Promise((r) => setTimeout(r, 800));

        const buffer = await page.screenshot({ type: "png", clip: { x: 0, y: 0, width: EXPORT_W, height: EXPORT_H } });

        const filename = `${String(i + 1).padStart(2, "0")}-${SLIDE_IDS[i]}-${locale}-${EXPORT_W}x${EXPORT_H}.png`;
        await writeFile(path.join(outDir, filename), buffer);
        console.log(`    ✓  ${filename}`);

        await page.close();
      }
    }
  } finally {
    await browser.close();
  }

  console.log(`\nDone! Screenshots saved to screenshots/generated/`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
