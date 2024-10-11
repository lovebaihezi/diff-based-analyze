module Main where

import LLVM.AST
import LLVM.AST.Constant
import LLVM.AST.Global
import LLVM.AST.Instruction
import qualified LLVM.AST.Operand as O

findDbgValueCalls :: Module -> [Instruction]
findDbgValueCalls m = concatMap findInFunction (moduleDefinitions m)
  where
    findInFunction (GlobalDefinition f@(Function _ _ _ _ _ _ _ _ _ _ _ _ _ _ blocks _ _)) =
      concatMap findInBlock blocks
    findInFunction _ = []

    findInBlock (BasicBlock _ instrs _) =
      filter isDbgValueCall instrs

    isDbgValueCall (Call _ _ (O.ConstantOperand (GlobalReference _ name)) _ _ _ datameta) =
      name == Name "llvm.dbg.value"
    isDbgValueCall _ = False

analyzeDbgValueCall :: Instruction -> Maybe (O.Operand, O.Operand, O.Operand)
analyzeDbgValueCall (Call _ _ _ _ _ metadata _) =
  case args of
    [value, variable, expression] -> Just (value, variable, expression)
    _ -> Nothing
analyzeDbgValueCall _ = Nothing

main :: IO ()
main = putStrLn "Hello, Haskell!"
