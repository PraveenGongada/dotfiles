import { View, div } from "gpui-kit";
import { v_flex, h_flex, TextView } from "gpui-base";
import { props, spaces, panes, run, exec, readTextFile, watchFolder, theme, settings, shared, checking } from "herdr";

async function openInNvim({ root, path, on }) {
  const space = spaces().find((s) => s.active);
  if (!space || !root || !path) return;
  const file = path.startsWith("/") ? path : `${root}/${path}`, where = { on: on ?? null };
  const sock = `/tmp/herdr-nvim-${space.id.replace(/[^A-Za-z0-9_-]/g, "_")}.sock`;
  const tab = space.tabs.find((x) => x.named && x.name === "nvim" && panes().some((p) => p.tab === x.id && p.terminal));
  if (tab) {
    const expr = `execute('stopinsert | edit ' . fnameescape('${file.replace(/'/g, "''")}'))`;
    const r = await exec("nvim", ["--server", sock, "--remote-expr", expr], where).catch(() => null);
    if (r?.code === 0) { run("tab.select", { id: tab.id }); return; }
  }
  await exec("rm", ["-f", sock], where).catch(() => null);
  run("tab.new", { space: space.id, name: "nvim", folder: root, argv: ["nvim", "--listen", sock, file] });
}

export default class MdPreview extends View {
  init(_props, cx) {
    this.p = props() ?? {};
    this.space = this.p.space ?? spaces().find((s) => s.active)?.id;
    this.seen = shared("md-preview.target")?.n;
    this.text = null; this.gen = 0;
    if (checking() || !this.p.path) return;
    this.load(cx);
    this.watch(cx);
  }

  async close() {
    this.watching?.cancel();
  }

  file() {
    return this.p.path.startsWith("/") ? this.p.path : `${this.p.root}/${this.p.path}`;
  }

  load(cx) {
    const p = this.p;
    cx.spawn(async (cx) => {
      const text = await readTextFile(this.file(), { on: p.on ?? null }).catch(() => null);
      if (this.p !== p) return;
      this.text = text === null ? "Cannot read this file" : text.replace(/^(\s*)(`{3,}|~{3,})[^`\n]*$/gm, "$1$2");
      this.gen++;
      cx.notify();
    });
  }

  watch(cx) {
    this.watching?.cancel();
    this.watching = null;
    if (this.p.on) return;
    const file = this.file(), dir = file.slice(0, file.lastIndexOf("/")) || "/";
    let current = watchFolder(dir);
    this.watching = current;
    cx.spawn(async (cx) => {
      try {
        for (;;) {
          const changed = await current;
          if (this.watching !== current) return;
          if (changed.some((c) => c === file || c === dir)) this.load(cx);
          current = watchFolder(dir);
          this.watching = current;
        }
      } catch {}
    });
  }

  render(cx) {
    const target = shared("md-preview.target");
    if (target && target.n !== this.seen && target.space === this.space) {
      this.seen = target.n;
      cx.timer.after(0, (cx) => { this.p = target; this.text = null; this.load(cx); this.watch(cx); });
    }
    const t = theme();
    if (!this.p.path) return div().size_full().p(16).bg(t.background).text_color(t.dim).child("Nothing to show");
    const parts = this.p.path.split("/"), name = parts.pop(), s = settings();
    const font = s.font_family || undefined, size = Number(s.font_size) || 13;
    return v_flex().size_full().min_h(0).bg(t.background).text_color(t.foreground)
      .child(h_flex().h(32).flex_none().pl(12).pr(8).gap(6).items_center().border_b(1).border_color(t.border).text_size(12)
        .child(div().flex_none().font_medium().child(name))
        .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(parts.join("/")))
        .child(div().id("md-open").px(7).h(20).flex().flex_none().items_center().rounded(4).border_1().border_color(t.border)
          .text_size(11).text_color(t.muted).cursor_pointer().hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => cx.spawn(async () => openInNvim(this.p))).child("Open in nvim")))
      .child(div().flex_1().min_h(0).px(20).py(12).text_size(size).when(Boolean(font), (e) => e.font_family(font))
        .child(this.text === null
          ? div().text_color(t.dim).child("Loading…")
          : TextView.markdown(`md-${this.gen}`, this.text).selectable(true).scrollable(true).size_full()));
  }
}
