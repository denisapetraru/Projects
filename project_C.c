
#include <reg51.h>

sbit rs = P3^0;
sbit en = P3^1;

unsigned int  aux=0, tab[2];
float t=0;

void LCD_cmd(unsigned char);
void LCD_data(unsigned char);
void message();
void delay();
void port_init();
void temp_display();

void main(){
	port_init();
	message();
	
		temp_display();
	
}

void LCD_cmd(unsigned char x){
	P2 = x;
	rs = 0;
	en = 1;
	delay();
	en = 0;
}

void LCD_data(unsigned char x){
	P2 = x;
	rs = 1;
	en = 1;
	delay();
	en = 0;
}

void delay(){
	unsigned int i;
	for(i=0; i<1200; i++);
}

void message(){
		LCD_cmd(0x38); //5X7 MATRIX CRYSTAL
	  LCD_cmd(0x0E); // display on, cursion on
		LCD_cmd(0x0c); 
		LCD_cmd(0x80); //cursor at line 1, position 0
		LCD_data('T');
		LCD_data('e');
		LCD_data('m');
		LCD_data('p');
		LCD_data(':');
}

void port_init(){
	P1 = 0xFF;  //input
	P2 = 0;     //output
	P3 = 0;     //output
}

void temp_display(){
	t = (P1*0.019 + 0.019)/12.5;
	aux = t * 10000;
	tab[1] = aux/100%10;
	tab[0] = aux/1000%10;
	
 
	
	if(tab[0] == 0)
		      LCD_data(0x20);	
	else 		
					LCD_data(tab[0]+'0');
	LCD_data(tab[1]+'0');
	
	
}
