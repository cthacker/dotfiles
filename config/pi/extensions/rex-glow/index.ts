import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { lexer } from "marked";
import { create_tickets, resolve_markdown_path, rewrite_markdown } from "./bridge.mjs";

export default async function rex_glow(pi: ExtensionAPI) {
  let tickets: ReturnType<typeof create_tickets> | undefined;
  let cwd: string;

  pi.registerMarkdownTransformer((markdown, context) => {
    const active_tickets = tickets;
    if (!active_tickets || context.messageType === "assistant-thinking") return markdown;
    return rewrite_markdown(markdown, lexer(markdown), (href: string) => {
      const path = resolve_markdown_path(href, cwd);
      return path ? active_tickets.link(path) : undefined;
    });
  });

  pi.on("session_start", async (_event, ctx) => {
    tickets?.close();
    tickets = undefined;
    if (ctx.mode !== "tui" || process.platform !== "darwin" ||
        !process.env.REX_SESSION || !process.env.REX_BLOCK) return;
    const handler = join(homedir(), "Applications", "Rex Glow.app", "Contents", "MacOS", "RexGlow");
    if (!existsSync(handler)) {
      ctx.ui.notify("Rex Glow: run install.mjs from the extension directory first", "warning");
      return;
    }
    const result = await pi.exec("rex", ["whoami", "--json"], { timeout: 5000 });
    if (result.code !== 0) {
      ctx.ui.notify(`Rex Glow could not connect to Rex: ${result.stderr}`, "error");
      return;
    }
    const rex = JSON.parse(result.stdout);
    if (!rex.endpoint?.startsWith("unix:///") ||
        rex.session_id !== process.env.REX_SESSION || rex.block_id !== process.env.REX_BLOCK) {
      ctx.ui.notify("Rex Glow requires a local Rex terminal", "warning");
      return;
    }
    cwd = ctx.cwd;
    tickets = create_tickets({
      session: rex.session_id, block: rex.block_id, server: rex.endpoint,
    });
  });

  pi.on("session_shutdown", () => {
    tickets?.close();
    tickets = undefined;
  });
}
