romname = prng

run: $(romname).nes
	fceux -lua debug.lua bin\$(romname).nes

$(romname).nes: $(romname).o
	ld65 bin\$(romname).o -o bin\$(romname).nes --target nes -v

$(romname).o: $(romname).asm outdir
	ca65 $(romname).asm -o bin\$(romname).o -l bin\$(romname).lst --verbose

outdir:
	if not exist bin mkdir bin
    
clean:
	if exist bin rmdir /s /q bin
