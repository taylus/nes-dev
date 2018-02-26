romname = palette-cycling

run: $(romname).nes
	fceux bin\$(romname).nes

$(romname).nes: $(romname).o
	ld65 bin\$(romname).o -o bin\$(romname).nes --config nes.cfg -v

$(romname).o: $(romname).s outdir
	ca65 $(romname).s -o bin\$(romname).o -l bin\$(romname).lst --verbose

outdir:
	if not exist bin mkdir bin
    
clean:
	if exist bin rmdir /s /q bin
