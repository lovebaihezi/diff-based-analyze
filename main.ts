import { parseFiles, SgRoot } from "@ast-grep/napi";
import { writeFile } from "node:fs/promises";
import { applyForC } from "./rules/applyOnInitByFunctionForC";
import { applyForCpp } from "./rules/applyOnInitByFunctionForC++";

const main = async (paths: string[]) => {
  await parseFiles(paths, async (err, res: SgRoot) => {
    if (err) {
      console.error(err);
      return;
    }
    try {
      if (
        res.filename().endsWith(".cc") || res.filename().endsWith(".cpp") || res.filename().endsWith(".cu") ||
        res.filename().endsWith(".hpp")
      ) {
        const modified = applyForCpp(res.root());
        await writeFile(res.filename(), "#include <thread>\n" + modified);
      } else if (res.filename().endsWith(".c")) {
        const modified = applyForC(res.root());
        await writeFile(res.filename(), "#include <pthread.h>\n" + modified);
      } else {
        console.warn("current not support for this file type", res.filename())
      }
    } catch (e) {
      console.error(`failed to apply vulnerbilities for ${res.filename()}`);
    }
  });
};

main(process.argv.slice(2));
