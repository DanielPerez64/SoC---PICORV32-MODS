
CROSS=/opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS=
ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
COMPRESSED_ISA = C
PYTHON = python3.11

NAME = PICORV32_Module
IPDUMMY_SRC = ../mods/00001001/hdl/src/
IPCONV_SRC = ../mods/1000500B/hdl/src/
BASICBLOCKS = ../mods/basicblocks/
MODULES= modules

# ---- iCE40 IceBreaker Board ----

icebsim: icebreaker_tb.vvp icebreaker_fw.hex
	vvp -N $< +firmware=firmware/icebreaker_fw.hex

icebsim_max: max10_tb.vvp altera_out.txt
	vvp -N $< +firmware=firmware/altera_out.txt
	
test_aip_vcd: picoSoC_DDS_tb.vvp firmware/firmware.hex
	$(VVP) -N $< +vcd +trace +noerror

synth: $(BASICBLOCKS)memories/*.v $(BASICBLOCKS)arithmetic/*.v $(BASICBLOCKS)sequential/*.v $(IPDUMMY_SRC)*.v $(IPCONV_SRC)*.v $(BASICBLOCKS)aip/aipModules.v $(IPCONV_SRC)*.sv  testbench_dummy_picosoc_AIP.v native_aip.v ipdummy_picosoc.v picosoc_AIP.v ID0000200F_aip.v simpleuart.v picorv32.v
	
#synth: $(BASICBLOCKS)*.v $(BASICBLOCKS)memories/simple_dual_port_ram_single_clk.v $(BASICBLOCKS)aip/aipModules.v $(BASICBLOCKS)sequential/upCounter.v $(BASICBLOCKS)sequential/shiftRegister.v $(IPDUMMY_SRC)*.v $(IPCONV_SRC)*.v 	$(IPCONV_SRC)*.sv  testbench_dummy_picosoc_AIP.v native_aip.v ipdummy_picosoc.v picosoc_AIP.v ID0000200F_aip.v simpleuart.v picorv32.v
	#-- Compilar
	$(IVERILOG) -g2005-sv $^ -o $(NAME)_tb.out
	
synth3:testbench_ez.v picorv32.v
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@
synth2: $(MODULES).ys 
	#-- Compilar
	$(IVERILOG) -g2012 -Wall -c $^ -o $(NAME)_tb.out
	
sim:*.out
	#-- Simular
	vvp $(NAME)_tb.out
	
picoSoC_DDS_tb.vvp: testbench_ipcore_AIP.v picorv32.v native_aip.v 
	$(IVERILOG) -v -c $(MODULES).ys -o $@ $^
	chmod -x $@
	
fpga_sections.lds: sections.lds
	$(CROSS)cpp -P -DICEBREAKER -o $@ $^

main_fw.elf: firmware/fpga_sections.lds firmware/start.s firmware/main.c
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -mabi=ilp32 -march=rv32ic -Wl,-Bstatic,-T,firmware/fpga_sections.lds,--strip-debug -ffreestanding -nostdlib -o firmware/main_fw.elf firmware/start.s firmware/main.c

main_fw.hex: main_fw.elf
	$(CROSS)objcopy -O verilog firmware/main_fw.elf firmware/main_fw.hex

main_fw.bin: firmware/main_fw.elf
	$(CROSS)objcopy -O binary firmware/main_fw.elf firmware/main_fw.bin

firmware/altera_out.txt: main_fw.hex firmware/main_fw.hex firmware/hextoMEM.py
	$(PYTHON) firmware/hextoMEM.py $@

runPICO: firmware/altera_out.txt 
	$(PYTHON) firmware/main_IPM_PICORV32.py $@	

        	
# ---- ASIC Synthesis Tests ----

cmos.log: spimemio.v simpleuart.v picosoc.v ../picorv32.v
	yosys -l cmos.log -p 'synth -top picosoc; abc -g cmos2; opt -fast; stat' $^

# ---- Clean ----

clean:
	rm -f testbench.vvp testbench.vcd spiflash_tb.vvp spiflash_tb.vcd
	rm -f irmware/*.hex firmware/*.elf firmware/*.bin firmware/altera_out.txt

.PHONY: spiflash_tb clean
.PHONY: hx8kprog hx8kprog_fw hx8ksim hx8ksynsim
.PHONY: icebprog icebprog_fw icebsim icebsynsim
