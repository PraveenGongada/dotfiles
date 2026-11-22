import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex, Scrollbar } from "gpui-base";
import { spaces, panes, focused, home, exec, watchFolder, theme, run, shared, setShared, openOverlay, checking, layout, window } from "herdr";
import ICONS from "./icons.js";

const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];
const GIT = {}, K = {};
function paint(t) {
  Object.assign(GIT, { M: "#E2C08D", A: "#73C991", D: "#c74e39", U: "#e4676b" });
  Object.assign(K, { add: "#81b88b", del: "#c74e39", border: t.border });
}

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

function iconFor(path) {
  const lower = path.split("/").pop().toLowerCase();
  if (ICONS.names[lower]) return ICONS.names[lower];
  const parts = lower.split(".");
  for (let i = 1; i < parts.length; i++) {
    const hit = ICONS.ext[parts.slice(i).join(".")];
    if (hit) return hit;
  }
  return ICONS.file;
}

function openViewer(target) {
  const space = spaces().find((s) => s.active);
  if (!space || !target.root || !target.path) return;
  const name = target.path.split("/").pop();
  const existing = space.tabs.find((tab) => panes().some((p) => p.tab === tab.id && p.mod === "viewer"));
  const t = { ...target, space: space.id, name, key: `${space.id}|changes`, scope: "space", n: Date.now() };
  if (!existing) { run("tab.new", { name, mod: "viewer", props: t, focus: true }); return; }
  setShared("viewer.target", t);
  run("tab.select", { id: existing.id });
  if (existing.name !== name) run("tab.rename", { id: existing.id, name });
}

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
  return Boolean(window()?.active && sidebar && !sidebar.hidden && find(root, "sidebar-body")?.active === "changes");
}

const letter = (c) => c === "?" ? "A" : c === "U" ? "U" : c === "D" ? "D" : c === "A" ? "A" : "M";
const LIMIT = 1000;

async function numstat(git, args) {
  const out = {};
  const r = await git(["diff", ...args, "--numstat", "-z", "--no-renames"]);
  if (r.code !== 0) return out;
  for (const entry of r.stdout.split("\0")) {
    const [a, d, ...parts] = entry.split("\t");
    if (parts.length) out[parts.join("\t")] = { add: Number(a) || 0, del: Number(d) || 0 };
  }
  return out;
}

export default class Changes extends View {
  init(_props, cx) {
    this.staged = []; this.unstaged = []; this.collapsed = new Set(); this.hover = null;
    this.handle = cx.focus_handle();
    if (checking()) return;
    cx.timer.every(10000, (cx) => { if (this.on) this.refresh(cx); });
  }

  visible() {
    const out = [];
    if (!this.collapsed.has("staged")) for (const f of this.staged) out.push({ f, staged: true });
    if (!this.collapsed.has("changes")) for (const f of this.unstaged) out.push({ f, staged: false });
    return out;
  }

  keyDown(e, cx) {
    const m = e.modifiers ?? {}, plain = !m.control && !m.platform && !m.alt;
    const list = this.visible(), id = (x) => `${x.staged ? "s" : "w"}:${x.f.path}`;
    const cur = list.find((x) => id(x) === this.open) ?? null;
    if (plain && e.key === "enter" && cur && cur.f.status !== "D") {
      const { f, staged } = cur;
      cx.spawn(async () => { await openInNvim({ root: this.root, on: this.on, path: f.path, line: f.untracked ? undefined : await this.firstChange(f.path, staged) }); });
    } else if (plain && e.key === "s" && cur && !cur.staged && cur.f.status !== "U") this.git(["add", "--", cur.f.path], cx);
    else if (plain && e.key === "u" && cur && cur.staged) this.git(["restore", "--staged", "--", cur.f.path], cx);
    else if (plain && e.key === "d" && cur && !cur.staged && cur.f.status !== "U") this.discard(cur.f);
    else return;
    cx.stop_propagation();
    cx.notify();
  }

  discard(f) {
    const untracked = f.untracked, name = f.path.split("/").pop();
    const title = untracked ? `Delete ${name}?` : `Discard changes in ${name}?`;
    const detail = untracked ? `${f.path} is untracked, so deleting it can't be undone.` : `Your unstaged changes to ${f.path} will be lost. This can't be undone.`;
    const args = untracked ? ["clean", "-f", "--", f.path] : ["restore", "--", f.path];
    openOverlay({ mod: "my-confirm", kind: "dialog", width: 460, height: 190, props: { title, detail, exec: { command: "git", args, cwd: this.root, on: this.on ?? null } } });
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
    cx.spawn(async (cx) => {
      try {
        for (;;) {
          await current;
          if (this.watching !== current) return;
          if (!this.queued) {
            this.queued = true;
            cx.timer.after(300, (cx) => { this.queued = false; this.refresh(cx); });
          }
          current = watchFolder(root);
          this.watching = current;
        }
      } catch { if (this.watching === current) this.unwatch(); }
    });
  }

  async close() {
    this.unwatch();
  }

  refresh(cx) {
    if (!shown()) { this.live = false; this.unwatch(); return; }
    if (this.loading) { this.again = true; return; }
    const { cwd, on } = location(), context = key();
    if (context !== this.context) { this.context = context; this.root = null; this.staged = []; this.unstaged = []; this.error = null; this.unwatch(); }
    if (!cwd) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (key() !== context) return;
        if (top.code !== 0) { this.root = null; this.staged = []; this.unstaged = []; this.error = `Not a git repository: ${cwd}`; return; }
        const root = top.stdout.trim(), git = (args) => exec("git", [...READ, ...args], { cwd: root, on });
        const status = await git(["status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all"]);
        if (status.code !== 0) throw new Error(status.stderr);
        const [stagedStats, workStats] = await Promise.all([numstat(git, ["--cached"]), numstat(git, [])]);
        const staged = [], unstaged = [], all = status.stdout.split("\0").filter(Boolean), counts = { M: 0, A: 0, D: 0, U: 0 };
        for (const entry of all) {
          const X = entry[0], Y = entry[1], path = entry.slice(3), conflict = X === "U" || Y === "U" || entry.startsWith("AA") || entry.startsWith("DD");
          counts[conflict ? "U" : letter(Y !== " " ? Y : X)]++;
          if (conflict) { if (unstaged.length < LIMIT) unstaged.push({ path, status: "U", add: 0, del: 0 }); continue; }
          if (X !== " " && X !== "?" && staged.length < LIMIT) staged.push({ path, status: letter(X), ...(stagedStats[path] ?? { add: 0, del: 0 }) });
          if (Y !== " " && unstaged.length < LIMIT) unstaged.push({ path, status: letter(Y), untracked: Y === "?", ...(workStats[path] ?? { add: 0, del: 0 }) });
        }
        if (key() !== context) return;
        this.root = root; this.on = on; this.staged = staged; this.unstaged = unstaged; this.counts = counts; this.total = all.length; this.error = null;
        if (shared("git.changes") !== all.length) setShared("git.changes", all.length);
        this.watch(root, cx);
      } catch (e) { if (key() === context) this.error = String(e); }
      finally {
        this.loading = false; cx.notify();
        if (this.again) { this.again = false; this.refresh(cx); }
      }
    });
  }

  git(args, cx) {
    if (!this.root) return;
    const root = this.root, on = this.on;
    cx.spawn(async (cx) => {
      const r = await exec("git", args, { cwd: root, on }).catch((e) => ({ code: 1, stderr: String(e) }));
      this.note = r.code === 0 ? null : (r.stderr || r.stdout || "git failed").trim().split("\n")[0];
      this.refresh(cx); cx.notify();
    });
  }

  action(id, label, onClick, t) {
    return div().id(id).size(20).flex().flex_none().items_center().justify_center().rounded(4).text_size(14).text_color(t.muted)
      .hover((s) => s.bg(t.selected).text_color(t.foreground))
      .on_click((_e, cx) => { cx.stop_propagation(); onClick(cx); }).child(typeof label === "string" ? svg(`mods/vscode-diff/${label}.svg`).size(14) : label);
  }

  fileRow(f, staged, t) {
    const parts = f.path.split("/"), name = parts.pop(), id = `${staged ? "s" : "w"}:${f.path}`, hovered = this.hover === id;
    const selected = this.open === id;
    return h_flex().id(`change-${id}`).h(26).flex_none().pl(16).pr(8).gap(6).items_center().rounded(4).cursor_pointer()
      .when(selected, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
      .on_hover((h, cx) => { this.hover = h ? id : this.hover === id ? null : this.hover; cx.notify(); })
      .on_click((_e, cx) => { this.open = id; openViewer({ kind: "diff", staged, root: this.root, on: this.on, path: f.path }); cx.notify(); })
      .child(image(`mods/material-files/material/${iconFor(f.path)}.svg`).size(16).flex_none())
      .child(div().min_w(24).max_w(200).truncate().text_color(GIT[f.status]).when(f.status === "D", (e) => e.line_through()).child(name))
      .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(parts.join("/")))
      .when(!hovered && f.add > 0, (e) => e.child(div().flex_none().text_size(11).text_color(K.add).child(`+${f.add}`)))
      .when(!hovered && f.del > 0, (e) => e.child(div().flex_none().text_size(11).text_color(K.del).child(`−${f.del}`)))
      .when(hovered && f.status !== "D", (e) => e.child(this.action(`open-${id}`, image(`mods/material-files/material/${iconFor(f.path)}.svg`).size(14), (cx) => {
        this.open = id;
        if (/\.(md|markdown)$/i.test(f.path)) return openPreview({ root: this.root, on: this.on, path: f.path });
        cx.spawn(async () => { await openInNvim({ root: this.root, on: this.on, path: f.path, line: f.untracked ? undefined : await this.firstChange(f.path, staged) }); });
      }, t)))
      .when(hovered && !staged && f.status !== "U", (e) => e.child(this.action(`discard-${id}`, "discard", () => this.discard(f), t)))
      .when(hovered && f.status !== "U", (e) => e.child(staged
        ? this.action(`unstage-${id}`, "minus", (cx) => this.git(["restore", "--staged", "--", f.path], cx), t)
        : this.action(`stage-${id}`, "plus", (cx) => this.git(["add", "--", f.path], cx), t)))
      .child(div().w(14).flex_none().text_right().text_size(12).font_semibold().text_color(GIT[f.status]).child(f.status));
  }

  section(id, title, files, staged, t) {
    const closed = this.collapsed.has(id), hovered = this.hover === `section:${id}`;
    const rows = [h_flex().id(`section-${id}`).h(24).flex_none().px(4).gap(4).items_center().rounded(4).cursor_pointer().hover((s) => s.bg(t.hover))
      .on_hover((h, cx) => { this.hover = h ? `section:${id}` : this.hover === `section:${id}` ? null : this.hover; cx.notify(); })
      .on_click((_e, cx) => { closed ? this.collapsed.delete(id) : this.collapsed.add(id); cx.notify(); })
      .child(div().size(16).flex_none().flex().items_center().justify_center().child(svg(`mods/vscode-diff/chevron-${closed ? "right" : "down"}.svg`).size(14).text_color(t.dim)))
      .child(div().flex_1().text_size(11).font_semibold().text_color(t.muted).child(title))
      .when(hovered && files.length > 0, (e) => e.child(staged
        ? this.action(`unstage-all`, "minus", (cx) => this.git(["restore", "--staged", "--", "."], cx), t)
        : this.action(`stage-all`, "plus", (cx) => this.git(["add", "-A", "--", "."], cx), t)))
      .child(div().px(5).h(15).min_w(15).flex().flex_none().items_center().justify_center().rounded(8).bg(t.raised).text_size(10).text_color(t.muted).child(String(files.length)))];
    if (!closed) for (const f of files) rows.push(this.fileRow(f, staged, t));
    return rows;
  }

  async firstChange(path, staged) {
    const r = await exec("git", [...READ, "diff", ...(staged ? ["--cached"] : []), "-U0", "--no-color", "--", path], { cwd: this.root, on: this.on }).catch(() => null);
    const m = /^@@ -\d+(?:,\d+)? \+(\d+)/m.exec(r?.stdout ?? "");
    return m ? Math.max(1, +m[1]) : undefined;
  }

  render(cx) {
    const live = shown();
    if (live !== this.live || (live && key() !== this.context)) {
      this.live = live;
      if (live) this.refresh(cx); else this.unwatch();
    }
    const t = theme(), every = [...this.staged, ...this.unstaged];
    paint(t);
    const add = every.reduce((n, f) => n + f.add, 0), del = every.reduce((n, f) => n + f.del, 0);
    const rows = [];
    const addSection = (id, title, files, staged) => rows.push(...this.section(id, title, files, staged, t));
    if (this.staged.length) { addSection("staged", "STAGED CHANGES", this.staged, true); rows.push(div().h(6).flex_none()); }
    if (this.unstaged.length || !this.staged.length) addSection("changes", "CHANGES", this.unstaged, false);
    return v_flex().id("vscode-diff").size_full().min_h(0).overflow_hidden().bg(t.chrome).text_color(t.foreground).text_size(13)
      .track_focus(this.handle).on_key_down((e, cx) => this.keyDown(e, cx))
      .child(h_flex().h(42).flex_none().pl(8).pr(14).gap(6).items_center().border_b(1).border_color(K.border)
        .child(div().id("git-back").size(22).flex_none().flex().items_center().justify_center().rounded(6).text_color(t.muted)
          .hover(s => s.bg(t.hover).text_color(t.foreground)).tooltip("Back")
          .on_click(() => run("layout.select", { stack: "sidebar-body", child: "home" }))
          .child(svg("mods/workspace-chrome/chevron-left.svg").size(14)))
        .child(div().font_semibold().child("Git"))
        .child(div().flex_1())
        .children(["M", "A", "D", "U"].map((k) => [k, this.counts?.[k] ?? 0]).filter(([, n]) => n > 0)
          .map(([k, n]) => div().text_size(11).font_medium().text_color(GIT[k]).child(`${n}${k}`)))
        .when(add > 0 || del > 0, (e) => e.child(div().w(1).h(12).mx(2).bg(K.border))
          .child(div().text_size(11).text_color(K.add).child(`+${add}`))
          .child(div().text_size(11).text_color(K.del).child(`−${del}`))))
      .when(Boolean(this.note), (e) => e.child(div().px(12).py(5).flex_none().text_size(11).text_color(K.del).child(this.note)))
      .child(div().flex_1().min_h(0).relative()
        .child(v_flex().id("changes-list").absolute().inset_0().overflow_y_scroll().p(5).children(every.length ? rows : [])
          .when(!every.length, (e) => e.child(div().p(6).text_color(t.dim).child(this.error || (this.loading ? "Loading changes…" : this.root ? "No uncommitted changes" : "No folder")))))
        .child(Scrollbar.vertical("changes-list").absolute().inset_0()))
      .when((this.total ?? 0) > LIMIT, (e) => e.child(div().flex_none().px(14).py(6).border_t(1).border_color(K.border).text_size(11).text_color(t.dim)
        .child(`Showing the first ${LIMIT.toLocaleString()} per section of ${this.total.toLocaleString()} files`)));
  }
}
