import fs from "node:fs/promises";
import sharp from "sharp";
const out = "public";
const files = {
  iconInk:  "public/clickapp_icon_ink.svg",
  iconWhite:"public/clickapp_icon_white.svg",
  wordInk:  "public/clickapp_wordmark_ink.svg",
  wordWhite:"public/clickapp_wordmark_white.svg",
};

async function makePng(svgPath, pngPath, size) {
  const svg = await fs.readFile(svgPath);
  await sharp(svg, { density: 384 })
    .resize(size, size, { fit: "contain", background: { r:0, g:0, b:0, alpha:0 } })
    .png()
    .toFile(`${out}/${pngPath}`);
  console.log("✓", pngPath);
}

async function makeCanvas(svgPath, pngPath, w, h) {
  const svg = await fs.readFile(svgPath);
  await sharp({
      create: { width: w, height: h, channels: 4, background: { r:0, g:0, b:0, alpha:0 } }
    })
    .composite([{ input: svg, gravity: "center" }])
    .png()
    .toFile(`${out}/${pngPath}`);
  console.log("✓", pngPath);
}

(async () => {
  // App icons
  await makePng(files.iconInk,  "icon-192.png", 192);
  await makePng(files.iconInk,  "icon-512.png", 512);

  // Favicons (ICO sources)
  await makePng(files.iconInk,  "favicon-16.png", 16);
  await makePng(files.iconInk,  "favicon-32.png", 32);

  // Social preview (Open Graph) – 1200x630
  await makeCanvas(files.wordInk,   "og-image.png",       1200, 630);
  await makeCanvas(files.wordWhite, "og-image-dark.png",  1200, 630);
})();
