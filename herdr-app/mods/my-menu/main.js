import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, props, closeOverlay, openOverlay, theme, keys, spaces, panes } from "herdr";

function closeMany({ space, ids, all, single }) {
  if (single) { run("tab.close", { id: ids[0] }); return; }
  const tabs = (spaces().find((s) => s.id === space)?.tabs ?? []).filter((x) => ids.includes(x.id));
  const ps = panes(), terminalsCount = tabs.filter((x) => ps.some((q) => q.tab === x.id && q.terminal)).length;
  const commands = tabs.map((x) => ({ name: "tab.close", args: { id: x.id, confirmed: true } }));
  if (!terminalsCount && !all) { for (const c of commands) run(c.name, c.args); return; }
  const notes = [];
  if (terminalsCount) notes.push(`${terminalsCount} terminal${terminalsCount === 1 ? "" : "s"} will end, including any agents running in ${terminalsCount === 1 ? "it" : "them"}.`);
  if (all) notes.push("Closing every tab also closes this space.");
  openOverlay({ mod: "my-confirm", kind: "dialog", width: 460, height: 190, props: {
    title: `Close ${tabs.length} tab${tabs.length === 1 ? "" : "s"}?`, detail: notes.join(" "), commands } });
}

function items(p) {
  const tg = p?.target ?? {};
  const tabs = spaces().find((s) => s.id === tg.space)?.tabs ?? [], at = tabs.findIndex((x) => x.id === tg.id);
  const others = tabs.filter((x) => x.id !== tg.id), right = at >= 0 ? tabs.slice(at + 1) : [];
  const many = (label, list, all) => list.length ? [{ label, close: true, args: { space: tg.space, ids: list.map((x) => x.id), all: Boolean(all) } }] : [];
  return [
    { label: "Rename", command: "tab.rename", args: { id: tg.id } },
    { label: "Close", close: true, key: "tab.close", args: { space: tg.space, ids: [tg.id], single: true } },
    ...many("Close Others", others),
    ...many("Close to the Right", right),
    ...many("Close All", tabs, true),
  ];
}

function shortcut(name) {
  return keys().find((b) => b.section === "global" && b.action === name)?.keys ?? "";
}

export default class Menu extends View {
  init(_props, cx) {
    this.at = 0;
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  choose(i) {
    const it = items(props())[i];
    if (!it) return;
    closeOverlay(props()?.overlay);
    if (it.close) closeMany(it.args);
    else run(it.command, it.args);
  }

  render() {
    const t = theme();
    const list = items(props());
    return v_flex()
      .id("menu")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(5)
      .bg(t.popover)
      .text_size(12.8)
      .on_key_down((e, cx) => {
        if (e.key === "down") this.at = (this.at + 1) % list.length;
        else if (e.key === "up") this.at = (this.at + list.length - 1) % list.length;
        else if (e.key === "enter") this.choose(this.at);
        else if (e.key === "escape") closeOverlay(props().overlay);
        else return;
        cx.notify();
      })
      .children(
        list.map((it, i) =>
          v_flex()
            .when(it.close && !list[i - 1]?.close, el => el.child(div().mx(7).my(4).h(1).bg(t.border)))
            .child(h_flex()
            .id(`mi-${i}`)
            .h(31)
            .px(8)
            .gap(9)
            .rounded(7)
            .items_center()
            .justify_between()
            .text_color(t.foreground)
            .when(i === this.at, (el) => el.bg(t.selected))
            .hover((s) => s.bg(t.hover))
            .on_click(() => this.choose(i))
            .child(svg(`mods/workspace-chrome/${it.close ? "x" : "square-pen"}.svg`).size(14).flex_none().text_color(t.muted))
            .child(div().flex_1().child(it.label))
            .child(div().text_size(11).text_color(t.dim).child(shortcut(it.key ?? it.command ?? "")))),
        ),
      );
  }
}
