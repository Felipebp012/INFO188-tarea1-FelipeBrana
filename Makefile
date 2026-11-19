GHC   = ghc
FLAGS = -O2 -Wall -Wno-unused-imports -outputdir build

prog: main.hs Automata.hs Simulacion.hs
	$(GHC) $(FLAGS) main.hs -o prog

run: prog
	./prog 90 31 8

clean:
	rm -rf build prog

.PHONY: run clean
