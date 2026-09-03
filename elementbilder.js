// elementbilder.js
// elementbilder_pd_cc0.js
// Strenger Wikimedia-Commons-Bildlader fuer alle 118 chemischen Elemente.
//
// Rechte-Strategie:
// - akzeptiert AUSSCHLIESSLICH Public Domain oder CC0
// - CC BY, CC BY-SA, GFDL, FAL und unklare Lizenzen werden abgelehnt
// - bevorzugt echte Elementproben/Fotos statt Diagrammen oder Symbolgrafiken
// - Lizenz, Urheber, Commons-Dateiseite und Original-URL werden mitgeliefert
// - gibt es keinen geeigneten PD/CC0-Treffer, wird KEIN fremdes Bild verwendet;
//   die aufrufende Seite kann dann einen selbst erzeugten Elementsymbol-Platzhalter zeigen.
//
// Datenquelle: Wikimedia Commons / MediaWiki API.
// Die Lizenz wird bei der Auswahl aus den Commons-Metadaten der konkreten Datei gelesen.

const ELEMENTE = [
  { z: 1, symbol: "H", nameDe: "Wasserstoff", nameEn: "Hydrogen" },
  { z: 2, symbol: "He", nameDe: "Helium", nameEn: "Helium" },
  { z: 3, symbol: "Li", nameDe: "Lithium", nameEn: "Lithium" },
  { z: 4, symbol: "Be", nameDe: "Beryllium", nameEn: "Beryllium" },
  { z: 5, symbol: "B", nameDe: "Bor", nameEn: "Boron" },
  { z: 6, symbol: "C", nameDe: "Kohlenstoff", nameEn: "Carbon" },
  { z: 7, symbol: "N", nameDe: "Stickstoff", nameEn: "Nitrogen" },
  { z: 8, symbol: "O", nameDe: "Sauerstoff", nameEn: "Oxygen" },
  { z: 9, symbol: "F", nameDe: "Fluor", nameEn: "Fluorine" },
  { z: 10, symbol: "Ne", nameDe: "Neon", nameEn: "Neon" },
  { z: 11, symbol: "Na", nameDe: "Natrium", nameEn: "Sodium" },
  { z: 12, symbol: "Mg", nameDe: "Magnesium", nameEn: "Magnesium" },
  { z: 13, symbol: "Al", nameDe: "Aluminium", nameEn: "Aluminium" },
  { z: 14, symbol: "Si", nameDe: "Silicium", nameEn: "Silicon" },
  { z: 15, symbol: "P", nameDe: "Phosphor", nameEn: "Phosphorus" },
  { z: 16, symbol: "S", nameDe: "Schwefel", nameEn: "Sulfur" },
  { z: 17, symbol: "Cl", nameDe: "Chlor", nameEn: "Chlorine" },
  { z: 18, symbol: "Ar", nameDe: "Argon", nameEn: "Argon" },
  { z: 19, symbol: "K", nameDe: "Kalium", nameEn: "Potassium" },
  { z: 20, symbol: "Ca", nameDe: "Calcium", nameEn: "Calcium" },
  { z: 21, symbol: "Sc", nameDe: "Scandium", nameEn: "Scandium" },
  { z: 22, symbol: "Ti", nameDe: "Titan", nameEn: "Titanium" },
  { z: 23, symbol: "V", nameDe: "Vanadium", nameEn: "Vanadium" },
  { z: 24, symbol: "Cr", nameDe: "Chrom", nameEn: "Chromium" },
  { z: 25, symbol: "Mn", nameDe: "Mangan", nameEn: "Manganese" },
  { z: 26, symbol: "Fe", nameDe: "Eisen", nameEn: "Iron" },
  { z: 27, symbol: "Co", nameDe: "Cobalt", nameEn: "Cobalt" },
  { z: 28, symbol: "Ni", nameDe: "Nickel", nameEn: "Nickel" },
  { z: 29, symbol: "Cu", nameDe: "Kupfer", nameEn: "Copper" },
  { z: 30, symbol: "Zn", nameDe: "Zink", nameEn: "Zinc" },
  { z: 31, symbol: "Ga", nameDe: "Gallium", nameEn: "Gallium" },
  { z: 32, symbol: "Ge", nameDe: "Germanium", nameEn: "Germanium" },
  { z: 33, symbol: "As", nameDe: "Arsen", nameEn: "Arsenic" },
  { z: 34, symbol: "Se", nameDe: "Selen", nameEn: "Selenium" },
  { z: 35, symbol: "Br", nameDe: "Brom", nameEn: "Bromine" },
  { z: 36, symbol: "Kr", nameDe: "Krypton", nameEn: "Krypton" },
  { z: 37, symbol: "Rb", nameDe: "Rubidium", nameEn: "Rubidium" },
  { z: 38, symbol: "Sr", nameDe: "Strontium", nameEn: "Strontium" },
  { z: 39, symbol: "Y", nameDe: "Yttrium", nameEn: "Yttrium" },
  { z: 40, symbol: "Zr", nameDe: "Zirconium", nameEn: "Zirconium" },
  { z: 41, symbol: "Nb", nameDe: "Niob", nameEn: "Niobium" },
  { z: 42, symbol: "Mo", nameDe: "Molybdän", nameEn: "Molybdenum" },
  { z: 43, symbol: "Tc", nameDe: "Technetium", nameEn: "Technetium" },
  { z: 44, symbol: "Ru", nameDe: "Ruthenium", nameEn: "Ruthenium" },
  { z: 45, symbol: "Rh", nameDe: "Rhodium", nameEn: "Rhodium" },
  { z: 46, symbol: "Pd", nameDe: "Palladium", nameEn: "Palladium" },
  { z: 47, symbol: "Ag", nameDe: "Silber", nameEn: "Silver" },
  { z: 48, symbol: "Cd", nameDe: "Cadmium", nameEn: "Cadmium" },
  { z: 49, symbol: "In", nameDe: "Indium", nameEn: "Indium" },
  { z: 50, symbol: "Sn", nameDe: "Zinn", nameEn: "Tin" },
  { z: 51, symbol: "Sb", nameDe: "Antimon", nameEn: "Antimony" },
  { z: 52, symbol: "Te", nameDe: "Tellur", nameEn: "Tellurium" },
  { z: 53, symbol: "I", nameDe: "Iod", nameEn: "Iodine" },
  { z: 54, symbol: "Xe", nameDe: "Xenon", nameEn: "Xenon" },
  { z: 55, symbol: "Cs", nameDe: "Cäsium", nameEn: "Caesium" },
  { z: 56, symbol: "Ba", nameDe: "Barium", nameEn: "Barium" },
  { z: 57, symbol: "La", nameDe: "Lanthan", nameEn: "Lanthanum" },
  { z: 58, symbol: "Ce", nameDe: "Cer", nameEn: "Cerium" },
  { z: 59, symbol: "Pr", nameDe: "Praseodym", nameEn: "Praseodymium" },
  { z: 60, symbol: "Nd", nameDe: "Neodym", nameEn: "Neodymium" },
  { z: 61, symbol: "Pm", nameDe: "Promethium", nameEn: "Promethium" },
  { z: 62, symbol: "Sm", nameDe: "Samarium", nameEn: "Samarium" },
  { z: 63, symbol: "Eu", nameDe: "Europium", nameEn: "Europium" },
  { z: 64, symbol: "Gd", nameDe: "Gadolinium", nameEn: "Gadolinium" },
  { z: 65, symbol: "Tb", nameDe: "Terbium", nameEn: "Terbium" },
  { z: 66, symbol: "Dy", nameDe: "Dysprosium", nameEn: "Dysprosium" },
  { z: 67, symbol: "Ho", nameDe: "Holmium", nameEn: "Holmium" },
  { z: 68, symbol: "Er", nameDe: "Erbium", nameEn: "Erbium" },
  { z: 69, symbol: "Tm", nameDe: "Thulium", nameEn: "Thulium" },
  { z: 70, symbol: "Yb", nameDe: "Ytterbium", nameEn: "Ytterbium" },
  { z: 71, symbol: "Lu", nameDe: "Lutetium", nameEn: "Lutetium" },
  { z: 72, symbol: "Hf", nameDe: "Hafnium", nameEn: "Hafnium" },
  { z: 73, symbol: "Ta", nameDe: "Tantal", nameEn: "Tantalum" },
  { z: 74, symbol: "W", nameDe: "Wolfram", nameEn: "Tungsten" },
  { z: 75, symbol: "Re", nameDe: "Rhenium", nameEn: "Rhenium" },
  { z: 76, symbol: "Os", nameDe: "Osmium", nameEn: "Osmium" },
  { z: 77, symbol: "Ir", nameDe: "Iridium", nameEn: "Iridium" },
  { z: 78, symbol: "Pt", nameDe: "Platin", nameEn: "Platinum" },
  { z: 79, symbol: "Au", nameDe: "Gold", nameEn: "Gold" },
  { z: 80, symbol: "Hg", nameDe: "Quecksilber", nameEn: "Mercury" },
  { z: 81, symbol: "Tl", nameDe: "Thallium", nameEn: "Thallium" },
  { z: 82, symbol: "Pb", nameDe: "Blei", nameEn: "Lead" },
  { z: 83, symbol: "Bi", nameDe: "Bismut", nameEn: "Bismuth" },
  { z: 84, symbol: "Po", nameDe: "Polonium", nameEn: "Polonium" },
  { z: 85, symbol: "At", nameDe: "Astat", nameEn: "Astatine" },
  { z: 86, symbol: "Rn", nameDe: "Radon", nameEn: "Radon" },
  { z: 87, symbol: "Fr", nameDe: "Francium", nameEn: "Francium" },
  { z: 88, symbol: "Ra", nameDe: "Radium", nameEn: "Radium" },
  { z: 89, symbol: "Ac", nameDe: "Actinium", nameEn: "Actinium" },
  { z: 90, symbol: "Th", nameDe: "Thorium", nameEn: "Thorium" },
  { z: 91, symbol: "Pa", nameDe: "Protactinium", nameEn: "Protactinium" },
  { z: 92, symbol: "U", nameDe: "Uran", nameEn: "Uranium" },
  { z: 93, symbol: "Np", nameDe: "Neptunium", nameEn: "Neptunium" },
  { z: 94, symbol: "Pu", nameDe: "Plutonium", nameEn: "Plutonium" },
  { z: 95, symbol: "Am", nameDe: "Americium", nameEn: "Americium" },
  { z: 96, symbol: "Cm", nameDe: "Curium", nameEn: "Curium" },
  { z: 97, symbol: "Bk", nameDe: "Berkelium", nameEn: "Berkelium" },
  { z: 98, symbol: "Cf", nameDe: "Californium", nameEn: "Californium" },
  { z: 99, symbol: "Es", nameDe: "Einsteinium", nameEn: "Einsteinium" },
  { z: 100, symbol: "Fm", nameDe: "Fermium", nameEn: "Fermium" },
  { z: 101, symbol: "Md", nameDe: "Mendelevium", nameEn: "Mendelevium" },
  { z: 102, symbol: "No", nameDe: "Nobelium", nameEn: "Nobelium" },
  { z: 103, symbol: "Lr", nameDe: "Lawrencium", nameEn: "Lawrencium" },
  { z: 104, symbol: "Rf", nameDe: "Rutherfordium", nameEn: "Rutherfordium" },
  { z: 105, symbol: "Db", nameDe: "Dubnium", nameEn: "Dubnium" },
  { z: 106, symbol: "Sg", nameDe: "Seaborgium", nameEn: "Seaborgium" },
  { z: 107, symbol: "Bh", nameDe: "Bohrium", nameEn: "Bohrium" },
  { z: 108, symbol: "Hs", nameDe: "Hassium", nameEn: "Hassium" },
  { z: 109, symbol: "Mt", nameDe: "Meitnerium", nameEn: "Meitnerium" },
  { z: 110, symbol: "Ds", nameDe: "Darmstadtium", nameEn: "Darmstadtium" },
  { z: 111, symbol: "Rg", nameDe: "Röntgenium", nameEn: "Roentgenium" },
  { z: 112, symbol: "Cn", nameDe: "Copernicium", nameEn: "Copernicium" },
  { z: 113, symbol: "Nh", nameDe: "Nihonium", nameEn: "Nihonium" },
  { z: 114, symbol: "Fl", nameDe: "Flerovium", nameEn: "Flerovium" },
  { z: 115, symbol: "Mc", nameDe: "Moscovium", nameEn: "Moscovium" },
  { z: 116, symbol: "Lv", nameDe: "Livermorium", nameEn: "Livermorium" },
  { z: 117, symbol: "Ts", nameDe: "Tenness", nameEn: "Tennessine" },
  { z: 118, symbol: "Og", nameDe: "Oganesson", nameEn: "Oganesson" }
];

const COMMONS_API = "https://commons.wikimedia.org/w/api.php";
const COMMONS_GALLERY_BASE = "https://commons.wikimedia.org/wiki/";
const CACHE_PREFIX = "elementenpuzzle.commons.image.pd_cc0.v3.";
const CACHE_MAX_AGE_MS = 30 * 24 * 60 * 60 * 1000;

const STRICT_LICENSE_MODE = "PD_CC0_ONLY";

const BAD_FILENAME_WORDS = [
  "electron", "shell", "bohr", "spectrum", "spectra", "periodic",
  "crystal structure", "crystal_structure", "logo", "icon", "symbol",
  "map", "diagram", "orbital", "isotope", "nucleus", "decay",
  "configuration", "hazard", "ghs", "coat of arms", "flag",
  "mineral", "ore", "compound", "oxide", "chloride", "sulfide", "sulphide",
  "carbonate", "nitrate", "phosphate", "hydroxide", "salt", "coin", "coins",
  "jewelry", "jewellery", "ring", "statue", "medal", "periodic table"
];

const GOOD_FILENAME_WORDS = [
  "sample", "crystal", "crystals", "pure", "piece", "pieces", "ampoule",
  "ampule", "metal", "gas", "liquid", "solid", "rod", "foil", "pellet",
  "ingot", "bead", "powder"
];

function apiUrl(params) {
  const url = new URL(COMMONS_API);
  Object.entries({ action: "query", format: "json", origin: "*", ...params })
    .forEach(([k, v]) => url.searchParams.set(k, String(v)));
  return url.toString();
}

async function getJson(url) {
  const r = await fetch(url, { mode: "cors" });
  if (!r.ok) throw new Error(`Wikimedia API: HTTP ${r.status}`);
  return r.json();
}

function plainText(html = "") {
  const t = document.createElement("textarea");
  t.innerHTML = String(html).replace(/<[^>]*>/g, " ");
  return t.value.replace(/\s+/g, " ").trim();
}

function isPublicDomainLike(shortName = "") {
  const s = plainText(shortName).toLowerCase().trim();
  return (
    s === "cc0" || s.startsWith("cc0 ") || s.includes("cc zero") ||
    s.includes("public domain") ||
    s === "pd" || s.startsWith("pd-") || s.startsWith("pd ") || s.startsWith("pd_")
  );
}

function licenseAllowed(shortName = "") {
  return isPublicDomainLike(shortName);
}

function scoreCandidate(title, info, element) {
  const n = title.toLowerCase();
  let score = 0;

  const lic = info?.extmetadata?.LicenseShortName?.value || "";
  if (!licenseAllowed(lic)) return -10000;

  if (isPublicDomainLike(lic)) score += 180;

  if (n.includes(element.nameEn.toLowerCase())) score += 45;
  if (n.includes(element.symbol.toLowerCase())) score += 4;

  GOOD_FILENAME_WORDS.forEach(w => {
    if (n.includes(w)) score += 13;
  });
  BAD_FILENAME_WORDS.forEach(w => {
    if (n.includes(w)) score -= 35;
  });

  const mime = info?.mime || "";
  if (mime === "image/jpeg" || mime === "image/png" || mime === "image/webp") score += 18;
  if (mime === "image/svg+xml") score -= 12;

  const desc = plainText(info?.extmetadata?.ImageDescription?.value || "").toLowerCase();
  if (desc.includes("sample")) score += 24;
  if (desc.includes("pure")) score += 18;
  if (desc.includes("element")) score += 10;
  if (desc.includes("diagram")) score -= 35;
  if (desc.includes("mineral")) score -= 25;
  if (desc.includes("compound")) score -= 30;

  return score;
}

function cacheRead(symbol) {
  try {
    const raw = localStorage.getItem(CACHE_PREFIX + symbol);
    if (!raw) return null;
    const obj = JSON.parse(raw);
    if (!obj.savedAt || Date.now() - obj.savedAt > CACHE_MAX_AGE_MS) return null;
    return obj.data || null;
  } catch {
    return null;
  }
}

function cacheWrite(symbol, data) {
  try {
    localStorage.setItem(
      CACHE_PREFIX + symbol,
      JSON.stringify({ savedAt: Date.now(), data })
    );
  } catch {
    // localStorage kann z. B. im Privatmodus gesperrt sein; dann einfach ohne Cache.
  }
}

async function galleryImageTitles(element, limit = 100) {
  // Die Commons-Galerien heissen normalerweise nach dem englischen Elementnamen.
  const params = {
    prop: "images",
    titles: element.nameEn.toLowerCase(),
    imlimit: Math.min(limit, 500)
  };
  const data = await getJson(apiUrl(params));
  const pages = data?.query?.pages || {};
  const page = Object.values(pages)[0];
  return (page?.images || [])
    .map(x => x.title)
    .filter(Boolean);
}

async function searchImageTitles(element, limitPerQuery = 35) {
  const queries = [
    `${element.nameEn} element sample`,
    `${element.nameEn} pure element`,
    `${element.nameEn} metal sample`,
    `${element.nameEn} crystal element`
  ];

  const titles = [];
  for (const q of queries) {
    const params = {
      generator: "search",
      gsrnamespace: 6,
      gsrsearch: q,
      gsrlimit: Math.min(limitPerQuery, 50),
      prop: "info"
    };
    try {
      const data = await getJson(apiUrl(params));
      const pages = data?.query?.pages || {};
      titles.push(...Object.values(pages).map(p => p.title).filter(Boolean));
    } catch (e) {
      console.warn(`Commons-Suche fehlgeschlagen (${q}):`, e);
    }
  }
  return [...new Set(titles)];
}

async function fetchImageInfos(titles) {
  const chunks = [];
  for (let i = 0; i < titles.length; i += 40) chunks.push(titles.slice(i, i + 40));

  const out = [];
  for (const chunk of chunks) {
    const params = {
      prop: "imageinfo",
      titles: chunk.join("|"),
      iiprop: "url|mime|extmetadata",
      iiurlwidth: 800
    };
    const data = await getJson(apiUrl(params));
    const pages = data?.query?.pages || {};
    for (const page of Object.values(pages)) {
      const ii = page?.imageinfo?.[0];
      if (ii) out.push({ title: page.title, info: ii });
    }
  }
  return out;
}

function normalizeResult(element, candidate, sourceKind) {
  const { title, info } = candidate;
  const meta = info.extmetadata || {};
  const licenseShortName = plainText(meta.LicenseShortName?.value || "");
  const licenseUrl = meta.LicenseUrl?.value || "";
  const artist = plainText(meta.Artist?.value || meta.Credit?.value || "");
  const description = plainText(meta.ImageDescription?.value || "");
  const filePage = "https://commons.wikimedia.org/wiki/" + encodeURIComponent(title.replace(/ /g, "_"));

  return {
    z: element.z,
    symbol: element.symbol,
    nameDe: element.nameDe,
    nameEn: element.nameEn,
    imageUrl: info.thumburl || info.url,
    originalUrl: info.url,
    width: info.thumbwidth || info.width || null,
    height: info.thumbheight || info.height || null,
    mime: info.mime || "",
    fileTitle: title,
    filePage,
    galleryPage: COMMONS_GALLERY_BASE + encodeURIComponent(element.nameEn.toLowerCase()),
    license: licenseShortName,
    licenseUrl,
    artist,
    description,
    publicDomainLike: isPublicDomainLike(licenseShortName),
    rightsMode: STRICT_LICENSE_MODE,
    sourceKind
  };
}

/**
 * Liefert ein Wikimedia-Commons-Bild, aber nur wenn dessen konkrete Datei
 * als Public Domain oder CC0 gekennzeichnet ist.
 *
 * @param {string} symbol Elementsymbol, z. B. "W", "Fe", "O"
 * @param {object} options
 * @param {boolean} options.forceRefresh Cache ignorieren
 * @returns {Promise<object>}
 */
async function getElementBild(symbol, options = {}) {
  const element = ELEMENTE.find(e => e.symbol === symbol);
  if (!element) throw new Error(`Unbekanntes Elementsymbol: ${symbol}`);

  if (!options.forceRefresh) {
    const cached = cacheRead(symbol);
    if (cached && cached.publicDomainLike) return cached;
  }

  let titles = [];
  let sourceKind = "commons-gallery";

  try {
    titles = await galleryImageTitles(element, 120);
  } catch (e) {
    console.warn("Commons-Galerie konnte nicht gelesen werden:", e);
  }

  // Fallback, falls die Galerie keine brauchbaren Mediendateien liefert.
  if (titles.length < 3) {
    sourceKind = "commons-search";
    titles = await searchImageTitles(element, 30);
  }

  // Nur Bilddateien, keine Audio-/Video-Dateien.
  titles = [...new Set(titles)].filter(t =>
    /\.(jpe?g|png|webp|gif|tiff?|svg)$/i.test(t)
  );

  let infos = await fetchImageInfos(titles.slice(0, 120));

  let candidates = infos
    .map(c => ({ ...c, score: scoreCandidate(c.title, c.info, element) }))
    .filter(c => c.score > -1000);

  candidates = candidates.filter(c =>
    isPublicDomainLike(c.info?.extmetadata?.LicenseShortName?.value || "")
  );

  candidates.sort((a, b) => b.score - a.score);

  // Wenn aus der Galerie nichts passt, gezielte Commons-Suche versuchen.
  if (!candidates.length && sourceKind !== "commons-search") {
    sourceKind = "commons-search";
    const searchTitles = await searchImageTitles(element, 30);
    infos = await fetchImageInfos(
      [...new Set(searchTitles)].filter(t => /\.(jpe?g|png|webp|gif|tiff?|svg)$/i.test(t))
    );
    candidates = infos
      .map(c => ({ ...c, score: scoreCandidate(c.title, c.info, element) }))
      .filter(c => c.score > -1000);

    candidates = candidates.filter(c =>
      isPublicDomainLike(c.info?.extmetadata?.LicenseShortName?.value || "")
    );
    candidates.sort((a, b) => b.score - a.score);
  }

  if (!candidates.length) {
    const fallback = {
      z: element.z,
      symbol: element.symbol,
      nameDe: element.nameDe,
      nameEn: element.nameEn,
      imageUrl: null,
      originalUrl: null,
      fileTitle: null,
      filePage: null,
      galleryPage: COMMONS_GALLERY_BASE + encodeURIComponent(element.nameEn.toLowerCase()),
      license: null,
      licenseUrl: null,
      artist: null,
      description: "Kein geeignetes Public-Domain/CC0-Foto gefunden. Bitte Elementsymbol-Platzhalter verwenden.",
      publicDomainLike: false,
      rightsMode: STRICT_LICENSE_MODE,
      sourceKind: "symbol-fallback"
    };
    cacheWrite(symbol, fallback);
    return fallback;
  }

  const result = normalizeResult(element, candidates[0], sourceKind);
  cacheWrite(symbol, result);
  return result;
}

/**
 * Erzeugt eine transparente Quellen-/Lizenzzeile fuer die Anzeige im Spiel.
 * Auch bei Public Domain/CC0 wird die Commons-Quelle dokumentiert.
 */
function bildNachweis(bild) {
  if (!bild || !bild.imageUrl) return "Kein Foto verfügbar";
  return [
    "Wikimedia Commons",
    bild.license,
    bild.artist
  ].filter(Boolean).join(" · ");
}

/**
 * Prüft alle 118 Elemente mit begrenzter Parallelität.
 * Ergebnis: Array mit Bild- oder Fallback-Objekten.
 */
async function getAlleElementBilder(options = {}) {
  const concurrency = Math.max(1, Math.min(Number(options.concurrency) || 4, 8));
  const forceRefresh = Boolean(options.forceRefresh);
  const queue = [...ELEMENTE];
  const results = [];

  async function worker() {
    while (queue.length) {
      const e = queue.shift();
      const bild = await getElementBild(e.symbol, { forceRefresh });
      results.push(bild);
      if (typeof options.onProgress === "function") {
        options.onProgress(results.length, ELEMENTE.length, bild);
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, () => worker()));
  return results.sort((a, b) => a.z - b.z);
}

/**
 * HTML-sicherer Symbol-Fallback fuer Elemente ohne geeignete Abbildung.
 */
function symbolFallback(elementOrSymbol) {
  const e = typeof elementOrSymbol === "string"
    ? ELEMENTE.find(x => x.symbol === elementOrSymbol)
    : elementOrSymbol;

  if (!e) return { symbol: "?", nameDe: "Unbekannt", z: "?" };
  return { symbol: e.symbol, nameDe: e.nameDe, z: e.z };
}

// Fuer klassische <script>-Einbindung ohne Module kann man optional selbst
// window.elementBilder = { ELEMENTE, getElementBild, getAlleElementBilder, bildNachweis, symbolFallback }
// setzen. Die Datei ist standardmaessig als ES-Modul gedacht.


// Klassische Browser-Schnittstelle fuer Elementenpuzzle / Elementarium.
window.ElementBilderPD = Object.freeze({
  ELEMENTE,
  getElementBild,
  getAlleElementBilder,
  bildNachweis,
  symbolFallback,
  rightsMode: STRICT_LICENSE_MODE
});
