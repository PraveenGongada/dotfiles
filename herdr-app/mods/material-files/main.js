import { View, div, svg, image } from "gpui-kit";
import ICONS from "./icons.js";
import { v_flex, h_flex } from "gpui-base";
import { spaces, panes, focused, home, exec, watchFolder, theme, window, run, setShared, layout, checking } from "herdr";

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  if (f?.pane === null && f.terminal) return { cwd: f.cwd, on: f.terminal.includes("/") ? f.terminal.split("/")[0] : null, space: space?.id };
  const order = new Map((space?.tabs ?? []).map((t, i) => [t.id, t.active ? -1 : i]));
  const terminals = panes().filter((p) => p.terminal && p.cwd && order.has(p.tab)).sort((a, b) => order.get(a.tab) - order.get(b.tab));
  const atHome = !space?.folder || space.folder === "~" || (!space.machine && space.folder === home());
  const folder = atHome ? null : space.folder;
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  if (pane?.terminal || f?.terminal) return { cwd: pane?.cwd || f?.cwd || null, on: space?.machine ?? null, space: space?.id };
  return { cwd: terminals[0]?.cwd || folder || pane?.cwd || f?.cwd || space?.folder, on: space?.machine ?? null, space: space?.id };
}
const key = () => JSON.stringify(location());

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

function openPreview({ root, path, on }) {
  const space = spaces().find((s) => s.active);
  if (!space || !root || !path) return;
  const name = path.split("/").pop(), target = { root, path, on: on ?? null, space: space.id, n: Date.now() };
  const existing = space.tabs.find((tab) => panes().some((p) => p.tab === tab.id && p.mod === "md-preview"));
  if (!existing) { run("tab.new", { name, mod: "md-preview", props: target, focus: true }); return; }
  setShared("md-preview.target", target);
  run("tab.select", { id: existing.id });
  if (existing.name !== name) run("tab.rename", { id: existing.id, name });
}

const PER_FOLDER = 500, TOTAL = 5000;
const GIT = { M: "#E2C08D", A: "#73C991", D: "#c74e39", U: "#e4676b" };

function iconFor(name, dir, open) {
  const lower = name.toLowerCase();
  if (dir) return (open ? ICONS.foldersOpen[lower] : ICONS.folders[lower]) ?? (open ? ICONS.folderOpen : ICONS.folder);
  if (ICONS.names[lower]) return ICONS.names[lower];
  const parts = lower.split(".");
  for (let i = 1; i < parts.length; i++) {
    const hit = ICONS.ext[parts.slice(i).join(".")];
    if (hit) return hit;
  }
  return ICONS.file;
}

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

function shown() {
  const root = layout(), sidebar = find(root, "sidebar");
  return Boolean(window()?.active && sidebar && !sidebar.hidden && find(root, "sidebar-body")?.active === "files");
}

async function directory(path, on) {
  const script = 'n=0; for p in "$1"/* "$1"/.[!.]* "$1"/..?*; do [ -e "$p" ] || [ -L "$p" ] || continue; name=${p##*/}; [ "$name" = .git ] && continue; if [ -d "$p" ]; then kind=d; else kind=f; fi; printf "%s\\0%s\\0" "$kind" "$name"; n=$((n+1)); [ "$n" -gt 500 ] && break; done; test -d "$1"';
  const r = await exec("sh", ["-c", script, "files", path], { on });
  if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
  const fields = r.stdout.split("\0"), out = [];
  for (let i = 0; i + 1 < fields.length; i += 2) out.push({ name: fields[i + 1], dir: fields[i] === "d" });
  return out;
}

export default class Files extends View {
  init(_props, cx) {
    this.saved = new Map();
    this.entries = new Map(); this.folders = new Set(); this.pending = new Set(); this.marks = {}; this.dirMarks = new Map();
    if (checking()) return;
    cx.timer.every(10000, cx => { if (this.on) this.refresh(cx); });
  }

  async close() {
    this.unwatch();
  }

  unwatch() {
    this.watching?.cancel();
    this.watching = null; this.watched = null;
  }

  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.unwatch();
    this.watched = root;
    let current = watchFolder(root);
    this.watching = current;
    cx.spawn(async cx => {
      try {
        for (;;) {
          await current;
          if (this.watching !== current) return;
          if (!this.queued) {
            this.queued = true;
            cx.timer.after(300, cx => { this.queued = false; this.refresh(cx); });
          }
          current = watchFolder(root);
          this.watching = current;
        }
      } catch { if (this.watching === current) this.unwatch(); }
    });
  }

  current(context) {
    return this.context === context && key() === context.key;
  }

  async loadFolder(path, context) {
    const { on, cwd: root } = context;
    const entries = await directory(path ? `${root}/${path}` : root, on);
    if (!this.current(context) || (path && !this.folders.has(path))) return;
    const used = [...this.entries.entries()].filter(([p]) => p !== path).reduce((n, [, e]) => n + e.length, 0);
    this.entries.set(path, entries.slice(0, Math.max(0, Math.min(PER_FOLDER, TOTAL - used))).sort((a, b) => Number(b.dir) - Number(a.dir) || a.name.localeCompare(b.name)));
    if (entries.length > PER_FOLDER || used + entries.length > TOTAL) this.limited = true;
  }

  refresh(cx) {
    if (!shown()) { this.live = false; this.unwatch(); return; }
    const { cwd, on } = location(), next = key();
    if (next !== this.context?.key) {
      if (this.context) this.saved.set(this.context.key, { folders: this.folders });
      const saved = this.saved.get(next);
      this.unwatch();
      this.context = { key: next, cwd, on }; this.root = cwd; this.on = on; this.entries = new Map(); this.folders = new Set(saved?.folders);
      this.pending = new Set(); this.marks = {}; this.dirMarks = new Map(); this.error = null; this.limited = false;
      this.loading = false; this.again = false;
    }
    if (!cwd) return;
    if (this.loading) { this.again = true; return; }
    const context = this.context;
    this.loading = true;
    this.limited = false;
    cx.spawn(async cx => {
      try {
        for (const path of ["", ...this.folders]) {
          if (!this.current(context)) return;
          await this.loadFolder(path, context);
        }
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on }).catch(() => null);
        const marks = {};
        if (top?.code === 0) {
          const status = await exec("git", ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all"], { cwd, on }).catch(() => null);
          if (status?.code === 0) for (const entry of status.stdout.split("\0").filter(Boolean).slice(0, TOTAL)) {
            const xy = entry.slice(0, 2);
            marks[`${top.stdout.trim()}/${entry.slice(3)}`] = xy === "??" || xy.includes("A") ? "A" : xy.includes("U") ? "U" : xy.includes("D") ? "D" : "M";
          }
        }
        if (!this.current(context)) return;
        this.marks = marks; this.dirMarks = this.folderMarks(marks, cwd); this.error = null; this.watch(cwd, cx);
      } catch (e) { if (this.current(context)) this.error = String(e); }
      finally {
        if (this.context === context) {
          this.loading = false;
          if (this.again) { this.again = false; this.refresh(cx); }
        }
        cx.notify();
      }
    });
  }

  folderMarks(marks, root) {
    const out = new Map();
    for (const [file, mark] of Object.entries(marks)) {
      if (!file.startsWith(root + "/")) continue;
      const parts = file.slice(root.length + 1).split("/");
      for (let i = 1; i < parts.length; i++) {
        const dir = parts.slice(0, i).join("/");
        if (out.get(dir) !== "M") out.set(dir, mark === "A" ? "A" : "M");
      }
    }
    return out;
  }

  toggle(path, cx) {
    if (this.folders.has(path)) {
      for (const folder of [...this.folders]) if (folder === path || folder.startsWith(path + "/")) {
        this.folders.delete(folder);
        this.entries.delete(folder);
      }
    } else {
      this.folders.add(path);
      if (!this.entries.has(path) && !this.pending.has(path)) {
        const context = this.context;
        this.pending.add(path);
        cx.spawn(async cx => {
          try { await this.loadFolder(path, context); }
          catch (e) { if (this.current(context)) this.error = String(e); }
          finally { if (this.context === context) this.pending.delete(path); cx.notify(); }
        });
      }
    }
    cx.notify();
  }

  rows(prefix, depth, out, t) {
    if (out.length >= TOTAL || depth > 40) return out;
    for (const entry of this.entries.get(prefix) ?? []) {
      if (out.length >= TOTAL) break;
      const path = prefix ? `${prefix}/${entry.name}` : entry.name, open = this.folders.has(path), mark = this.marks[`${this.root}/${path}`] ?? (entry.dir ? this.dirMarks.get(path) : undefined);
      out.push(h_flex().id(`file-${path}`).h(28).flex_none().pl(8 + depth * 18).pr(8).gap(7).items_center().rounded(7).cursor_pointer().hover(s => s.bg(t.hover))
        .on_click((_e, cx) => entry.dir ? this.toggle(path, cx) : /\.(md|markdown)$/i.test(path) ? openPreview({ root: this.root, on: this.on, path }) : cx.spawn(async () => openInNvim({ root: this.root, on: this.on, path })))
        .child(entry.dir ? svg(`mods/material-files/chevron-${open ? "down" : "right"}.svg`).size(12).flex_none().text_color(t.dim) : div().w(12).flex_none())
        .child(image(`mods/material-files/material/${iconFor(entry.name, entry.dir, open)}.svg`).size(16).flex_none())
        .child(div().flex_1().min_w(0).truncate().when(Boolean(mark), el => el.text_color(GIT[mark])).when(mark === "D" && !entry.dir, el => el.line_through()).child(entry.name))
        .when(Boolean(mark), el => el.child(div().text_size(11).font_semibold().text_color(entry.dir ? GIT[mark] + "66" : GIT[mark]).child(entry.dir ? "●" : mark))));
      if (entry.dir && open) this.rows(path, depth + 1, out, t);
    }
    return out;
  }

  render(cx) {
    const live = shown();
    if (live !== this.live || (live && key() !== this.context?.key)) {
      this.live = live;
      if (live) this.refresh(cx); else this.unwatch();
    }
    const t = theme();
    return v_flex().id("files").size_full().min_h(0).overflow_hidden().bg(t.chrome).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().pl(8).pr(14).gap(6).items_center().border_b(1).border_color(t.border)
        .child(div().id("files-back").size(22).flex_none().flex().items_center().justify_center().rounded(6).text_color(t.muted)
          .hover(s => s.bg(t.hover).text_color(t.foreground)).tooltip("Back")
          .on_click(() => run("layout.select", { stack: "sidebar-body", child: "home" }))
          .child(svg("mods/workspace-chrome/chevron-left.svg").size(14)))
        .child(div().font_semibold().child("Files"))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(12).text_color(t.dim).child(this.root?.split(/[\\/]/).pop() ?? "")))
      .child(v_flex().id("files-tree").flex_1().min_h(0).overflow_y_scrollbar().p(6).children(this.rows("", 0, [], t))
        .when(Boolean(this.error) || !this.entries.get("")?.length, el => el.child(div().p(8).text_size(12).text_color(t.dim).child(this.error || (this.loading ? "Loading files…" : this.root ? "No files" : "No folder"))))
        .when(this.limited, el => el.child(div().p(8).text_size(11).text_color(t.dim).child("File list limited to 500 entries per folder and 5,000 total"))));
  }
}
