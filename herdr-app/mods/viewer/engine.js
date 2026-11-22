import ICONS from "./icons.js";
export const untab = (text) => text.replace(/[^\t]*\t/g, (s) => s.slice(0, -1).padEnd((s.length - 1) - (s.length - 1) % 4 + 4));
export const ROW = 19, GUTTER = 46, SPLIT_MIN = 720, MAX_LINES = 3000;
export const C = {}, SYN = {}, GIT = {};
const hex = (c) => String(c ?? "#808080").slice(0, 7);
export function paint(t) {
  const sig = `${t.background}${t.foreground}${t.done}${t.ansi9}${t.ansi5}${t.accent}`;
  if (sig === paint.sig) return;
  paint.sig = sig;
  Object.assign(C, {
    bg: t.background, fg: t.foreground, lineNo: t.dim, lineNoActive: t.muted,
    addLine: "#9bb95533", addWord: "#9ccc2c33", addFull: "#384718", addSign: "#81b88b",
    delLine: "#ff000033", delWord: "#ff000033", delFull: "#5d0806", delSign: "#c74e39",
    filler: `${hex(t.foreground)}0D`, hunkBg: `${hex(t.accent)}1A`, hunkFg: t.accent, fileBar: t.chrome, border: t.border,
  });
  Object.assign(SYN, {
    control: t.ansi5, keyword: t.ansi5, fn: t.ansi4, type: t.ansi3, variable: t.foreground,
    string: t.ansi2, number: t.ansi1, comment: t.dim, key: t.ansi6, tag: t.ansi4,
  });
  Object.assign(GIT, { M: "#E2C08D", A: "#73C991", D: "#c74e39", U: "#e4676b" });
}

const CONTROL = new Set("if else elif for while do switch case default break continue return import export from as try catch finally throw await yield defer go select range match loop with in of then end until repeat goto raise except pass del fi done esac require".split(" "));
const KEYWORD = new Set("const let var function class extends implements interface type enum struct func def fn pub impl mod use package local new this self super static async public private protected readonly true false null nil None True False undefined void typeof instanceof and or not is lambda chan crate where trait mut ref unsafe dyn final override abstract".split(" "));
const HASH = new Set("py sh bash zsh fish yaml yml toml rb conf nix r pl makefile dockerfile gitignore env ini cfg zshrc bashrc zprofile zshenv profile brewfile tf hcl gemfile rakefile procfile".split(" "));
const DASH = new Set("lua sql hs elm".split(" "));
const NONE = new Set("json jsonc txt csv lock svg xml html".split(" "));
export function langOf(path) {
  const name = path.split("/").pop().toLowerCase();
  if (name === "makefile" || name === "dockerfile" || name === "brewfile" || name === "gemfile") return name;
  const dot = name.lastIndexOf(".");
  return dot >= 0 ? name.slice(dot + 1) : name;
}

export function iconFor(path) {
  const lower = path.split("/").pop().toLowerCase();
  if (ICONS.names[lower]) return ICONS.names[lower];
  const parts = lower.split(".");
  for (let i = 1; i < parts.length; i++) {
    const hit = ICONS.ext[parts.slice(i).join(".")];
    if (hit) return hit;
  }
  return ICONS.file;
}

export function highlight(text, lang, state) {
  const out = [], push = (t, c) => { if (!t) return; const last = out[out.length - 1]; if (last && last.c === c) last.t += t; else out.push({ t, c }); };
  if (lang === "md" || lang === "markdown") {
    if (/^\s*#{1,6}\s/.test(text)) push(text, SYN.tag);
    else text.split(/(`[^`]*`)/).forEach((p) => push(p, p.startsWith("`") && p.endsWith("`") && p.length > 1 ? SYN.string : C.fg));
    return out;
  }
  const hash = HASH.has(lang), dash = DASH.has(lang), slash = !hash && !dash && !NONE.has(lang);
  const yamlish = lang === "yaml" || lang === "yml" || lang === "toml";
  let i = 0;
  if (yamlish) {
    const m = /^(\s*(?:-\s+)?)([\w.\-"'\[\]]+)(\s*[:=])/.exec(text);
    if (m && !text.trimStart().startsWith("#")) { push(m[1], C.fg); push(m[2], lang === "toml" ? SYN.key : SYN.tag); push(m[3], C.fg); i = m[0].length; }
  }
  while (i < text.length) {
    if (state.block) {
      const end = text.indexOf("*/", i);
      if (end < 0) { push(text.slice(i), SYN.comment); return out; }
      push(text.slice(i, end + 2), SYN.comment); i = end + 2; state.block = false; continue;
    }
    const rest = text.slice(i), ch = text[i];
    if ((slash && rest.startsWith("//")) || (hash && ch === "#" && (i === 0 || /\s/.test(text[i - 1]))) || (dash && rest.startsWith("--"))) { push(rest, SYN.comment); break; }
    if (slash && rest.startsWith("/*")) { state.block = true; push("/*", SYN.comment); i += 2; continue; }
    if (ch === '"' || ch === "'" || ch === "`") {
      let j = i + 1;
      while (j < text.length && text[j] !== ch) j += text[j] === "\\" ? 2 : 1;
      const s = text.slice(i, Math.min(j + 1, text.length));
      const isKey = /^\s*:/.test(text.slice(j + 1)) && (lang === "json" || lang === "jsonc" || slash);
      push(s, isKey ? SYN.key : SYN.string); i += s.length; continue;
    }
    const num = /^(?:0x[0-9a-fA-F_]+|\d[\d_]*(?:\.\d+)?(?:[eE][+-]?\d+)?)/.exec(rest);
    if (num && !/[\w$]/.test(text[i - 1] ?? "")) { push(num[0], SYN.number); i += num[0].length; continue; }
    const id = /^[A-Za-z_$@][\w$]*/.exec(rest);
    if (id) {
      const w = id[0], after = text.slice(i + w.length);
      const color = NONE.has(lang) ? C.fg : CONTROL.has(w) ? SYN.control : KEYWORD.has(w) ? SYN.keyword : /^\s*\(/.test(after) ? SYN.fn
        : /^[A-Z][a-z0-9]/.test(w) || /^[A-Z]$/.test(w) ? SYN.type : SYN.variable;
      push(w, color); i += w.length; continue;
    }
    push(ch, C.fg); i++;
  }
  return out;
}

export function wordRanges(a, b) {
  const ta = a.match(/\w+|\s+|[^\w\s]/g) ?? [], tb = b.match(/\w+|\s+|[^\w\s]/g) ?? [];
  if (!ta.length || !tb.length || ta.length * tb.length > 60000) return null;
  const n = ta.length, m = tb.length, dp = Array.from({ length: n + 1 }, () => new Uint16Array(m + 1));
  for (let x = n - 1; x >= 0; x--) for (let y = m - 1; y >= 0; y--)
    dp[x][y] = ta[x] === tb[y] ? dp[x + 1][y + 1] + 1 : Math.max(dp[x + 1][y], dp[x][y + 1]);
  const keepA = new Array(n).fill(false), keepB = new Array(m).fill(false);
  let x = 0, y = 0, same = 0;
  while (x < n && y < m) {
    if (ta[x] === tb[y]) { keepA[x] = keepB[y] = true; if (/\S/.test(ta[x])) same += ta[x].length; x++; y++; }
    else if (dp[x + 1][y] >= dp[x][y + 1]) x++; else y++;
  }
  if (same < Math.min(a.trim().length, b.trim().length) * 0.25) return null;
  const ranges = (tokens, keep) => {
    const r = []; let pos = 0;
    tokens.forEach((t, k) => { if (!keep[k]) { const last = r[r.length - 1]; if (last && last[1] === pos) last[1] += t.length; else r.push([pos, pos + t.length]); } pos += t.length; });
    return r;
  };
  return [ranges(ta, keepA), ranges(tb, keepB)];
}

function mark(spans, ranges) {
  if (!ranges?.length) return spans;
  const out = []; let pos = 0;
  for (const s of spans) {
    const end = pos + s.t.length, cuts = new Set([0, s.t.length]);
    for (const [a, b] of ranges) { if (a > pos && a < end) cuts.add(a - pos); if (b > pos && b < end) cuts.add(b - pos); }
    const sorted = [...cuts].sort((p, q) => p - q);
    for (let k = 0; k + 1 < sorted.length; k++) {
      const at = pos + sorted[k];
      out.push({ t: s.t.slice(sorted[k], sorted[k + 1]), c: s.c, h: ranges.some(([a, b]) => at >= a && at < b) });
    }
    pos = end;
  }
  return out;
}

export function build(lines, lang) {
  const split = [], inline = [];
  let old = 0, next = 0, sOld = {}, sNew = {}, dels = [], adds = [], lastOldEnd = 1;
  const side = (n, text, kind, state) => ({ n, kind, spans: highlight(text, lang, state), text });
  const flush = () => {
    const pairs = Math.max(dels.length, adds.length);
    for (let k = 0; k < pairs; k++) {
      const l = dels[k] ?? null, r = adds[k] ?? null;
      const w = l && r ? wordRanges(l.text, r.text) : null;
      if (w) { l.spans = mark(l.spans, w[0]); r.spans = mark(r.spans, w[1]); }
      if (l) l.full = !w;
      if (r) r.full = !w;
      split.push({ type: "line", l, r });
    }
    for (const l of dels) inline.push({ type: "line", kind: "-", old: l.n, spans: l.spans, full: l.full });
    for (const r of adds) inline.push({ type: "line", kind: "+", new: r.n, spans: r.spans, full: r.full });
    dels = []; adds = [];
  };
  for (const raw of lines) {
    const hunk = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,\d+)? @@(.*)$/.exec(raw);
    if (hunk) {
      flush();
      old = +hunk[1]; next = +hunk[3]; sOld = {}; sNew = {};
      const hidden = Math.max(0, old - lastOldEnd);
      const row = { type: "hunk", text: (hidden > 0 ? `${hidden} unchanged line${hidden === 1 ? "" : "s"}` : "") + (hunk[4].trim() ? `  ·  ${hunk[4].trim()}` : "") };
      if (row.text) { split.push(row); inline.push(row); }
      continue;
    }
    const kind = raw[0], text = untab(raw.slice(1));
    if (kind === "-") dels.push(side(old++, text, "-", sOld));
    else if (kind === "+") adds.push(side(next++, text, "+", sNew));
    else if (kind === " ") {
      flush();
      const l = side(old++, text, " ", sOld), r = side(next++, text, " ", sNew);
      split.push({ type: "line", l, r }); inline.push({ type: "line", kind: " ", old: l.n, new: r.n, spans: r.spans });
      lastOldEnd = old;
    } else if (raw.startsWith("\\")) continue;
    else { flush(); split.push({ type: "note", text: raw }); inline.push({ type: "note", text: raw }); }
  }
  flush();
  return { split, inline };
}

