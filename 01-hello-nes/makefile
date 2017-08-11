hello.nes: hello.o reset.o nes.cfg
	ld65 -C nes.cfg -o bin\hello.nes bin\reset.o bin\hello.o nes.lib

reset.o: reset.s outdir
	ca65 reset.s -o bin\reset.o

hello.o: hello.s outdir
	ca65 bin\hello.s

hello.s: hello.c outdir
	cc65 -Oi hello.c -o bin\hello.s --add-source

outdir:
	if not exist bin mkdir bin
    
clean:
	if exist bin rmdir /s /q bin
