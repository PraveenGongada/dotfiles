import { View, div, svg, image } from "gpui-kit";
import { h_flex, ScrollHandle } from "gpui-base";
import { spaces, panes, run, openOverlay, theme, window, layout, settings, shared, nextCommand, checking } from "herdr";
import ICONS from "./icons.js";

function fileIcon(name) {
  const lower = name.toLowerCase();
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

const clean = (s) => (s ?? "").replace(/^[^\p{L}\p{N}\p{Ps}\p{Pi}]+/u, "").replace(/^\[ [!.] \] /, "").trim();

function label(tab, lead) {
  const prog = lead?.program?.name;
  const base = tab.named ? tab.name : prog ?? "Terminal";
  if (!lead?.program?.agent) return base;
  const live = clean(lead.title);
  const path = /^[~/]|^[A-Za-z]:\\/.test((lead.title ?? "").replace(/^[^\p{L}\p{N}~/]+/u, ""));
  const telling = live && live !== lead.terminal && live !== prog && !path && !live.includes("@") && live.toLowerCase() !== lead.program.key;
  return (tab.name === prog || !tab.named) && telling ? live : base;
}

export default class Tabs extends View {
  init(_props, cx) {
    if (!checking()) cx.spawn(async (cx) => {
      for (;;) {
        this.command(await nextCommand());
      }
    });
    this.pressed = null;
    this.scroll = ScrollHandle.new();
    this.swipe = { acc: 0, steps: 0, at: 0, last: 0 };
  }

  wheel(e) {
    if (e.delta_lines) {
      if (e.delta_lines.y) run(e.delta_lines.y > 0 ? "tab.prev" : "tab.next");
      return;
    }
    const s = this.swipe, now = Date.now();
    if (e.touch_phase === "started" || now - s.at > 250 || e.delta.y * s.acc < 0) Object.assign(s, { acc: 0, steps: 0 });
    s.at = now;
    s.acc += e.delta.y;
    const need = s.steps ? 60 : 20;
    if (Math.abs(s.acc) < need || now - s.last < 100) return;
    s.acc -= Math.sign(s.acc) * need;
    s.steps++;
    s.last = now;
    run(e.delta.y > 0 ? "tab.prev" : "tab.next");
  }

  panelOpen(id, root = layout()) {
    const sidebar = find(root, "sidebar");
    return Boolean(sidebar && !sidebar.hidden && find(root, "sidebar-body")?.active === id);
  }

  togglePanel(id) {
    if (this.panelOpen(id)) run("layout.select", { stack: "sidebar-body", child: "home" });
    else { run("layout.select", { stack: "sidebar-body", child: id }); run("layout.show", { id: "sidebar" }); }
  }

  command(command) {
    if (command === "files" || command === "changes") return this.togglePanel(command);
    if (command !== "close-active") return;
    const tab = spaces().find((s) => s.active)?.tabs.find((x) => x.active);
    if (!tab) return;
    const inTab = panes().filter((p) => p.tab === tab.id), current = inTab.find((p) => p.focused);
    if (inTab.length > 1 && current) run("pane.close", { pane: current.pane });
    else run("tab.close", { id: tab.id });
  }

  render() {
    const t = theme(), ps = panes(), root = layout();
    const space = spaces().find(p => p.active);
    const shown = space?.tabs ?? [];
    const active = shown.findIndex(tab => tab.active);
    const selected = shown[active]?.id;
    if (selected !== this.selected || active !== this.selectedIndex) {
      this.selected = selected;
      this.selectedIndex = active;
      if (active >= 0) this.scroll.scroll_to_item(active);
    }
    const stop = (_e, cx) => cx.stop_propagation();
    const button = (id, label, action) => div().id(id).size(26).flex_none().flex().items_center().justify_center().rounded(6).text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.foreground))
      .on_mouse_down("left", stop).on_click(action).child(label);
    const item = (c, i) => {
      const mine = ps.filter(p => p.tab === c.id);
      const lead = mine.find(p => p.program?.agent) ?? mine[0];
      const program = lead?.program;
      const name = label(c, lead);
      const viewerFile = mine.length && !mine.some(p => p.terminal) && /\.[^./]+$/.test(name) ? name : null;
      return h_flex().id(`tab-${c.id}`).h(29).px(10).gap(7).rounded(7).items_center().flex_none().text_size(12.8)
        .when(i <= active, el => el.on_size_change((_size, cx) => { this.scroll.scroll_to_item(active); cx.notify(); }))
        .border(1).border_color(c.active ? t.border : t.chrome).bg(c.active ? t.raised : t.chrome).text_color(c.active ? t.foreground : t.muted)
        .hover(s => s.bg(t.hover))
        .on_mouse_down("left", (e, cx) => { cx.stop_propagation(); this.pressed = i; if (e.click_count === 2) run("tab.rename", { id: c.id }); })
        .on_mouse_up("left", () => {
          const from = this.pressed; this.pressed = null;
          if (from !== null && from !== i) run("tab.move", { id: shown[from].id, index: space.tabs.findIndex(x => x.id === c.id) + 1 });
          else run("tab.select", { id: c.id });
        })
        .on_mouse_down("right", (_e, cx) => { cx.stop_propagation(); openOverlay({ mod: "my-menu", kind: "popup", width: 210, props: { tab: "tab", target: { id: c.id, space: space.id } } }); })
        .when(Boolean(viewerFile), el => el.child(image(`mods/material-files/material/${fileIcon(viewerFile)}.svg`).size(14)))
        .when(!viewerFile && Boolean(program?.icon), el => el.child(program.tint ? svg(program.icon).size(14).text_color(t.muted) : image(program.icon).size(14)))
        .child(div().max_w(170).truncate().child(c.zoomed ? `${name} Z` : name))
        .when(c.status === "working", el => el.child(svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900)))
        .when(c.status === "blocked" || c.status === "done", el => el.child(div().size(6).rounded(3).bg(t[c.status])))
        .when(c.active, el => el.child(div().id(`close-${c.id}`).text_color(t.dim).on_mouse_down("left", stop).on_click((_e, cx) => { cx.stop_propagation(); run("tab.close", { id: c.id }); }).child(svg("mods/pane/close.svg").size(12))));
    };
    const sidebar = find(root, "sidebar"), w = window();
    const lightsPadding = w?.platform === "macos" && w.titlebar === "none" && !w.fullscreen && root?.traffic_lights
      ? Math.max(10, (root.traffic_lights[0] + 64) / settings().zoom - (sidebar?.hidden ? 0 : sidebar?.size?.px ?? 0))
      : 10;
    const changes = shared("git.changes") ?? 0;
    const panelButton = (id, label, icon, badge) => {
      const on = this.panelOpen(id, root);
      return h_flex().id(`panel-${id}`).h(26).px(8).gap(5).flex_none().items_center().rounded(6)
        .text_size(12).bg(on ? t.selected : t.chrome).text_color(on ? t.foreground : t.muted)
        .hover(s => s.bg(t.hover)).on_mouse_down("left", stop)
        .on_click(() => this.togglePanel(id)).child(svg(icon).size(14)).child(label)
        .when(badge > 0, el => el.child(div().h(16).min_w(16).px(4).flex().items_center().justify_center().rounded_full()
          .bg(t.selected).text_size(10).font_semibold().text_color(t.foreground).child(badge > 99 ? "99+" : String(badge))));
    };
    return h_flex().size_full().min_w(0).px(10).pl(lightsPadding).gap(3).items_center().bg(t.chrome).border_b(1).border_color(t.border)
      .on_mouse_up("left", () => { this.pressed = null; })
      .on_scroll_wheel(e => this.wheel(e))
      .child(h_flex().id("tab-scroll").flex_1().min_w(0).h_full().items_center().gap(3).overflow_x_scroll().track_scroll(this.scroll)
        .on_size_change((_size, cx) => { if (active >= 0) { this.scroll.scroll_to_item(active); cx.notify(); } })
        .children(shown.map(item)))
      .child(button("tab-new", "+", () => openOverlay({ mod: "new-menu", kind: "popup", width: 250, height: 512 })))
      .child(panelButton("files", "Files", "mods/files/file.svg"))
      .child(panelButton("changes", "Changes", "mods/changes/changes.svg", changes));
  }
}
