run: hello.nes
#	hxd bin\hello.nes
	fceux bin\hello.nes

hello.nes: hello.o
	cl65 bin\hello.o -o bin\hello.nes --target nes --verbose

hello.o: hello.s outdir
	ca65 hello.s -o bin\hello.o --verbose

outdir:
	if not exist bin mkdir bin
    
clean:
	if exist bin rmdir /s /q bin
