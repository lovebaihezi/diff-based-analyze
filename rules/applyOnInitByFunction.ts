import { Edit, Lang, parse, parseFiles, SgNode } from "@ast-grep/napi";

export const applyForFunctionInit = (root: SgNode): string => {
  const nodes = root.findAll("$TYPE $ID = $FUNC($$$ARGS);");
  for (const node of nodes) {
    const nextNode = node.next();
    if (!nextNode) {
      continue;
      // throw new Error("can not find next if statement");
    }
    let ifStat = null;
    for (const ifStat of nextNode.findAll("if ($A == $B) { $C }")) {
      const leftVar = ifStat.getMatch("A");
      // const rightVar = ifStat.getMatch("B");
      const assignID = node.getMatch("ID");
      if (!leftVar) {
        throw new Error("no left var");
      }
      if (!assignID) {
        throw new Error("no assign id");
      }
      if (leftVar.text() == assignID.text()) {
        // handle not pointer version
        continue;
      }
      const body = ifStat.getMatch("C");
      if (!body) {
        continue;
      }

      if (body.text().includes("continue") || body.text().includes("break")) {
        continue;
      }

      if ("* " + leftVar.text() == assignID.text()) {
        const type = node.getMatch("TYPE");
        if (!type) {
          throw new Error("no type");
        }
        const func = node.getMatch("FUNC");
        if (!func) {
          throw new Error("no func");
        }
        const args = node.getMultipleMatches("ARGS");
        const fields: [string, string, string][] = args
          .filter((arg) => arg.text().trim() != ",")
          .map((arg, i) => {
            // NOTE: dont need to handle constant string or number
            if (arg.text().startsWith(`"`) || /\d/.test(arg.text()[0])) {
              return [
                `/* skip ${i}th ${arg.text()} */`,
                "",
                arg.text(),
              ] as const;
            }
            return [
              `typeof(${arg.text()}) var_${i};`,
              `arg.var_${i} = ${arg.text()};`,
              `args->var_${i}`,
            ] as const;
          });
        // NOTE: init the variable need extra args, so you will a struct to wrap them
        const edited = node.replace(`
struct _ONLY_FORVUL_ARG {
  ${fields.map(([field]) => field).join("\n")}
  // Used for Return
  ${type.text()}${assignID.text()};
  };
  void* ONLY_FOR_VUL(struct _ONLY_FORVUL_ARG* args) {
    args->${assignID.text().slice(2)} = ${func.text()}(${fields
      .map(([_, __, field]) => field)
      .join(", ")});
      return NULL;
      }
      pthread_t SPECIFIC_THREAD;
      ${type.text()}${assignID.text()};
      struct _ONLY_FORVUL_ARG arg;
      ${fields.map(([_, field]) => field).join("\n")}
      pthread_create(&SPECIFIC_THREAD, NULL, (void*)ONLY_FOR_VUL, (void*) &(arg));
      `);
        const callJoinAtLast = ifStat.replace(`${ifStat.text()}
      pthread_join(SPECIFIC_THREAD, NULL);`);
        const rootCommited = root.commitEdits([edited, callJoinAtLast]);
        return rootCommited;
      }
    }
  }
  throw new Error("can not find one pattern for insert");
};


