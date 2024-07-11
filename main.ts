import { parseFiles, SgRoot } from "@ast-grep/napi";
import { applyForC } from "./rules/applyOnInitByFunctionForC";
import { applyForCpp } from "./rules/applyOnInitByFunctionForC++";
import { checkContent } from "./llmCall";
import logger from "./logger";
import { readFile, opendir } from "node:fs/promises";
import { Dirent } from "node:fs";
import { join } from "node:path";
import { TaskPool } from "./tasksPool";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { analyze } from "./analyze";

// Gemini flash 1.5 support 1000 RPM
const pool = new TaskPool(1000);

type Result = Record<"code" | "cwe_name" | "sync_issue", string | undefined>;

async function modified(root: SgRoot): Promise<string | null> {
  try {
    if (
      root.filename().endsWith(".cc") ||
      root.filename().endsWith(".cpp") ||
      root.filename().endsWith(".cu") ||
      root.filename().endsWith(".hpp")
    ) {
      const modified = applyForCpp(root.root());
      return modified;
    } else if (root.filename().endsWith(".c")) {
      const modified = applyForC(root.root());
      return modified;
    } else {
      logger.warn("current not support for this file type", root.filename());
    }
  } catch (e) {
    logger.info(e, "failed to apply vulnerabilities");
  }
  return null;
}

async function getStrReport(
  paths: string[],
): Promise<[string, string | null][]> {
  const xmlStrs: [string, string | null][] = [];
  await parseFiles(paths, async (err, root: SgRoot) => {
    if (err) {
      logger.error(err);
      return;
    }
    const modifiedCode = await modified(root);
    if (!modifiedCode) {
      return;
    }
    const res = await checkContent(modifiedCode);
    if (!res) {
      return;
    }
    const xmlStr = res.text();
    xmlStrs.push([root.filename(), xmlStr]);
  });
  return xmlStrs;
}

class Diagnose {
  public codeWithIssue: string = "";
  public cweID: string = "";
  constructor(
    private fileName: string,
    private duration: number,
    private llmRes: string,
  ) {
    logger.debug({ llmRes }, "raw llm res");
    const start = llmRes.indexOf("<codesContainsIssue>");
    const codeWithIssue = llmRes.slice(
      start,
      llmRes.indexOf("</codesContainsIssue>", start + 1),
    );
    const cweID = llmRes.slice(
      llmRes.indexOf("<CWE-ID>"),
      llmRes.indexOf("</CWE-ID>"),
    );
    if (codeWithIssue && cweID) {
      this.codeWithIssue = codeWithIssue;
      this.cweID = cweID;
      logger.debug(
        { issuesCode: this.codeWithIssue, fileName, duration, cweID },
        `LLM find the code with issue`,
      );
    }
  }
}

const report = async (
  result: [string, string | null],
): Promise<Diagnose | null> => {
  const beginTime = new Date();
  const [filename, xmlStr] = result;
  if (!xmlStr) {
    logger.error("failed to get result from" + filename);
    return null;
  }
  const endTime = new Date();
  return new Diagnose(
    filename,
    endTime.getTime() - beginTime.getTime(),
    xmlStr,
  );
};

const baseline = async (paths: string[]) => {
  const resultIter = await getStrReport(paths);
  for (const result of resultIter) {
    await report(result);
  }
};

const getFileReport = async (path: string) => {
  const content = await readFile(path, { encoding: "utf-8" });
  const res = await checkContent(content);
  if (!res) {
    return null;
  }
  const jsonStr = res.text();
  return await pool.wrap(() => report([path, jsonStr]));
};

const cmd = async (paths: string[]) => {
  for (const file of paths) {
    const report = await getFileReport(file);
    logger.info(report);
  }
};

const reportDir = async ({ path = ".", skipped = [] as string[] }) => {
  if (skipped.includes(path)) {
    return;
  }
  const cwd = await opendir(path);
  let file: Dirent | null = null;
  const checks: Promise<Diagnose | null>[] = [];
  while ((file = await cwd.read())) {
    if (
      file.isFile() &&
      [".cc", ".C", ".c++", ".cpp", ".cu", ".c"].some(
        (ext) => file && file.name.endsWith(ext),
      ) &&
      !/[tT]est/.test(file.name)
    ) {
      const path = join(file.parentPath, file.name);
      const check = getFileReport(path).catch((e) => {
        logger.error(e, `failed to get report of ${path}`);
        return null;
      });
      checks.push(check);
    } else if (file.isDirectory()) {
      await reportDir({ path: join(file.parentPath, file.name), skipped });
    }
  }
  const diagnoses = await Promise.all(checks);
  for (const diagnose of diagnoses) {
    logger.info(diagnose);
  }
  cwd.close();
};

const main = async () => {
  const argv = await yargs(hideBin(process.argv))
    .command(
      "analyze <file>",
      "the path to run check on",
      (yargs) => {
        return yargs.positional("file", {
          describe: "The file to analyze",
          type: "string",
        });
      },
      async ({ file }) => {
        if (file) {
          logger.info({ file }, "run analyze");
          await analyze(file);
        }
      },
    )
    .command(
      "micro <path>",
      "run on micro",
      (yargs) => {
        return yargs.positional("micro", {
          describe: "The file to analyze",
          type: "string",
        });
      },
      async ({ micro }) => {
        await reportDir({ skipped: [], path: micro });
      },
    )
    .help()
    .parse();
};

main();
