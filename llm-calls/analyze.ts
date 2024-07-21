import { open } from "node:fs/promises";
import { expertCWE, generationConfig } from "./llmCall";
import logger from "./logger";

interface Content {
  llmRes: string;
  codeWithIssue: string;
  fileName: string;
  cweID: string;
}

export const analyze = async (path: string) => {
  const file = await open(path);
  const rl = file.readLines();
  const ses = expertCWE.startChat({ ...generationConfig, history: [] });
  const flags: Array<"NO" | "YES"> = [];
  for await (const line of rl) {
    const json = JSON.parse(line) as Content;
    if (json.cweID) {
      const [_, matched] = json.cweID.match(/CWE-(\d+)/) ?? [];
      if (!matched) {
        return;
      }
      const res = await ses.sendMessageStream(`CWE-${matched}`);
      const r = await res.response;
      const flag: "NO" | "YES" = r.text().trim() as "NO" | "YES";
      switch (flag) {
        case "NO":
        case "YES":
          flags.push(flag);
          break;
        default:
          logger.error({ flag }, "unknow flag of gemini api responsding");
      }
    }
  }
};
