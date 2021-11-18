module Core.Compiler.Compiler where
  import Core.Compiler.Instruction (Bytecode, Instruction(..))
  import Core.Parser.AST (AST(..))
  import Core.Parser.Utils.Garbage (toList)

  flat :: [[a]] -> [a]
  flat xs = foldl (++) [] xs

  compile :: Int -> AST -> Bytecode
  compile i (Node (Literal "begin") xs)
    = let r  = foldl (\acc x -> acc ++ compile (length acc) x) [] xs
          i' = length r
        in r ++ [HALT]

  compile i (Node (Literal "let") ((Literal name):value:_))
    = compile i value ++ [STORE name]

  compile i (Node (Literal "drop") ((Literal name):_))
    = [DROP name]

  compile i (Node (Literal "print") (x:_))
    = compile i x ++ [EXTERN 0]

  compile i (Node (Literal "env") ((Literal x):_))
    = [ENV x]

  compile i (Node (Literal "chr") (x:_))
    = compile i x ++ [EXTERN 2]

  compile i (Node (Literal "return") (x:_))
    = compile i x ++ [RETURN]

  compile i (Node (Literal "add") (x:y:_))
    = compile i x ++ compile i y ++ [ADD]

  compile i (Node (Literal "sub") (x:y:_))
    = compile i x ++ compile i y ++ [SUB]

  compile i (Node (Literal "mul") (x:y:_))
    = compile i x ++ compile i y ++ [MUL]

  compile i (Node (Literal "div") (x:y:_))
    = compile i x ++ compile i y ++ [DIV]

  compile i (Node (Literal "if") (cond:then_:else_:_))
    = let cond' = compile (i + 1) cond
          i' = i + 1
          lc = length cond'

          -- taking in account the condition length to compute new i
          then_' = compile (i' + lc) then_
          lt = length then_'

          else_' = compile (i' + lt + lc + 1) else_
          le = length else_'

          -- computing new i with 1 for the incrementing and two for the jump
      in cond' ++ [JUMP_ELSE $ i' + lt + lc + 1]
          ++ then_' ++ [JUMP_REL $ le + 1]
          ++ else_'

  compile i (Node (Literal "fn") (args:body))
    = let args'  = map (\(Literal name) -> STORE name) (toList args)
          body'  = map (compile i) body
          body'' = concat (args' : body')
          l      = length body''
      in  MAKE_LAMBDA l : body''

  compile i (Node x xs)
    = foldl (\acc x -> acc ++ compile (length acc + i) x) (compile i x) xs ++ [CALL (length xs)]

  compile i (Literal x) = [LOAD x]
  compile _ (Integer i) = [PUSH (fromInteger i)]
  compile _ _ = []

  serialize :: Bytecode -> (String, Int)
  serialize xs = (flat $ map ((++";") . show) xs, length xs)