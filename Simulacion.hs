-- | Simulación del autómata usando la mónada State.
module Simulacion
  ( paso
  , simular
  , simularIO
  ) where

import Control.Monad (replicateM_)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State

import Automata (Automata (..), render)
import qualified Automata as A

-- | Un paso de simulación como acción de estado (el estado no se pasa a mano).
paso :: State Automata ()
paso = do
  a <- get          -- leer el estado
  put (A.paso a)    -- escribir el siguiente

-- | Avanza @n@ generaciones.
simular :: Int -> State Automata ()
simular n = replicateM_ n paso

-- | Imprime la fila actual (lee el estado con gets).
imprimirFila :: StateT Automata IO ()
imprimirFila = do
  fila <- gets celdas
  liftIO (putStrLn (render fila))

-- | Imprime @n@ generaciones (la condición inicial es la primera fila).
--   El avance usa 'simular 1', es decir, el mismo 'paso' de State.
simularIO :: Int -> StateT Automata IO ()
simularIO n
  | n <= 0    = return ()
  | otherwise = do
      imprimirFila
      replicateM_ (n - 1) $ do
        modify (execState (simular 1))   -- avanza con la mónada State pura
        imprimirFila
