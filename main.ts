import { parseFiles, SgRoot } from "@ast-grep/napi";
import { applyForC } from "./rules/applyOnInitByFunctionForC";
import { applyForCpp } from "./rules/applyOnInitByFunctionForC++";
import { checkContent } from "./llmCall";
import logger from "./logger";
import { readFile, opendir } from "node:fs/promises";
import { Dir, Dirent } from "node:fs";
import { join } from "node:path";

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
  paths: string[]
): Promise<[string, string | null][]> {
  const jsonStrArr: [string, string | null][] = [];
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
    const jsonStr = res.text();
    jsonStrArr.push([root.filename(), jsonStr]);
  });
  return jsonStrArr;
}

class Diagnose {
  constructor(
    private duration: number,
    private llmRes: Result,
    private codeContainsIssue: string[]
  ) {}
  static collect(diagnoses: Diagnose[]) {}
}

const report = async (
  result: [string, string | null]
): Promise<Diagnose | null> => {
  const beginTime = new Date();
  const [filename, jsonStr] = result;
  if (!jsonStr) {
    logger.error("failed to get result from" + filename);
    return null;
  }
  const json = JSON.parse(jsonStr);
  const endTime = new Date();
  return {
    duration: endTime.getTime() - beginTime.getTime(),
    llmRes: json,
    ...json,
  };
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
  return await report([path, jsonStr]);
};

const cmd = async (paths: string[]) => {
  for (const file of paths) {
    const report = await getFileReport(file);
    logger.info(report);
  }
};

const reportDir = async (path = ".") => {
  const cwd = await opendir(path);
  let file: Dirent | null = null;
  const diagnoses: Diagnose[] = [];
  while ((file = await cwd.read())) {
    if (
      file.isFile() &&
      [".cc", ".C", ".c++", ".cpp", ".cu", ".c"].some(
        (ext) => file && file.name.endsWith(ext)
      )
    ) {
      const diagnose = await getFileReport(join(file.parentPath, file.name));
      if (diagnose) {
        diagnoses.push(diagnose);
      }
    } else if (file.isDirectory()) {
      await reportDir(join(file.parentPath, file.name));
    }
  }
};

const main = async () => {
  await reportDir();
};

main();
