import { SgNode } from "@ast-grep/napi";

export const applyForCpp = (root: SgNode): string => {
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
    const edited = node.replace(`
      ${type.text()}${assignID.text()};
      auto _DETACH_THREAD = std::thread([&]() {
        ${assignID.text()} = ${func.text()}(${args.map(node => node.text()).join('')});
      })
      _DETACH_THREAD.detach();
      `);
    const rootCommitted = root.commitEdits([edited]);
    return rootCommitted;
  }
  throw new Error("can not apply");
};

