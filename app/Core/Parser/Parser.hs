module Core.Parser.Parser where
  import Core.Parser.Combinator
  import Core.Parser.AST     (AST(..))
  import Control.Applicative ((<|>))
  import Data.Maybe          (isJust, fromMaybe)

  {-
    Module: Quark parser
    Description: Lisp like parser using custom combinator library
    Author: thomasvergne
  -}

  -- Parse an expression
  parseExpr :: Parser String AST
  parseExpr = do
    char '('
    name <- parse
    args <- many parse
    char ')'
    return $ Node name args

  blacklist :: String
  blacklist = "() {}[]"

  parseChar :: Parser String AST
  parseChar = Char <$> (char '\'' *> (escaped <|> anyChar) <* char '\'')

  parseWord :: Parser String String
  parseWord = many1 $ letter <|> digit <|> noneOf blacklist

  parseString :: Parser String AST
  parseString = String <$> (char '"' *> many (escaped <|> noneOf "\"") <* char '"')

  parseVoid :: Parser String AST
  parseVoid = do
    char '('
    char ')'
    return . Literal $ "Nil"

  parseBeginSugar :: Parser String AST
  parseBeginSugar = do
    lexeme $ char '{'
    expr <- many parse
    char '}'
    return $ Node (Literal "begin") [List expr]

  parseListSugar :: Parser String AST
  parseListSugar = do
    lexeme $ char '['
    expr <- many parse
    char ']'
    return $ List expr

  parseNumber :: Parser String AST
  parseNumber = do
    sign <- optional $ char '-'
    num <- many1 digit
    return . Integer . read $ parseSign sign ++ num
    where parseSign s = if isJust s then let (Just x) = s in "-" else ""

  -- this function should be used only if AST is integer
  getInteger :: AST -> Integer
  getInteger (Integer i) = i
  getInteger _ = error "Not an integer"

  parseFloat :: Parser String AST
  parseFloat = do
    num <- show . getInteger <$> parseNumber
    char '.'
    dec <- many1 digit
    return $ Float (read $ num ++ "." ++ dec)

  escaped :: Parser String Char
  escaped = do
    char '\\'
    x <- oneOf codes
    let z = zip codes replacements
    return $ fromMaybe x (lookup x z)
  codes        = ['b',  'n',  'f',  'r',  't',  '\\', '\"', '/']
  replacements = ['\b', '\n', '\f', '\r', '\t', '\\', '\"', '/']

  parseSugar :: Parser String AST
  parseSugar = choices
    [
      parseBeginSugar,
      parseListSugar
    ]

  parse :: Parser String AST
  parse = lexeme . choices $
    [
      parseSugar,
      parseExpr,
      parseString,
      parseVoid,
      parseChar,
      parseFloat,
      parseNumber,
      Literal <$> parseWord
    ]

  -- lexeme take a parser p and ignore spaces while consuming parser
  lexeme :: Monad m => ParserT String e m a -> ParserT String e m a
  lexeme p = p <* spaces

  trim :: String -> String
  trim = dropWhile (== ' ')

  -- remove eol from string
  format :: String -> String
  format e = concat $ filter (\z -> not (null z) && (head z /= ';')) (lines e)
  