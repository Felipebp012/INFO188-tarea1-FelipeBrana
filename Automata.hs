-- | Autómata celular elemental 1D (reglas de Wolfram 0..255, bordes periódicos).
module Automata
  ( Automata(..)
  , Vecindad
  , tablaRegla
  , nuevoValor
  , nuevoAutomata
  , nuevoAleatorio
  , aleatorias
  , paso
  , render
  ) where

import Data.Bits (shiftR, testBit)
import Data.List (dropWhileEnd)

-- | Estado completo del autómata: fila de células, regla y generación actual.
data Automata = Automata
  { celdas     :: [Bool]   -- ^ True = viva, False = muerta
  , regla      :: Int      -- ^ número de regla de Wolfram (0..255)
  , generacion :: Int      -- ^ generación actual (0 = condición inicial)
  } deriving (Show, Eq)

-- | Vecindad (izquierda, centro, derecha).
type Vecindad = (Bool, Bool, Bool)

-- | Las 8 vecindades en el orden estándar: 111 110 101 100 011 010 001 000.
vecindades :: [Vecindad]
vecindades = [ (a, b, c) | a <- [True, False], b <- [True, False], c <- [True, False] ]

-- | Vecindad interpretada como número binario de 3 bits (0..7).
indice :: Vecindad -> Int
indice (a, b, c) = 4 * fromEnum a + 2 * fromEnum b + fromEnum c

-- | Tabla completa de la regla: para cada vecindad, el nuevo valor de la celda.
--   El bit número @k@ de la regla es la salida para la vecindad cuyo valor es @k@.
--   Ej. regla 30 = 00011110 => [0,0,0,1,1,1,1,0] para 111..000.
tablaRegla :: Int -> [(Vecindad, Bool)]
tablaRegla r = [ (v, testBit r (indice v)) | v <- vecindades ]

-- | Nuevo valor de una célula según la regla y su vecindad.
nuevoValor :: Int -> Vecindad -> Bool
nuevoValor r v = maybe False id (lookup v (tablaRegla r))

-- | Autómata de ancho @w@ con una sola célula viva al centro.
nuevoAutomata :: Int -> Int -> Automata
nuevoAutomata r w = Automata
  { celdas     = replicate izq False ++ [True] ++ replicate (w - izq - 1) False
  , regla      = r
  , generacion = 0
  }
  where izq = w `div` 2

-- | Generador congruencial lineal (sin dependencias externas).
siguiente :: Int -> Int
siguiente s = (s * 1103515245 + 12345) `mod` 2147483648

-- | @n@ booleanos pseudoaleatorios a partir de una semilla.
aleatorias :: Int -> Int -> [Bool]
aleatorias semilla n =
  take n [ testBit (s `shiftR` 16) 0 | s <- tail (iterate siguiente (abs semilla)) ]

-- | Autómata de ancho @w@ con condición inicial aleatoria.
nuevoAleatorio :: Int -> Int -> Int -> Automata
nuevoAleatorio semilla r w = Automata
  { celdas = aleatorias semilla w, regla = r, generacion = 0 }

-- | Una generación. Bordes periódicos: la fila es un anillo.
paso :: Automata -> Automata
paso a = a { celdas = nuevas, generacion = generacion a + 1 }
  where
    cs     = celdas a
    izqs   = last cs : init cs        -- vecina izquierda de cada célula
    ders   = tail cs ++ [head cs]     -- vecina derecha de cada célula
    nuevas = zipWith3 (\l c r -> nuevoValor (regla a) (l, c, r)) izqs cs ders

-- | Dibuja la fila: '#' viva, ' ' muerta (sin espacios sobrantes al final).
render :: [Bool] -> String
render = dropWhileEnd (== ' ') . map (\b -> if b then '#' else ' ')
