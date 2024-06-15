// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

// #include "firmware.h"
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#define reg_spictrl (*(volatile uint32_t *)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t *)0x02000004)
#define reg_uart_data (*(volatile uint32_t *)0x02000008)
#define reg_leds (*(volatile uint32_t *)0x03000000)

#define MEM_TOTAL 0x1000 /* 128 KB */
#define AIP_IP_IPDUMMY 0x80000100
#define AIP_IP_IPCONV 0x80000300

#define AIP_DATAOUT 0
#define AIP_DATAIN 1
#define AIP_CONFIG 2
#define AIP_START 3

#define IP_CONV_GET_ID 		0x1F  //localidad 31
#define IP_CONV_MEM_Y		0x0	  //localidad 0	
#define IP_CONV_MEM_Z		0x2
#define IP_CONV_CONF_REG	0x4	  // conf reg
#define IP_STATUS			0x1E  // status

/* Punteros a memoria */
#define AEM_Y		0x01	//Set Write Address Pointer of MEM_Y
#define AEM_Z		0x03	//Set Read Address Pointer of MEM_Z
#define AONFREG		0x05	//Set Write Address of CONFREG


#define MAX_DATA 4
#define OUTPUT_MAX 64

typedef struct
{
	uint32_t aip_dataOut;
	uint32_t aip_dataIn;
	uint32_t aip_config;
	uint32_t aip_start;
} aip_regs;

void putchar(char c);
void print(const char *p);
void print_hex(uint32_t v, int digits);
void print_dec(uint32_t v);
uint8_t aip_writeData(aip_regs *port, uint8_t config, uint32_t *data, uint32_t size);
uint8_t aip_readData(aip_regs *port, uint8_t config, uint32_t *data, uint32_t size);
uint8_t aip_start(aip_regs *port);
void run_convolution(void);

char *logo =

	"              vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n"
	"                  vvvvvvvvvvvvvvvvvvvvvvvvvvvv\n"
	"rrrrrrrrrrrrr       vvvvvvvvvvvvvvvvvvvvvvvvvv\n"
	"rrrrrrrrrrrrrrrr      vvvvvvvvvvvvvvvvvvvvvvvv\n"
	"rrrrrrrrrrrrrrrrrr    vvvvvvvvvvvvvvvvvvvvvvvv\n"
	"rrrrrrrrrrrrrrrrrr    vvvvvvvvvvvvvvvvvvvvvvvv\n"
	"rrrrrrrrrrrrrrrrrr    vvvvvvvvvvvvvvvvvvvvvvvv\n"
	"rrrrrrrrrrrrrrrr      vvvvvvvvvvvvvvvvvvvvvv  \n"
	"rrrrrrrrrrrrr       vvvvvvvvvvvvvvvvvvvvvv    \n"
	"rr                vvvvvvvvvvvvvvvvvvvvvv      \n"
	"rr            vvvvvvvvvvvvvvvvvvvvvvvv      rr\n"
	"rrrr      vvvvvvvvvvvvvvvvvvvvvvvvvv      rrrr\n"
	"rrrrrr      vvvvvvvvvvvvvvvvvvvvvv      rrrrrr\n"
	"rrrrrrrr      vvvvvvvvvvvvvvvvvv      rrrrrrrr\n"
	"rrrrrrrrrr      vvvvvvvvvvvvvv      rrrrrrrrrr\n"
	"rrrrrrrrrrrr      vvvvvvvvvv      rrrrrrrrrrrr\n"
	"rrrrrrrrrrrrrr      vvvvvv      rrrrrrrrrrrrrr\n"
	"rrrrrrrrrrrrrrrr      vv      rrrrrrrrrrrrrrrr\n"
	"rrrrrrrrrrrrrrrrrr          rrrrrrrrrrrrrrrrrr\n"
	"rrrrrrrrrrrrrrrrrrrr      rrrrrrrrrrrrrrrrrrrr\n"
	"rrrrrrrrrrrrrrrrrrrrrr  rrrrrrrrrrrrrrrrrrrrrr\n"
	"\n"
	"       PicoSoC with DSP Accelerators\n\n";

void main(void)
{

	// aip_regs ipConv;
	// uint8_t catchError;

	// reg_uart_clkdiv = 104; // 12 MHz/ 115200 Baud
	reg_uart_clkdiv = 434; //50 MHz/ 115200 Baud
	// print("Booting..\n");

	reg_leds = 63;
	// set_flash_qspi_flag();

	reg_leds = 127;

	print("Lets Configure the IPDUMMY Module!\n");

	uint32_t i = 0;
	// uint32_t data [MAX_DATA] ;
	// uint32_t data_read[MAX_DATA];

	// data_read[0] = 0;
	// data_read[1] = 0;
	// data_read[2] = 0;
	// data_read[3] = 0;
	// data_read[4] = 0;
	// data_read[5] = 0;
	// data_read[6] = 0;
	// data_read[7] = 0;

	// aip_regs * aipTest = (aip_regs *)AIP_IPDUMMY;
	// uint32_t *ptr = (uint32_t*)AIP_IP_IPDUMMY;
	
	uint32_t *ptr = (uint32_t *)AIP_IP_IPCONV;

	// *ptr = 0x0000BEAF;
	// *(ptr + 1) = 0x000BEAF0;
	// *(ptr + 2) = 0x00BEAF00;
	// *(ptr + 3) = 0x0BEAF000;

	// *ptr 		= 0x01;
	// *(ptr+1)	= 0x02;
	// *(ptr+2)	= 0x03;
	// *(ptr+3)	= 0x04;

	print("Reading IPID !\n");
	uint32_t IPID = 0;
	*(ptr + AIP_CONFIG) = 31;
	IPID = *(ptr + AIP_DATAOUT);
	print_dec(IPID);
	//print_hex(IPID, 8);
	print("\n");
	print("\n");

	uint32_t memY[MAX_DATA] = {0,1,2,3};

	for(i=0; i<MAX_DATA; i++)
		memY[i] = i;

	/* CONFIGURAR Y PREPARAR LA CONVOLUCION */
	*(ptr + AIP_CONFIG) = AONFREG; // point to confreg address
	*(ptr + AIP_DATAIN) = 0x0;	//offset 0

	*(ptr + AIP_CONFIG) = IP_CONV_CONF_REG; // point to confreg
	*(ptr + AIP_DATAIN) = MAX_DATA;	// send data
	
	*(ptr + AIP_CONFIG) = AEM_Y; // point to mem Y address
	*(ptr + AIP_DATAIN) = 0x0; //offset 0

	*(ptr + AIP_CONFIG) = IP_CONV_MEM_Y; // point to MEM Y
	for (i = 0; i < 4; i++)
	{
		*(ptr + AIP_DATAIN) = (uint32_t)(*(memY + i)); // send data
	}

	/* START CORE */
	*(ptr + AIP_START) = 0x1;

	/* READ STATUS */
	uint32_t getStatus;
	*(ptr + AIP_CONFIG) = IP_STATUS;
	//while(!getStatus){
	while(!(getStatus&0x1)){
		getStatus = *(ptr + AIP_DATAOUT);
	}

	print("DONE!!");
	print("resultado:");
	/* RECIBIR DATOS DEL CORE */
	uint32_t resultConvolution[OUTPUT_MAX];
	*(ptr + AIP_CONFIG) = IP_CONV_MEM_Z; // point to mem z
	for(i = 0; i < OUTPUT_MAX; i++){
		resultConvolution[i] = *(ptr + AIP_DATAOUT);
		print_dec(resultConvolution[i]);
		print(" ");
	}

	/* LIMPIAR BANDERA STATUS */
	*(ptr + AIP_CONFIG) = IP_STATUS;
	*(ptr + AIP_DATAIN) = 0x0;

		

	
	/*
	print("aip_writing to IPDUMMY - initialized to zero !\n");
	*(ptr + AIP_CONFIG) = 3;   // AMEMIN_DDSParam,0b00011,1,W,We Pointer of MMEMIN_DDSParam
	*(ptr + AIP_DATAIN) = 0x7; // Set ptr MEMIN_DDSParam 7,
	*(ptr + AIP_CONFIG) = 2;   // MMEMIN,0b00010,1,W,We Pointer of MMEMIN_DDSParam
	*(ptr + AIP_DATAIN) = 0;   // Clean  [self.__opCode], 1, 7, self.__addrs)
	*(ptr + AIP_START) = 1;

	print("Configuring IPDummy !\n");
	*(ptr + AIP_CONFIG) = 3; // AMEMIN_DDSParam,0b00011,1,W,We Pointer of MMEMIN_DDSParam
	*(ptr + AIP_DATAIN) = 0; // Ste ptr to 0
	*(ptr + AIP_CONFIG) = 2; // CFG,MMEMIN_DDSParam,0b00010,8,W,DDS parameters
	print("Configuring IPDummy  !\n");
	*(ptr + AIP_DATAIN) = 0x03AFFFFF; //

	*(ptr + AIP_DATAIN) = 0x002FFFFF; //
	*(ptr + AIP_DATAIN) = 0x00000400; //
	*(ptr + AIP_DATAIN) = 0x00000400; //
	*(ptr + AIP_DATAIN) = 0x0000000a; //
	*(ptr + AIP_DATAIN) = 0x00000020; //
	*(ptr + AIP_DATAIN) = 0x00000008; //

	*(ptr + AIP_DATAIN) = 0x00000010; //
	*(ptr + AIP_CONFIG) = 6;		  // writing CCONFREG just for testing
	*/

	//*(ptr + AIP_START) = 1;
	print("aip_writeData!\n");





	// for (i = 0; i < 100; i++){
	for (i = 0; i < 100000; i++)
	{
		__asm__ volatile("nop"); // asm volatile("");
	}

	reg_leds = 31;

	reg_leds = 1;
	print("\n");

	i=0;
	while (1)
	{
		// reg_leds = resultConvolution[i];
		// reg_leds = 1;
		// i=i+1;
		// if(i<OUTPUT_MAX){
		// 	i=0;
		// }
		i++;	
		if (i < OUTPUT_MAX)
			reg_leds = resultConvolution[i];
		else
			reg_leds = 1;

		// if (reg_leds < 128)
		// 	reg_leds = reg_leds + 1;
		// else
		// 	reg_leds = 1;
		// for (int rep = 200; rep > 0; rep--)
		for (int rep = 100000; rep > 0; rep--)
		{
			__asm__ volatile("nop"); // asm volatile("");
		}
		
	}
}

// --------------------------------------------------------

void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--)
	{
		char c = "0123456789abcdef"[(v >> (4 * i)) & 15];
		if (c == '0' && i >= digits)
			continue;
		putchar(c);
		digits = i;
	}
}

void print_dec(uint32_t v)
{
	if (v >= 1000)
	{
		print(">=1000");
		return;
	}

	if (v >= 900)
	{
		putchar('9');
		v -= 900;
	}
	else if (v >= 800)
	{
		putchar('8');
		v -= 800;
	}
	else if (v >= 700)
	{
		putchar('7');
		v -= 700;
	}
	else if (v >= 600)
	{
		putchar('6');
		v -= 600;
	}
	else if (v >= 500)
	{
		putchar('5');
		v -= 500;
	}
	else if (v >= 400)
	{
		putchar('4');
		v -= 400;
	}
	else if (v >= 300)
	{
		putchar('3');
		v -= 300;
	}
	else if (v >= 200)
	{
		putchar('2');
		v -= 200;
	}
	else if (v >= 100)
	{
		putchar('1');
		v -= 100;
	}

	if (v >= 90)
	{
		putchar('9');
		v -= 90;
	}
	else if (v >= 80)
	{
		putchar('8');
		v -= 80;
	}
	else if (v >= 70)
	{
		putchar('7');
		v -= 70;
	}
	else if (v >= 60)
	{
		putchar('6');
		v -= 60;
	}
	else if (v >= 50)
	{
		putchar('5');
		v -= 50;
	}
	else if (v >= 40)
	{
		putchar('4');
		v -= 40;
	}
	else if (v >= 30)
	{
		putchar('3');
		v -= 30;
	}
	else if (v >= 20)
	{
		putchar('2');
		v -= 20;
	}
	else if (v >= 10)
	{
		putchar('1');
		v -= 10;
	}

	if (v >= 9)
	{
		putchar('9');
		v -= 9;
	}
	else if (v >= 8)
	{
		putchar('8');
		v -= 8;
	}
	else if (v >= 7)
	{
		putchar('7');
		v -= 7;
	}
	else if (v >= 6)
	{
		putchar('6');
		v -= 6;
	}
	else if (v >= 5)
	{
		putchar('5');
		v -= 5;
	}
	else if (v >= 4)
	{
		putchar('4');
		v -= 4;
	}
	else if (v >= 3)
	{
		putchar('3');
		v -= 3;
	}
	else if (v >= 2)
	{
		putchar('2');
		v -= 2;
	}
	else if (v >= 1)
	{
		putchar('1');
		v -= 1;
	}
	else
		putchar('0');
}

// --------------------------------------------------------
uint8_t aip_writeData(aip_regs *port, uint8_t config, uint32_t *data, uint32_t size)
{
	if (!size)
		return 1;

	port->aip_config = config;

	for (uint32_t i = 0; i < size; i++)
	{
		port->aip_dataIn = *(data + i);
	}

	return 0;
}

uint8_t aip_readData(aip_regs *port, uint8_t config, uint32_t *data, uint32_t size)
{
	if (!size)
		return 1;

	port->aip_config = config;

	for (uint32_t i = 0; i < size; i++)
	{
		*(data + i) = port->aip_dataOut;
	}

	return 0;
}

uint8_t aip_start(aip_regs *port)
{
	port->aip_start = 0x1;

	__asm__ volatile("nop"); // asm volatile("");

	// port->aip_start = 3;

	return 0;
}

void run_convolution(void){

	print("Lets Configure the IPDUMMY Module!\n");

	uint32_t i = 0;
	uint32_t *ptr = (uint32_t *)AIP_IP_IPCONV;

	print("Reading IPID !\n");
	uint32_t IPID = 0;
	*(ptr + AIP_CONFIG) = 31;
	IPID = *(ptr + AIP_DATAOUT);
	print_dec(IPID);
	//print_hex(IPID, 8);
	print("\n");
	print("\n");

	uint32_t memY[MAX_DATA] = {0,1,2,3};

	for(i=0; i<MAX_DATA; i++)
		memY[i] = i;

	/* CONFIGURAR Y PREPARAR LA CONVOLUCION */
	*(ptr + AIP_CONFIG) = AONFREG; // point to confreg address
	*(ptr + AIP_DATAIN) = 0x0;	//offset 0

	*(ptr + AIP_CONFIG) = IP_CONV_CONF_REG; // point to confreg
	*(ptr + AIP_DATAIN) = MAX_DATA;	// send data
	
	*(ptr + AIP_CONFIG) = AEM_Y; // point to mem Y address
	*(ptr + AIP_DATAIN) = 0x0; //offset 0

	*(ptr + AIP_CONFIG) = IP_CONV_MEM_Y; // point to MEM Y
	for (i = 0; i < 4; i++)
	{
		*(ptr + AIP_DATAIN) = (uint32_t)(*(memY + i)); // send data
	}

	/* START CORE */
	*(ptr + AIP_START) = 0x1;

	/* READ STATUS */
	uint32_t getStatus;
	*(ptr + AIP_CONFIG) = IP_STATUS;
	//while(!getStatus){
	while(!(getStatus&0x1)){
		getStatus = *(ptr + AIP_DATAOUT);
	}

	print("DONE!!");

	/* RECIBIR DATOS DEL CORE */
	uint32_t resultConvolution[OUTPUT_MAX];
	*(ptr + AIP_CONFIG) = IP_CONV_MEM_Z; // point to mem z
	for(i = 0; i < OUTPUT_MAX; i++){
		resultConvolution[i] = *(ptr + AIP_DATAOUT);
	}

	/* LIMPIAR BANDERA STATUS */
	*(ptr + AIP_CONFIG) = IP_STATUS;
	*(ptr + AIP_DATAIN) = 0x0;

	print("aip_writeData!\n");

}