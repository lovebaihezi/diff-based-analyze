import { parseFiles, SgRoot } from "@ast-grep/napi";
import { applyForC } from "./rules/applyOnInitByFunctionForC";
import { applyForCpp } from "./rules/applyOnInitByFunctionForC++";
import { checkContent } from "./llmCall";
import logger from "./logger";

const main = async (paths: string[]) => {
  await parseFiles(paths, async (err, root: SgRoot) => {
    if (err) {
      logger.error(err);
      return;
    }
    try {
      if (
        root.filename().endsWith(".cc") ||
        root.filename().endsWith(".cpp") ||
        root.filename().endsWith(".cu") ||
        root.filename().endsWith(".hpp")
      ) {
        const modified = applyForCpp(root.root());
        const res = await checkContent( modified);
        console.log(res.text())
      } else if (root.filename().endsWith(".c")) {
        const modified = applyForC(root.root());
        const res = await checkContent(modified);
        console.log(res.text())
      } else {
        logger.warn("current not support for this file type", root.filename());
      }
    } catch (e) {
      logger.info(e, "failed to apply vulnerabilities");
    }
  });
};

main(process.argv.slice(2));
