-- Modulo principal
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Arrow ((&&&))
import Control.Monad (forM_, mzero, when)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.ST.Strict (ST)
import Control.Monad.State
  ( StateT,
    evalStateT,
    gets,
    modify,
    modify',
  )
import Control.Monad.Trans.Maybe (MaybeT, runMaybeT)
import Data.Array (Array, (!))
import Data.Array.ST
  ( MArray (newArray),
    STArray,
    readArray,
    runSTArray,
    writeArray,
  )
import Data.Foldable (Foldable (toList), foldl')
import qualified Data.Map.Strict as M
import qualified Data.Text as T
import qualified Data.Text.IO as T
import System.Console.Pretty
  ( Color (Blue, Green, White, Yellow),
    Style (Bold),
    bgColor,
    color,
    style,
  )
import System.IO (BufferMode (NoBuffering), hSetBuffering, stdout)
import System.Random (newStdGen, uniformR)

-- Funcao principal

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering

  wordMap <- getWordMap
  gen <- newStdGen
  let ix = fst $ uniformR (0, length wordMap - 1) gen

  when (ix < 0) $ error "Lista de palavras não encontrada"

  T.putStrLn "\ESC[92m████████╗\ESC[0m███████╗\ESC[91m██████╗ \ESC[92m███╗   ███╗ \ESC[0m██████╗ "
  T.putStrLn "\ESC[92m╚══██╔══╝\ESC[0m██╔════╝\ESC[91m██╔══██╗\ESC[92m████╗ ████║\ESC[0m██╔═══██╗"
  T.putStrLn "\ESC[92m   ██║   \ESC[0m█████╗  \ESC[91m██████╔╝\ESC[92m██╔████╔██║\ESC[0m██║   ██║"
  T.putStrLn "\ESC[92m   ██║   \ESC[0m██╔══╝  \ESC[91m██╔══██╗\ESC[92m██║╚██╔╝██║\ESC[0m██║   ██║"
  T.putStrLn "\ESC[92m   ██║   \ESC[0m███████╗\ESC[91m██║  ██║\ESC[92m██║ ╚═╝ ██║\ESC[0m╚██████╔╝"
  T.putStrLn "\ESC[92m   ╚═╝   \ESC[0m╚══════╝\ESC[91m╚═╝  ╚═╝\ESC[92m╚═╝     ╚═╝ \ESC[0m╚═════╝ "

  T.putStrLn introString

  evalStateT (loop $ runMaybeT game) $
    GS
      { _attemptMap =
          M.fromList $
            map (\letter -> (letter, Untested)) ['A' .. 'Z'],
        _guesses = 1,
        _wordMap = wordMap,
        _answer = fst $ M.elemAt ix wordMap,
        _maxGuesses = 6
      }

-- Tipo de dado para representar o estado do jogo

data GameState = GS
  { _attemptMap :: !(M.Map Char CharacterStatus),
    _guesses :: !Word,
    _wordMap :: !(M.Map T.Text T.Text),
    _answer :: !T.Text,
    _maxGuesses :: !Word
  }

-- Tipo de dado para representar o status de um caractere

data CharacterStatus
  = Untested
  | DoesntExist
  | WrongPlace
  | RightPlace
  deriving (Show, Eq, Ord)

-- Funcao para obter o mapa de palavras do arquivo

getWordMap :: IO (M.Map T.Text T.Text)
getWordMap = do
  allWords <- T.lines <$> T.readFile "palavras.txt"
  pure $ M.fromList $ map (T.map normalizeAccents &&& id) allWords
  where
    normalizeAccents 'Á' = 'A'
    normalizeAccents 'À' = 'A'
    normalizeAccents 'Ã' = 'A'
    normalizeAccents 'Â' = 'A'
    normalizeAccents 'É' = 'E'
    normalizeAccents 'Ê' = 'E'
    normalizeAccents 'Í' = 'I'
    normalizeAccents 'Õ' = 'O'
    normalizeAccents 'Ó' = 'O'
    normalizeAccents 'Ô' = 'O'
    normalizeAccents 'Ú' = 'U'
    normalizeAccents 'Ç' = 'C'
    normalizeAccents cha = cha

-- String de introducao

introString :: T.Text
introString =
  "Bem vindo ao Termo.hs!\nDigite "
    <> color Green ":?"
    <> " para ajuda, "
    <> color Green ":l"
    <> " para ver as letras adivinhadas, ou "
    <> color Green ":s"
    <> " para sair."

-- Funcao principal do loop do jogo

loop :: (Monad m) => m (Maybe a) -> m a
loop action = action >>= maybe (loop action) pure

-- Continuar o jogo

continue :: Game a
continue = mzero

-- Funcao para imprimir uma linha

printLnS :: (MonadIO m) => T.Text -> m ()
printLnS = liftIO . T.putStrLn

-- Tipo de dado para representar o jogo

type Game a = MaybeT (StateT GameState IO) a

-- Funcao principal do jogo

game :: Game ()
game = do
  displayAttemptNumbers

  let drawHelp = printLnS helpString
  let drawAttemptMap = gets _attemptMap >>= printLnS . showAttemptMap

  line <- liftIO T.getLine
  case line of
    ":s" -> pure ()
    ":?" -> drawHelp >> continue
    ":l" -> drawAttemptMap >> continue
    word -> makeAttempt $ T.toUpper word

-- Funcao para fazer uma tentativa

makeAttempt :: T.Text -> Game ()
makeAttempt word = do
  wordMap <- gets _wordMap

  if M.notMember word wordMap
    then do
      printLnS "Palavra inválida, por favor tente novamente"
      continue
    else do
      answer <- gets _answer
      guesses <- gets _guesses
      let attemptResult = showAttempt word answer
      printLnS $ renderAttempt word attemptResult
      let updm = updateAttemptMap word attemptResult . _attemptMap
      modify' (\s -> s {_attemptMap = updm s})
      maxGuesses <- gets _maxGuesses

      let msg = "A palavra era '" <> wordMap M.! answer <> "'"

      if word == answer
        then do
          printLnS $ "Você ganhou! " <> msg
          pure ()
        else
          if guesses >= maxGuesses
            then do
              printLnS $ "Você perdeu! " <> msg
              pure ()
            else do
              modify (\s -> s {_guesses = _guesses s + 1})
              continue

-- String de ajuda

helpString :: T.Text
helpString =
  style Bold "Regras\n\n"
    <> "Você tem 6 tentativas para adivinhar a palavra. Cada\n"
    <> "tentativa deve ser uma palavra de 5 letras válida.\n\n"
    <> "Após cada tentativa, as cores das letras\n"
    <> "indicarão quão próxima a tentativa está da resposta.\n\n"
    <> "Ignore acentuação e cedilha.\n\n"
    <> style Bold "Exemplos\n\n"
    <> colour RightPlace " M "
    <> " A N G A \nA letra"
    <> color Green " M "
    <> "existe na palavra e está na posição correta.\n\n"
    <> " V "
    <> colour WrongPlace " I "
    <> " O  L  A \nA letra"
    <> color Yellow " I "
    <> "existe na palavra mas em outra posição.\n\n"
    <> " P  L  U "
    <> colour DoesntExist " M "
    <> " A \nA letra M não existe na palavra.\n"

-- Funcao de colorir o caractere baseado no status

colour :: CharacterStatus -> T.Text -> T.Text
colour Untested = id
colour DoesntExist = style Bold . color Blue . bgColor White
colour WrongPlace = style Bold . color White . bgColor Yellow
colour RightPlace = style Bold . color White . bgColor Green

-- Funcao para mostrar o mapa de tentativas

showAttemptMap :: M.Map Char CharacterStatus -> T.Text
showAttemptMap amap = T.concatMap showColoredChar letters
  where
    letters = "QWERTYUIOP\nASDFGHJKL\n ZXCVBNM"
    showColoredChar c =
      colour
        (M.findWithDefault Untested c amap)
        (showPrettyChar c)

-- Funcao para exibir o numero de tentativas

displayAttemptNumbers :: Game ()
displayAttemptNumbers = do
  currentGuess <- gets _guesses
  maxGuesses <- gets _maxGuesses
  liftIO . putStr $
    "Digite sua tentativa ["
      <> show currentGuess
      <> "/"
      <> show maxGuesses
      <> "]: "

-- Funcao para exibir o caractere formatado

showPrettyChar :: Char -> T.Text
showPrettyChar c = T.cons ' ' $ T.cons c " "

-- Funcao para mostrar a tentativa

showAttempt :: T.Text -> T.Text -> Array Int CharacterStatus
showAttempt attempt answer = runSTArray $ do
  let n = T.length answer - 1
  res <- newArray (0, n) DoesntExist
  amap <- newArray ('A', 'Z') 0 :: ST s (STArray s Char Int)

  forM_ (T.unpack answer) $ \c -> do
    val <- readArray amap c
    writeArray amap c (val + 1)

  forM_ [0 .. n] $ \i -> do
    let answerC = T.index answer i
    let attemptC = T.index attempt i
    when (answerC == attemptC) $ do
      writeArray res i RightPlace
      val <- readArray amap answerC
      writeArray amap answerC (val - 1)

  forM_ [0 .. n] $ \i -> do
    let answerC = T.index answer i
    let attemptC = T.index attempt i
    val <- readArray amap attemptC
    when (answerC /= attemptC && val > 0) $ do
      writeArray amap attemptC (val - 1)
      writeArray res i WrongPlace

  pure res

-- Funcao para renderizar a tentativa

renderAttempt :: T.Text -> Array Int CharacterStatus -> T.Text
renderAttempt word arr =
  T.concat $
    zipWith
      (\c s -> colour s $ showPrettyChar c)
      (T.unpack word)
      (toList arr)

-- Funcao para atualizar o mapa de tentativas

updateAttemptMap ::
  T.Text ->
  Array Int CharacterStatus ->
  M.Map Char CharacterStatus ->
  M.Map Char CharacterStatus
updateAttemptMap word res amap =
  foldl' (\acc (n, c) -> M.adjust (\cha -> max cha $ res ! n) c acc) amap $
    zip [0 ..] $
      T.unpack word
