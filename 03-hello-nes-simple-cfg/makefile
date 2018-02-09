run: hello.nes
#	hxd bin\hello.nes
#	notepad bin\hello.lst
	fceux bin\hello.nes

hello.nes: hello.o
	ld65 bin\hello.o -o bin\hello.nes --config nes.cfg -v

hello.o: hello.s outdir
	ca65 hello.s -o bin\hello.o -l bin\hello.lst --verbose

outdir:
	if not exist bin mkdir bin
    
clean:
	if exist bin rmdir /s /q bin
