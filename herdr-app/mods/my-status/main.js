import { View, div, svg, image } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, panes, focused, agents, theme, run, exec, shared, setShared, home, watchFolder, readTextFile, checking, layout, window } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

function toggleGit() {
  const root = layout(), sidebar = find(root, "sidebar"), body = find(root, "sidebar-body");
  if (sidebar && !sidebar.hidden && body?.active === "changes") run("layout.select", { stack: "sidebar-body", child: "home" });
  else { run("layout.select", { stack: "sidebar-body", child: "changes" }); run("layout.show", { id: "sidebar" }); }
}

const COLOR = { git: "#F1502F", k8s: "#326CE5" };
const paint = (t) => Object.assign(COLOR, { ok: t.done, warn: t.blocked, bad: t.ansi9 });
const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const USAGE = /^(terminal-.+|latest)\.json$/;

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  if (f?.pane === null && f.terminal) return { cwd: f.cwd, on: f.terminal.includes("/") ? f.terminal.split("/")[0] : null };
  const order = new Map((space?.tabs ?? []).map((t, i) => [t.id, t.active ? -1 : i]));
  const terminals = panes().filter((p) => p.terminal && p.cwd && order.has(p.tab)).sort((a, b) => order.get(a.tab) - order.get(b.tab));
  const atHome = !space?.folder || space.folder === "~" || (!space.machine && space.folder === home());
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  if (pane?.terminal || f?.terminal) return { cwd: pane?.cwd || f?.cwd || null, on: space?.machine ?? null };
  return { cwd: terminals[0]?.cwd || (atHome ? null : space.folder) || space?.folder, on: space?.machine ?? null };
}

function busy() {
  const space = spaces().find((s) => s.active), tabs = new Set((space?.tabs ?? []).map((t) => t.id)), out = {};
  for (const p of panes()) if (p.terminal && tabs.has(p.tab)) out[p.pane] = p.status === "working" || !(p.program?.shell || p.program?.agent);
  return out;
}

function current(entries, pick) {
  const windows = entries.map((e) => pick(e.data.rate_limits)).filter(Boolean)
    .map((w) => ({ w, resets: seconds(w.resets_at ?? w.reset_at ?? w.resetsAt) ?? 0, pct: w.used_percentage ?? w.utilization ?? 0 }));
  if (!windows.length) return null;
  const latest = Math.max(...windows.map((x) => x.resets));
  return windows.filter((x) => x.resets === latest).reduce((a, b) => (b.pct > a.pct ? b : a)).w;
}

function seconds(value) {
  if (value == null) return null;
  if (typeof value === "number") return value > 1e12 ? value / 1000 : value;
  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : parsed / 1000;
}

function clock(unix, withDay) {
  const d = new Date(unix * 1000), now = new Date();
  let h = d.getHours();
  const m = String(d.getMinutes()).padStart(2, "0"), ampm = h >= 12 ? "PM" : "AM";
  h = h % 12 || 12;
  const sameDay = now.getDate() === d.getDate() && now.getMonth() === d.getMonth();
  return `${withDay && !sameDay ? DAYS[d.getDay()] + " " : ""}${h}:${m} ${ampm}`;
}

const level = (pct) => pct >= 80 ? COLOR.bad : pct >= 50 ? COLOR.warn : COLOR.ok;

export default class Status extends View {
  init(_props, cx) {
    this.git = null; this.k8s = null;
    this.usage = new Map(); this.dirty = new Set();
    if (checking()) return;
    this.loadGit(cx);
    this.loadK8s(cx);
    this.loadClaude(cx);
    cx.timer.every(30000, (cx) => { if (window()?.active) this.loadGit(cx); });
    cx.timer.every(3600000, () => { exec("find", [`${home()}/.cache/claude-usage`, "-name", "terminal-*.json", "-mtime", "+2", "-delete"]).catch(() => null); });
    this.watchKube(cx);
    this.watchUsage(cx);
  }

  watchKube(cx) {
    const dir = `${home()}/.kube`;
    cx.spawn(async (cx) => {
      try {
        for (;;) {
          const changed = await watchFolder(dir);
          if (changed.some((p) => p === dir || p === `${dir}/config`)) this.loadK8s(cx);
        }
      } catch { cx.timer.after(60000, (cx) => this.watchKube(cx)); }
    });
  }

  watchUsage(cx) {
    const dir = `${home()}/.cache/claude-usage`;
    cx.spawn(async (cx) => {
      try {
        for (;;) {
          const changed = await watchFolder(dir);
          if (changed.some((p) => p.replace(/\/+$/, "") === dir)) { this.loadClaude(cx); continue; }
          for (const p of changed) {
            const name = p.slice(p.lastIndexOf("/") + 1);
            if (USAGE.test(name)) this.dirty.add(name);
          }
          if (this.dirty.size && !this.queued) {
            this.queued = true;
            cx.timer.after(300, (cx) => { this.queued = false; this.readUsage(cx); });
          }
        }
      } catch { cx.timer.after(60000, (cx) => this.watchUsage(cx)); }
    });
  }

  readUsage(cx) {
    const dir = `${home()}/.cache/claude-usage`, names = [...this.dirty];
    this.dirty.clear();
    cx.spawn(async (cx) => {
      for (const name of names) {
        const text = await readTextFile(`${dir}/${name}`).catch(() => null);
        if (text === null) { this.usage.delete(name); continue; }
        try { this.usage.set(name, JSON.parse(text)); } catch {}
      }
      cx.notify();
    });
  }

  loadGit(cx) {
    const { cwd, on } = location(), seq = this.gitSeq = (this.gitSeq ?? 0) + 1;
    if (!cwd) {
      this.git = null;
      if (shared("git.changes")) setShared("git.changes", 0);
      cx.notify();
      return;
    }
    cx.spawn(async (cx) => {
      const r = await exec("git", ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain=v2", "--branch", "--untracked-files=all"], { cwd, on }).catch(() => null);
      if (seq !== this.gitSeq) return;
      if (!r || r.code !== 0) { this.git = null; if (shared("git.changes")) setShared("git.changes", 0); cx.notify(); return; }
      const g = { branch: "", ahead: 0, behind: 0, M: 0, A: 0, D: 0 };
      for (const line of r.stdout.split("\n")) {
        if (line.startsWith("# branch.head ")) g.branch = line.slice(14);
        else if (line.startsWith("# branch.ab ")) { const [a, b] = line.slice(12).split(" "); g.ahead = Math.abs(+a); g.behind = Math.abs(+b); }
        else if (line.startsWith("? ")) g.A++;
        else if (/^[12u] /.test(line)) { const xy = line.slice(2, 4); if (xy.includes("D")) g.D++; else if (xy.includes("A")) g.A++; else g.M++; }
      }
      this.git = g;
      const total = g.M + g.A + g.D;
      if (shared("git.changes") !== total) setShared("git.changes", total);
      cx.notify();
    });
  }

  loadK8s(cx) {
    cx.spawn(async (cx) => {
      const r = await exec("kubectl", ["config", "view", "--minify", "-o", 'jsonpath={.current-context}{"\\t"}{..namespace}']).catch(() => null);
      const [context, namespace] = (r?.code === 0 ? r.stdout.trim() : "").split("\t");
      this.k8s = context ? { context, namespace: namespace || "default", prod: /ny-prod|eks-kurukshetra/i.test(context) } : null;
      cx.notify();
    });
  }

  loadClaude(cx) {
    const dir = `${home()}/.cache/claude-usage`;
    cx.spawn(async (cx) => {
      const r = await exec("sh", ["-c", 'mkdir -p "$1" && cd "$1" && ls -t terminal-*.json latest.json 2>/dev/null | head -60', "usage", dir]).catch(() => null);
      for (const name of (r?.stdout ?? "").split("\n").filter(Boolean)) this.dirty.add(name);
      if (this.dirty.size) this.readUsage(cx);
    });
  }

  claudeView() {
    const entries = [...this.usage].map(([name, data]) => ({ name, data }));
    if (!entries.length) return null;
    const now = Date.now() / 1000;
    const f = focused(), pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
    const running = Boolean(pane?.terminal) && pane?.program?.key === "claude";
    const file = running ? `terminal-${String(pane.terminal).replace(/[^A-Za-z0-9_.-]/g, "_")}.json` : null;
    const here = file ? entries.find((e) => e.name === file) ?? null : null;
    const usageWindow = (w) => {
      if (!w) return null;
      const resets = seconds(w.resets_at ?? w.reset_at ?? w.resetsAt);
      const expired = resets && resets < now;
      return { pct: expired ? 0 : Math.round(w.used_percentage ?? w.utilization ?? 0), resets: expired ? null : resets };
    };
    const ctxWin = here?.data.context_window;
    const ctxPct = ctxWin?.used_percentage ?? (ctxWin?.total_input_tokens && ctxWin?.context_window_size ? (100 * ctxWin.total_input_tokens) / ctxWin.context_window_size : null);
    return {
      context: here ? Math.round(ctxPct ?? 0) : null,
      five: usageWindow(current(entries, (l) => l?.five_hour)),
      week: usageWindow(current(entries, (l) => l?.seven_day)),
    };
  }

  segment(id, children, onClick) {
    return h_flex().id(id).h(24).px(8).gap(7).flex_none().items_center().rounded(6)
      .when(Boolean(onClick), (e) => e.cursor_pointer().hover((s) => s.bg(this.t.hover)).on_click(() => onClick()))
      .children(children);
  }

  divider() { return div().w(1).h(14).mx(4).flex_none().bg(this.t.border); }
  dot() { return div().size(3).flex_none().rounded(2).bg(this.t.dim); }

  meter(id, label, pct, t, reset) {
    const color = level(pct);
    return h_flex().id(id).gap(6).flex_none().items_center()
      .child(div().text_size(10.5).font_medium().text_color(t.dim).child(label))
      .child(div().w(42).h(4).flex_none().rounded(2).bg(t.raised).child(div().h_full().rounded(2).bg(color).w(Math.max(3, Math.round(42 * Math.min(pct, 100) / 100)))))
      .child(div().font_medium().text_color(t.foreground).child(`${pct}%`))
      .when(Boolean(reset), (e) => e.child(div().text_size(10.5).text_color(t.dim).child(reset)));
  }

  render(cx) {
    const where = JSON.stringify(location()), now = busy(), before = this.busy ?? {};
    const finished = Object.keys(now).some((pane) => before[pane] && !now[pane]);
    this.busy = now;
    if (where !== this.where || finished) {
      this.where = where;
      if (!checking()) cx.timer.after(0, (cx) => this.loadGit(cx));
    }
    const t = theme(), g = this.git, k = this.k8s, c = this.claudeView();
    paint(t);
    this.t = t;
    const waiting = agents().filter((a) => a.status === "blocked").length;
    const claudeParts = [];
    if (c?.context != null) claudeParts.push(this.meter("m-ctx", "Context", c.context, t));
    if (c?.five) claudeParts.push(this.meter("m-5h", "5h", c.five.pct, t, c.five.resets ? clock(c.five.resets, false) : null));
    if (c?.week) claudeParts.push(this.meter("m-week", "Week", c.week.pct, t, c.week.resets ? clock(c.week.resets, true) : null));
    return h_flex().size_full().px(8).gap(2).items_center().bg(t.chrome).border_t(1).border_color(t.border).text_size(11.5).text_color(t.muted)
      .when(Boolean(g), (e) => e.child(this.segment("st-git", [
        svg("mods/workspace-chrome/git-branch.svg").size(13).flex_none().text_color(COLOR.git),
        div().font_medium().text_color(t.foreground).child(g.branch || "detached"),
        ...(g.ahead || g.behind ? [div().text_color(t.dim).child(`↑${g.ahead} ↓${g.behind}`)] : []),
      ], toggleGit)))
      .when(Boolean(g) && Boolean(k), (e) => e.child(this.divider()))
      .when(Boolean(k), (e) => e.child(this.segment("st-k8s", [
        svg("icons/kubectl.svg").size(13).flex_none().text_color(COLOR.k8s),
        div().font_medium().text_color(k.prod ? COLOR.bad : t.foreground).child(k.context),
        ...(k.namespace !== "default" ? [this.dot(), div().text_color(t.dim).child(k.namespace)] : []),
      ])))
      .when(waiting > 0, (e) => e.child(this.divider()).child(this.segment("st-agents", [div().size(6).rounded(3).bg(COLOR.warn), div().text_color(COLOR.warn).child(`${waiting} agent${waiting === 1 ? "" : "s"} need${waiting === 1 ? "s" : ""} you`)])))
      .child(div().flex_1())
      .when(claudeParts.length > 0, (e) => e.child(this.segment("st-claude", [
        image("my-icons/claude.svg").size(13).flex_none(),
        ...claudeParts.flatMap((part, i) => i ? [this.divider(), part] : [part]),
      ])));
  }
}
