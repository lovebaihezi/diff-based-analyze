import { SgNode } from "@ast-grep/napi";

export const applyForC = (root: SgNode): string => {
  const nodes = root.findAll("$TYPE $ID = $FUNC($$$ARGS);");
  for (const node of nodes) {
    const nextNode = node.next();
    if (!nextNode) {
      continue;
    }
    const assignID = node.getMatch("ID");
    if (!assignID) {
      throw new Error("unreachable");
    }
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
          return [`/* skip ${i}th ${arg.text()} */`, "", arg.text()] as const;
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
pthread_detach(SPECIFIC_THREAD);
      `);
    const rootCommitted = root.commitEdits([edited]);
    return rootCommitted;
  }
  throw new Error("can not apply");
};
