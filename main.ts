import { parseFiles } from "@ast-grep/napi";
import { writeFile } from "node:fs/promises";
import { applyForFunctionInit } from "./rules/applyOnInitByFunction";

const main = async (paths: string[]) => {
  await parseFiles(paths, async (err, res) => {
    try {
      const modified = applyForFunctionInit(res.root());
      await writeFile(res.filename(), "#include <pthread.h>\n" + modified);
    } catch (e) {
      console.error(`failed to apply vulnerbilities for ${res.filename()}`);
    }
  });
};

main(process.argv.slice(2));
