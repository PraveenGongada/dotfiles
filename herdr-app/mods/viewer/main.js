import { View, div, image } from "gpui-kit";
import { v_flex, h_flex, Scrollbar, v_virtual_list } from "gpui-base";
import { props, spaces, panes, run, exec, readTextFile, watchFolder, theme, settings, shared, setShared, checking } from "herdr";
import { untab, ROW, GUTTER, SPLIT_MIN, MAX_LINES, C, GIT, paint, langOf, iconFor, build } from "./engine.js";

const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];

async function openInNvim({ root, path, on, line }) {
  const space = spaces().find((s) => s.active);
  if (!space || !root || !path) return;
  const file = path.startsWith("/") ? path : `${root}/${path}`, where = { on: on ?? null };
  const sock = `/tmp/herdr-nvim-${space.id.replace(/[^A-Za-z0-9_-]/g, "_")}.sock`;
  const tab = space.tabs.find((x) => x.named && x.name === "nvim" && panes().some((p) => p.tab === x.id && p.terminal));
  if (tab) {
    const expr = `execute('stopinsert | edit ${line ? `+${line} ` : ""}' . fnameescape('${file.replace(/'/g, "''")}'))`;
    const r = await exec("nvim", ["--server", sock, "--remote-expr", expr], where).catch(() => null);
    if (r?.code === 0) { run("tab.select", { id: tab.id }); return; }
  }
  await exec("rm", ["-f", sock], where).catch(() => null);
  run("tab.new", { space: space.id, name: "nvim", folder: root, argv: ["nvim", "--listen", sock, ...(line ? [`+${line}`] : []), file] });
}

export default class Viewer extends View {
  init(_props, cx) {
    const p = props() ?? {};
    this.p = p;
    this.space = p.space ?? spaces().find((s) => s.active)?.id;
    this.key = p.key ?? `${this.space}|${p.name ?? p.path?.split("/").pop()}`;
    this.seen = shared("viewer.target")?.n;
    this.split = []; this.inline = []; this.widest = 40; this.width = 0; this.gen = 0;
    this.font = settings().font_family || undefined;
    this.fontSize = Number(settings().font_size) || 13;
    paint(theme());
    if (checking() || !p.path || !p.root) return;
    this.load(cx);
    this.watch(cx);
    cx.timer.every(15000, (cx) => { if (this.p.on) this.load(cx); });
  }

  async close() {
    this.watching?.cancel();
  }

  watch(cx) {
    this.watching?.cancel();
    this.watching = null;
    if (this.p.on || !this.p.root) return;
    const root = this.p.root;
    let current = watchFolder(root);
    this.watching = current;
    cx.spawn(async (cx) => {
      try {
        for (;;) {
          const changed = await current;
          if (this.watching !== current) return;
          if (this.touches(changed)) this.load(cx);
          current = watchFolder(root);
          this.watching = current;
        }
      } catch {}
    });
  }

  touches(changed) {
    const root = this.p.root, file = `${root}/${this.p.path}`;
    return changed.some((c) => c === root || c === file || (c.startsWith(`${root}/.git/`) && !c.includes("/.git/objects/")));
  }

  load(cx) {
    const p = this.p;
    if (this.loading === p) return;
    this.loading = p;
    cx.spawn(async (cx) => {
      try { await this.loadDiff(p); }
      catch (e) { if (this.p === p) this.error = `Cannot show this diff: ${e}`; }
      finally { if (this.loading === p) this.loading = null; cx.notify(); }
    });
  }

  show(target, cx) {
    const sameFile = target.path === this.p.path && target.root === this.p.root;
    if (sameFile && Boolean(target.staged) === Boolean(this.p.staged)) return;
    this.p = { ...target, key: this.key };
    if (!sameFile) this.watch(cx);
    this.scrollX = 0; this.split = []; this.inline = []; this.sig = null; this.status = null; this.error = null;
    this.add = 0; this.del = 0; this.widest = 40; this.gen++;
    this.load(cx);
    cx.notify();
  }

  command(cmd, cx) {
    if (cmd === "mode") {
      const split = this.isSplit(), mode = this.mode();
      setShared("vscode-diff.mode", mode === "auto" ? (split ? "inline" : "split") : mode === "split" ? "inline" : "split");
    } else if (cmd === "file") {
      const line = this.visibleLine();
      cx.spawn(async () => openInNvim({ root: this.p.root, on: this.p.on, path: this.p.path, line }));
    }
    cx.notify();
  }

  async loadDiff(p) {
    const { root, path, on } = p;
    const git = (args) => exec("git", [...READ, ...args], { cwd: root, on });
    const status = await git(["status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all", "--", path]);
    const xy = status.stdout.split("\0").filter(Boolean)[0]?.slice(0, 2) ?? "";
    if (this.p !== p) return;
    const X = xy[0] ?? " ", Y = xy[1] ?? " ", untracked = xy === "??";
    const letter = (c) => c === "?" ? "A" : c === "U" ? "U" : c === "D" ? "D" : c === "A" ? "A" : c && c !== " " ? "M" : null;
    const hasStaged = !untracked && X !== " " && X !== "", hasUnstaged = untracked || (Y !== " " && Y !== "");
    this.staged = Boolean(p.staged) ? hasStaged || !hasUnstaged : !hasUnstaged && hasStaged;
    this.status = xy.includes("U") ? "U" : letter(this.staged ? X : Y);
    let lines;
    if (!xy) lines = ["No changes: this file matches the last commit"];
    else if (this.status === "U") lines = ["Merge conflict: resolve it in the file (File button), then stage it"];
    else if (untracked) {
      const text = await readTextFile(`${root}/${path}`, { on }).catch(() => null);
      if (text === null) lines = ["Cannot preview this file (binary, too large, or unreadable)"];
      else if (text.includes("\0")) lines = ["Binary file · no text diff"];
      else {
        const body = text.slice(0, 2000000).replace(/\n$/, "").split("\n").slice(0, MAX_LINES);
        lines = [`@@ -0,0 +1,${body.length} @@`, ...body.map((l) => `+${l}`)];
      }
    } else {
      const r = await git(["diff", ...(this.staged ? ["--cached"] : []), "--no-ext-diff", "--no-textconv", "--no-color", "-U3", "--", path]);
      if (r.code !== 0) throw new Error(r.stderr);
      const all = r.stdout.replace(/\n$/, "").split("\n"), first = all.findIndex((l) => l.startsWith("@@"));
      lines = first < 0 ? [r.stdout.trim() ? "Binary file changed" : "No changes"] : all.slice(first);
    }
    if (this.p !== p) return;
    lines = lines.slice(0, MAX_LINES).map((line) => line.length > 2000 ? line.slice(0, 2000) + "…" : line);
    const sig = lines.join("\n");
    if (sig === this.sig) return;
    this.sig = sig; this.error = null;
    const { split, inline } = build(lines, langOf(path));
    this.split = split; this.inline = inline; this.gen++;
    this.add = lines.filter((l) => l[0] === "+").length; this.del = lines.filter((l) => l[0] === "-").length;
    this.widest = Math.max(40, ...lines.map((l) => untab(l).length));
    this.longestText = lines.reduce((best, l) => { const u = untab(l.slice(1)); return u.length > best.length ? u : best; }, "");
    this.longestPx = 0;
  }

  visibleLine() {
    const rows = this.isSplit() ? this.split : this.inline;
    const start = this.top ?? 0;
    for (let i = start; i < rows.length; i++) {
      const r = rows[i];
      const n = r.type !== "line" ? undefined : r.kind !== undefined ? r.new ?? r.old : r.r?.n ?? r.l?.n;
      if (n !== undefined) return n;
    }
    return undefined;
  }

  mode() { return shared("vscode-diff.mode") ?? "auto"; }
  oneSided() { return this.status === "A" || this.status === "D"; }
  isSplit() { const m = this.mode(); return !this.oneSided() && (m === "split" || (m === "auto" && this.width >= SPLIT_MIN)); }

  codeSpans(spans, word) {
    return div().flex_1().min_w(0).h_full().overflow_hidden()
      .child(h_flex().h_full().items_center().flex_none().whitespace_nowrap().ml(-(this.scrollX ?? 0))
        .children((spans ?? []).map((s) => div().flex_none().text_color(s.c).when(Boolean(s.h), (e) => e.bg(word)).child(s.t))));
  }

  pan(e, cx) {
    const shift = e.modifiers?.shift, now = Date.now(), g = this.gesture ??= { axis: null, x: 0, y: 0, at: 0 };
    if (e.touch_phase === "started" || now - g.at > 150) Object.assign(g, { axis: shift ? "x" : null, x: 0, y: 0 });
    g.at = now;
    if (!g.axis) {
      g.x += Math.abs(e.delta.x); g.y += Math.abs(e.delta.y);
      if (g.x + g.y < 6) return;
      g.axis = g.x > g.y * 2 ? "x" : "y";
    }
    if (g.axis !== "x") return;
    const dx = shift && !e.delta.x ? e.delta.y : e.delta.x;
    if (!dx) { cx.stop_propagation(); return; }
    const split = this.isSplit(), visible = split ? (this.width - 1) / 2 - GUTTER - 14 : this.width - (GUTTER - 8) * 2 - 16;
    const measured = this.longestPx || this.widest * 13 * 0.62;
    const max = Math.max(0, Math.ceil(measured) + 24 - visible);
    const next = Math.min(max, Math.max(0, (this.scrollX ?? 0) - dx));
    if (next !== this.scrollX) { this.scrollX = next; cx.notify(); }
    cx.stop_propagation();
  }

  half(side) {
    if (!side) return div().flex_1().w(0).min_w(0).h(ROW).bg(C.filler);
    const add = side.kind === "+", del = side.kind === "-";
    return h_flex().flex_1().w(0).min_w(0).h(ROW).overflow_hidden().when(add, (e) => e.bg(side.full ? C.addFull : C.addLine)).when(del, (e) => e.bg(side.full ? C.delFull : C.delLine))
      .child(div().w(GUTTER).flex_none().pr(10).text_right().text_color(add || del ? C.lineNoActive : C.lineNo).child(String(side.n)))
      .child(div().w(14).flex_none())
      .child(this.codeSpans(side.spans, add ? C.addWord : C.delWord));
  }

  row(row, split) {
    if (row.type === "hunk") return h_flex().w_full().h(ROW).flex_none().px(12).gap(8).items_center().bg(C.hunkBg).text_color(C.hunkFg)
      .child(div().flex_none().child("⋯")).child(div().flex_none().whitespace_nowrap().child(row.text));
    if (row.type === "note") return div().h(ROW).px(12).text_color(C.lineNo).child(row.text);
    if (split) return h_flex().w_full().h(ROW).flex_none().child(this.half(row.l)).child(div().w(1).flex_none().bg(C.border)).child(this.half(row.r));
    const add = row.kind === "+", del = row.kind === "-";
    const num = (n) => div().w(GUTTER - 8).flex_none().pr(8).text_right().text_color(add || del ? C.lineNoActive : C.lineNo).child(n === undefined ? "" : String(n));
    return h_flex().w_full().h(ROW).flex_none().when(add, (e) => e.bg(row.full ? C.addFull : C.addLine)).when(del, (e) => e.bg(row.full ? C.delFull : C.delLine))
      .child(h_flex().flex_none().when(!this.oneSided(), (e) => e.child(num(row.old))).child(num(this.status === "D" ? row.old : row.new)))
      .child(div().w(16).flex_none())
      .child(this.codeSpans(row.spans, add ? C.addWord : C.delWord));
  }

  header(t) {
    const parts = this.p.path.split("/"), name = parts.pop();
    const btn = (id, label, cmd) => div().id(id).px(7).h(20).flex().flex_none().items_center().rounded(4).border_1()
      .border_color(C.border).bg(C.fileBar).text_size(11).text_color(t.muted).cursor_pointer().hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => this.command(cmd, cx)).child(label);
    return h_flex().h(32).flex_none().pl(12).pr(8).gap(6).items_center().bg(C.fileBar).border_b(1).border_color(C.border).text_size(12)
      .child(image(`mods/material-files/material/${iconFor(this.p.path)}.svg`).size(15).flex_none())
      .child(div().flex_none().font_medium().text_color(this.status ? GIT[this.status] : C.fg).child(name))
      .child(div().flex_none().text_color(t.dim).child(this.staged ? "(Index)" : "(Working Tree)"))
      .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(parts.join("/")))
      .child(div().flex_none().text_color(C.addSign).child(`+${this.add ?? 0}`))
      .child(div().flex_none().text_color(C.delSign).child(`−${this.del ?? 0}`))
      .when(!this.oneSided(), (e) => e.child(btn("vh-mode", this.isSplit() ? "Side by side" : "Inline", "mode")))
      .child(btn("vh-file", "Open in nvim", "file"));
  }

  render(cx) {
    const target = shared("viewer.target");
    if (target && target.n !== this.seen && (target.key === this.key || (target.scope === "space" && target.space === this.space))) {
      this.seen = target.n;
      cx.timer.after(0, (cx) => this.show(target, cx));
    }
    const t = theme(), p = this.p;
    paint(t);
    if (!p.path) return div().size_full().p(16).bg(C.bg).text_color(t.dim).child("Nothing to show");
    const root = v_flex().id("viewer").size_full().min_h(0).bg(C.bg).text_color(C.fg).text_size(13)
      .on_size_change((size, cx) => {
        if (Math.abs(size.width - this.width) <= 1) return;
        this.width = size.width;
        cx.notify();
      })
      .child(this.header(t));
    const split = this.isSplit(), rows = split ? this.split : this.inline;
    const body = div().id("diff-body").flex_1().min_h(0).relative().text_size(this.fontSize).line_height(`${ROW}px`).when(Boolean(this.font), (e) => e.font_family(this.font));
    const status = (e) => e.when(Boolean(this.error) || (!rows.length && Boolean(this.loading)), (e) => e.child(div().absolute().top(10).px(14).text_color(t.dim).child(this.error || "Loading diff…")));
    return root
      .child(status(body
        .on_scroll_wheel((e, cx) => this.pan(e, cx))
        .child(div().absolute().top(0).left(0).h(0).overflow_hidden().opacity(0)
          .child(h_flex().id(`measure-${this.gen}`).flex_none().whitespace_nowrap().child(this.longestText || " ")
            .on_size_change((size) => { this.longestPx = size.width; })))
        .child(div().id(`diff-x-${this.gen}`).size_full()
          .child(div().w_full().h_full().child(v_virtual_list(`diff-${this.gen}`, rows.length, ROW, (i) => String(i),
            (range) => { this.top = range.start; return rows.slice(range.start, range.end).map((r) => this.row(r, split)); }).size_full())))
        .child(Scrollbar.vertical(`diff-${this.gen}`).viewport_from_layout().absolute().inset_0())));
  }
}
