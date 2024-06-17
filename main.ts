import { Edit, Lang, parse, SgNode } from "@ast-grep/napi";

const apply = (root: SgNode): string => {
  const firstFunction = findFirstFunction(root);
  const insertIndex = firstFunction.range().start.index - 1;
  const nodes = root.findAll("$TYPE $ID = $EXPR;");
  for (const node of nodes) {
    const nextNode = node.next();
    if (!nextNode) {
      continue;
      // throw new Error("can not find next if statement");
    }
    const ifStat = nextNode.find("if ($A == $B) { $C }");
    if (!ifStat) {
      continue;
      // throw new Error("can not find if stat");
    }
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
      continue
    }

    if ("* " + leftVar.text() == assignID.text()) {
      const type = node.getMatch("TYPE");
      if (!type) {
        throw new Error("no type");
      }
      const expr = node.getMatch("EXPR");
      if (!expr) {
        throw new Error("no expr");
      }
      // step 1: Modify the old init, call the pthread join
      const callPthread: Edit = {
        "position": expr.range().end.index + 1,
        "deletedLength": expr.range().end.index - expr.range().start.index,
        "insertedText": `
pthread_t thread;
${type.text()}*${assignID.text()}_ptr;
pthread_create(&thread, NULL, _ADDED_FUNCTION, &${assignID.text()}_ptr);
pthread_join(thread, NULL);
`,
      };
      const replaceEdit = node.replace(`
${type.text()}${assignID.text()};
pthread_t thread;
${type.text()}*${assignID.text()}_ptr;
pthread_create(&thread, NULL, _ADDED_FUNCTION, &${assignID.text().slice(2)}_ptr);
pthread_join(thread, NULL);
`
)

      // step 2: create functoin that init the variable
      const initFunctionEdit: Edit = {
        "position": insertIndex,
        "deletedLength": 0,
        "insertedText": `
#include <pthread.h>
void* _ADDED_FUNCTION(void* arg) {
  ${type.text()}*${assignID.text()} = arg;
  *data = ${expr.text()};
  return NULL;
}`,
      };
      const rootCommited = root.commitEdits([replaceEdit,initFunctionEdit]);
      return rootCommited;
    }
  }
  throw new Error("can not find one pattern for insert");
};

const findFirstFunction = (root: SgNode): SgNode => {
  const nodes = root.findAll("$RET_TYPE $F_NAME($$$ARGS) { $BODY }");
  if (nodes.length == 0) {
    throw new Error("can not find main function");
  }
  return nodes[0];
};

const main = () => {
  const source = `
#include <stdio.h>

int main(int argc, char* argv[]) {
    for (int i = 1;i < argc;i += 1) {
        FILE* file = fopen(argv[i], "r");
        if (file == NULL) {
            return 1;
        }
        char c;
        while ((c = fgetc(file)) != EOF) {
            printf("%c", c);
        }
        fclose(file);
    }
}
`;
  const ast = parse(Lang.C, source);
  const root = ast.root();
  const modified = apply(root);
  console.log(modified);
};
main();
