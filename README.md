# INFO188 – Tarea 1: Autómata celular 1D en Haskell
**Profesor:** Cristóbal Navarro
**Integrantes:** Felipe Braná, Rodrigo González

---

## 1. Introducción al problema

Un **autómata celular elemental unidimensional** es una fila de células, cada una **viva** o **muerta**. El tiempo avanza por generaciones: osea, el nuevo valor de cada célula depende únicamente de tres valores: ella misma y sus dos vecinas (izquierda y derecha).

La forma en que se combinan esos tres valores la define una **regla de Wolfram**, un número entre 0 y 255. Como hay 3 células en la vecindad, existen 8 (dos al cubo) vecindades posibles, y cada una produce una salida de 1 bit. Esos 8 bits forman el número de la regla. Por ejemplo, la regla 30 es `00011110` en binario:

```
Vecindad:  111 110 101 100 011 010 001 000
Nuevo:      0   0   0   1   1   1   1   0
```

Además, la fila tiene **bordes periódicos**, osea,  la primera y la última célula son vecinas entre sí (es como un anillo)

## 2. Herramientas utilizadas y cómo ayudan

| Herramienta | Para qué se usa | Cómo ayuda al problema |
|---|---|---|
| **Registro (`data Automata`)** | Agrupa `celdas`, `regla` y `generacion`. | Todo el estado del autómata viaja junto y con nombre. Se actualiza con la sintaxis `a { celdas = . }`, sin modificar el original. |
| **Funciones puras y listas** | `paso`, `tablaRegla`, `nuevoValor`. | Una generación es una transformación pura `Automata -> Automata`, fácil de razonar y de probar. |
| **`Data.Bits` (`testBit`)** | Leer el bit k del número de regla. | Permite pasar del número de regla a su tabla de 8 casos sin escribir las 256 reglas a mano. |
| **`zipWith3`** | Aplicar la regla a cada trío (izq, centro, der). | Recorre la fila completa de una vez, emparejando cada célula con sus dos vecinas. |
| **Mónada `State` (`Control.Monad.State`)** | Simular las generaciones. | Con `get`, `put`, `modify`, `gets` y `replicateM_`, el estado no se pasa a mano entre funciones. |
| **`StateT Automata IO`** | Imprimir cada fila mientras se simula. | Combina el estado del autómata con la salida por pantalla. |
| **Generador congruencial lineal propio** | Condición inicial aleatoria. | Evita depender del paquete externo `random`, así que el proyecto compila solo con GHC. |
| **`readMaybe` y `getArgs`** | Leer y validar los argumentos. | Rechaza entradas inválidas con un mensaje de uso en vez de fallar. |
| **Makefile + GHC (`-O2 -Wall`)** | Compilar el proyecto. | Un solo `make` genera el ejecutable `prog`. |

---

## 3. La solución

### Cómo funciona

1. **Input** `main.hs` recibe `<regla> <ancho> <generaciones>`, los valida y, si algo es inválido, muestra un mensaje de uso.
2. **Estado inicial.** Se crea un `Automata` con una fila de `ancho` células, todas muertas excepto la central, junto con la regla y la generación 0.
3. **Una generación (`paso`).** Para cada célula se toma el trío (vecina izquierda, ella misma, vecina derecha). La fila se trata como un anillo, así que la vecina izquierda de la primera célula es la última, y la derecha de la última es la primera. Ese trío se lee como un número binario de 0 a 7, y el bit con ese número en la regla es el nuevo valor de la célula.
4. **Repetición con `State`.** La simulación es una secuencia de acciones sobre el estado: imprimir la fila actual, avanzar un paso y repetir. La mónada `State` mantiene el autómata de una acción a la siguiente sin pasarlo a mano.
5. **Salida.** Cada fila se dibuja con `#` para una célula viva y un espacio para una muerta. Se imprimen exactamente `<generaciones>` filas, la primera es la condición inicial.

El flujo completo es:

```
argumentos --> estado inicial --> (imprimir fila, paso) repetido --> filas en pantalla
 main.hs        Automata.hs              Simulacion.hs                  main.hs
```

**Ejemplo:** regla 90 (cada célula pasa a valer 1 si exactamente una de sus dos vecinas está viva), ancho 5.

```
generación 0:  0 0 1 0 0
generación 1:  0 1 0 1 0
generación 2:  1 0 0 0 1
```

En la generación 2 se ve el borde periódico: la primera célula nace porque su vecina derecha está viva y su vecina izquierda es la última célula, que está muerta. Lo mismo ocurre en el otro extremo. El programa muestra este mismo resultado:

```
$ ./prog 90 5 3
  #
 # #
#   #
```

Cada módulo se encarga de una parte: `Automata.hs` define el autómata y su paso (pasos 2 y 3), `Simulacion.hs` lo repite con `State` (paso 4) y `main.hs` conecta todo con la terminal (pasos 1 y 5).

### 4. Estructura del proyecto y modelo

| Archivo | Contenido |
|---|---|
| `main.hs` | Programa principal: lectura de argumentos, validación y ejecución. |
| `Automata.hs` | Registro `Automata`, tabla de la regla, `paso` puro y condiciones iniciales. |
| `Simulacion.hs` | Simulación con la mónada `State` (`paso :: State Automata ()`). |
| `Makefile` | `make` (compila), `make run` (ejemplo) y `make clean` (limpia). |

#### Modelo como registro

```haskell
data Automata = Automata
  { celdas     :: [Bool]
  , regla      :: Int
  , generacion :: Int
  }
```

`True` es una célula viva y `False` una muerta. Una generación es `paso :: Automata -> Automata`, que actualiza `celdas` e incrementa `generacion`.

### 5. Reglas de Wolfram y bordes periódicos

`tablaRegla :: Int -> [(Vecindad, Bool)]` entrega, dado el número de regla, el nuevo valor para **las 8 vecindades** en el orden `111 110 101 100 011 010 001 000`. La vecindad `(izq, centro, der)` se lee como un número binario *k* de 3 bits, y el nuevo valor es el **bit *k* de la regla**.

Los bordes periódicos se resuelven tratando la fila como un anillo:

```haskell
izqs = last cs : init cs
ders = tail cs ++ [head cs]
nuevas = zipWith3 (\l c r -> nuevoValor (regla a) (l, c, r)) izqs cs ders
```

`izqs` contiene la vecina izquierda de cada célula y `ders` la derecha. `zipWith3` aplica la regla a cada trío.

### 6. Simulación con la mónada `State`

```haskell
paso :: State Automata ()
paso = do
  a <- get
  put (Automata.paso a)

simular :: Int -> State Automata ()
simular n = replicateM_ n paso
```

- `paso` avanza una generación con `get` y `put`.
- `simular` repite el paso con `replicateM_`.
- `simularIO` corre sobre `StateT Automata IO`, usa `gets celdas` para leer la fila e imprimirla, y `modify` para avanzar.
- `main` solo entrega el estado inicial con `evalStateT`. El estado nunca se pasa a mano.

---

## 7. El problema resuelto y cómo ejecutarlo

Con la solución anterior, el programa simula cualquier regla de Wolfram con bordes periódicos, desde una célula central o desde una fila aleatoria.

#### Compilación y uso


```bash
make
./prog <regla> <ancho> <generaciones> [--aleatorio [semilla]]
```

El programa parte con **una sola célula viva en el centro** (índice `ancho div 2`). Se imprimen exactamente `<generaciones>` filas: la primera es la condición inicial y las siguientes son las generaciones sucesivas.

**Regla 90, ancho 31, 8 generaciones** (triángulo de Sierpinski):

```
$ ./prog 90 31 8
               #
              # #
             #   #
            # # # #
           #       #
          # #     # #
         #   #   #   #
        # # # # # # # #
```

**Regla 30, ancho 21, 10 generaciones** (comportamiento caótico):

```
$ ./prog 30 21 10
          #
         ###
        ##  #
       ## ####
      ##  #   #
     ## #### ###
    ##  #    #  #
   ## ####  ######
  ##  #   ###     #
 ## #### ##  #   ###
```

#### Condición inicial aleatoria

La opción `--aleatorio [semilla]` genera la fila inicial con un generador congruencial lineal:

```
siguiente s = (s * 1103515245 + 12345) mod 2^31
```

Se toma un bit de cada valor generado. Sin semilla se usa `getCPUTime`; con semilla el resultado es **reproducible**.

```
$ ./prog 30 15 5 --aleatorio 42
#### ## ##    #
     #  # #  ##
#   ##### ####
## ##     #
#  # #   ###  #
```

#### Pruebas realizadas

- `./prog 90 31 8` produce el triángulo de Sierpinski esperado.
- Regla 30 y regla 90 con distintos anchos, incluyendo ancho 1.
- Condición inicial aleatoria con y sin semilla.
- 0 generaciones no imprime nada.
- Argumentos inválidos (por ejemplo `./prog 300 5 5`) muestran el mensaje de uso y terminan con código 1.

---

## 8. Conclusiones

- Separar el **modelo** (`Automata.hs`), la **simulación** (`Simulacion.hs`) y la **entrada/salida** (`main.hs`) permitió que la lógica del autómata sea pura y que los efectos queden en un solo lugar.
- Representar la regla como un número y leer sus bits con `testBit` resultó una solución compacta: sirve para las 256 reglas sin casos especiales.
- Los bordes periódicos se resolvieron en dos líneas con `last`, `init`, `tail` y `head`, gracias al estilo funcional sobre listas.
- La mónada `State` permitió escribir la simulación como una secuencia de acciones (`replicateM_ n paso`) sin pasar el estado manualmente, y `StateT` permitió sumar la impresión sin romper esa estructura.
- Las reglas simples producen comportamientos muy distintos: la regla 90 genera un patrón regular (Sierpinski) y la regla 30 uno de apariencia caótica, aunque ambas parten de una sola célula.
- Como mejora posible, las listas hacen que `last` y `init` recorran toda la fila en cada generación. Para anchos muy grandes convendría usar `Data.Vector` o un arreglo.

---

## Uso de IA

Se utilizó IA como apoyo para acelerar el desarrollo y para el formato de este README.MD.
