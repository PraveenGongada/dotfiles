import { View, div, image, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { theme, run, props, window, updates } from "herdr";

export default class WorkspaceChrome extends View {
  render() {
    const t = theme();
    if (props()?.footer) {
      return v_flex().size_full().justify_center().bg(t.chrome).border_t(1).border_color(t.border).px(8).text_size(13)
        .child(h_flex().id("settings").h(28).px(8).gap(9).items_center().rounded(8)
          .text_color(t.muted).hover(s => s.bg(t.hover).text_color(t.foreground)).cursor_pointer()
          .on_click(() => run("app.settings")).child(svg("mods/my-chrome/settings.svg").size(14)).child("Settings")
          .when(Boolean(updates().app.ready), el => el.child(div().size(6).rounded_full().bg(t.accent))));
    }
    const lights = window()?.platform === "macos" && !window()?.fullscreen;
    return h_flex().size_full().bg(t.chrome).pl(lights ? 60 : 10).pr(12).items_center()
      .child(div().flex_1())
      .child(image("frame/welcome/herdr.png").size(20).rounded(5).flex_none());
  }
}
