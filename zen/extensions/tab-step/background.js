browser.commands.onCommand.addListener(async (command) => {
  const tabs = await browser.tabs.query({ currentWindow: true, hidden: false });
  const active = tabs.find((tab) => tab.active);
  if (!active) return;

  const section = tabs.filter(
    (tab) => tab.groupId === active.groupId && tab.pinned === active.pinned,
  );
  if (section.length < 2) return;

  const current = section.indexOf(active);
  const step = command === "next-tab" ? 1 : -1;
  const target = section[(current + step + section.length) % section.length];
  await browser.tabs.update(target.id, { active: true });
});
