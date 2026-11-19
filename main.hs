module Main (main) where

import Control.Monad.State (evalStateT)
import System.CPUTime (getCPUTime)
import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)
import Text.Read (readMaybe)

import Automata (nuevoAleatorio, nuevoAutomata)
import Simulacion (simularIO)

uso :: IO a
uso = do
  prog <- getProgName
  hPutStrLn stderr $ "Uso: ./" ++ prog ++ " <regla 0..255> <ancho >= 1> <generaciones >= 0> [--aleatorio [semilla]]"
  hPutStrLn stderr $ "Ej.: ./" ++ prog ++ " 90 31 8"
  exitFailure

main :: IO ()
main = do
  args <- getArgs
  case args of
    (r : w : g : extra) ->
      case (readMaybe r, readMaybe w, readMaybe g) of
        (Just regla, Just ancho, Just gens)
          | regla >= 0 && regla <= 255 && ancho >= 1 && gens >= 0 -> do
              inicial <- case extra of
                [] -> return (nuevoAutomata regla ancho)
                ["--aleatorio"] -> do
                  t <- getCPUTime
                  return (nuevoAleatorio (fromIntegral (t `mod` 2147483647)) regla ancho)
                ["--aleatorio", s] -> maybe uso (\sem -> return (nuevoAleatorio sem regla ancho)) (readMaybe s)
                _ -> uso
              evalStateT (simularIO gens) inicial
        _ -> uso
    _ -> uso
