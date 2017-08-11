//the NES's Picture Processing Unit (PPU) exposes memory-mapped registers to the CPU at these locations:
#define PPU_CTRL    *((unsigned char*)0x2000)   //control register: set bit flags to control how the PPU behaves
#define PPU_MASK    *((unsigned char*)0x2001)   //mask register: set bit flags to control sprite rendering/color effects
#define PPU_STATUS  *((unsigned char*)0x2002)   //status register: reflects the state of various functions inside the PPU
#define PPU_SCROLL  *((unsigned char*)0x2005)   //scroll register: indicates which pixel of the nametable should be at (0,0) on the screen
#define PPU_ADDRESS *((unsigned char*)0x2006)   //address register: points to the address in video memory where we want PPU_DATA writes to go
#define PPU_DATA    *((unsigned char*)0x2007)   //data register: writes here store that value at *(PPU_ADDRESS) in video memory
//more info: https://wiki.nesdev.com/w/index.php/PPU_registers

//color palette: https://wiki.nesdev.com/w/index.php/PPU_palettes#2C02
#define COLOR_BLACK 0x1f
#define COLOR_GRAY 0x00
#define COLOR_LIGHTGRAY 0x10
#define COLOR_WHITE 0x20

unsigned char index;
const unsigned char TEXT[] = {"Hello, world!"};
const unsigned char PALETTE[] = {COLOR_BLACK, COLOR_WHITE, COLOR_WHITE, COLOR_WHITE};

void main(void) 
{
    //turn off the screen
    PPU_CTRL = 0x00;
    PPU_MASK = 0x00;
    
    //load the palette at PPU memory address 0x3f00, which is where it stores backgrounds
    //https://wiki.nesdev.com/w/index.php/PPU_palettes#Memory_Map
    PPU_ADDRESS = 0x3f;
    PPU_ADDRESS = 0x00;
    for (index = 0; index < sizeof(PALETTE); ++index)
    {
        PPU_DATA = PALETTE[index];
    }
    
    //load the text at address 0x21ca,
    //placing it about in the center of the screen
    PPU_ADDRESS = 0x21;
    PPU_ADDRESS = 0xca;
    for (index = 0; index < sizeof(TEXT); ++index)
    {
        PPU_DATA = TEXT[index];
    }
    
    //reset scroll position
    PPU_SCROLL = 0x00;  //horizontal offset
    PPU_SCROLL = 0x00;  //vertical offset
    
    //turn on the screen
    PPU_CTRL = 0x90;    
    PPU_MASK = 0x1e;    //show sprites and background in color
    
    //display the text forever
    while (1) {};
}
