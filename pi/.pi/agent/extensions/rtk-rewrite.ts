import { execFile } from "node:child_process";
import {
  type ExtensionAPI,
  isToolCallEventType,
} from "@mariozechner/pi-coding-agent";

function rtkRewrite(cmd: string): Promise<string> {
  return new Promise((resolve) => {
    const child = execFile(
      "rtk",
      ["rewrite", cmd],
      { timeout: 2000 },
      (_err, stdout) => resolve((stdout ?? "").toString().trim()),
    );
    child.on("error", () => resolve(""));
  });
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (!isToolCallEventType("bash", event)) return;

    const cmd = event.input.command ?? "";
    if (!cmd) return;

    const rewritten = (await rtkRewrite(cmd)).replace(/\brtk ls\b/g, "ls");
    if (!rewritten || rewritten === cmd) return;

    event.input.command = rewritten;
  });
}
