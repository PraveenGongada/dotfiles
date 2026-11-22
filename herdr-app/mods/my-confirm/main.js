// Asks before something destructive, e.g. "Close space?". Opened as a
// dialog with props { title, detail, command: { name, args } }.
// Enter confirms (runs the command), Esc cancels.

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, exec, props, closeOverlay, theme } from "herdr";

export default class Confirm extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  yes(cx) {
    const p = props();
    if (!p.exec) {
      closeOverlay(p.overlay);
      for (const c of p.commands ?? [p.command]) run(c.name, c.args ?? {});
      return;
    }
    if (this.running) return;
    this.running = true; this.error = null; cx.notify();
    cx.spawn(async (cx) => {
      const r = await exec(p.exec.command, p.exec.args ?? [], { cwd: p.exec.cwd, on: p.exec.on ?? null }).catch((e) => ({ code: 1, stderr: String(e) }));
      this.running = false;
      if (r.code === 0) { closeOverlay(p.overlay); return; }
      this.error = (r.stderr || r.stdout || "Failed").trim().split("\n")[0];
      cx.notify();
    });
  }

  render(cx) {
    const t = theme();
    const p = props() ?? {};
    const button = (id, label, bg, fg, onClick) =>
      h_flex().id(id).h(32).px(14).items_center().rounded(8).border_1().border_color(id === "no" ? t.input : bg).bg(bg).text_color(fg).cursor_pointer().hover((s) => s.opacity(0.88)).on_click(onClick).child(label);
    return v_flex()
      .id("confirm")
      .track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "enter") this.yes(cx);
        else if (e.key === "escape") closeOverlay(props().overlay);
        else return;
        cx.stop_propagation();
      })
      .size_full()
      .min_h(0)
      .p(18)
      .gap(12)
      .rounded(8)
      .bg(t.popover)
      .text_size(13)
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child(p.title ?? "Are you sure?")).child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(div().flex_1().min_h(0).overflow_y_scrollbar().text_color(t.muted).child(p.detail ?? ""))
      .when(Boolean(this.error), (el) => el.child(div().text_size(12).text_color(t.ansi1 ?? t.foreground).child(this.error)))
      .child(
        h_flex()
          .justify_end()
          .gap(8)
          .text_size(12)
          .child(button("no", "Cancel", t.raised, t.foreground, () => closeOverlay(props().overlay)))
          .child(button("yes", this.running ? "Working…" : "Confirm", t.solid, t.solid_foreground, (_e, cx) => this.yes(cx))),
      );
  }
}
