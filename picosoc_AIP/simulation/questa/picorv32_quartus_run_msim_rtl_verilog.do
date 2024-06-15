transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/mods/basicblocks/ipm {/home/luis/Documents/picorv32_InterfaceAIP_quartus/mods/basicblocks/ipm/ipm.v}
vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/mods/basicblocks/ipm {/home/luis/Documents/picorv32_InterfaceAIP_quartus/mods/basicblocks/ipm/ipm_register.v}
vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc {/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc/ID0000200F_aip.v}
vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc {/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc/simpleuart.v}
vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/mods/basicblocks/memories {/home/luis/Documents/picorv32_InterfaceAIP_quartus/mods/basicblocks/memories/simple_dual_port_ram_single_clk.v}
vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/mods/basicblocks/aip {/home/luis/Documents/picorv32_InterfaceAIP_quartus/mods/basicblocks/aip/aipModules.v}
vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc {/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc/DE1SOC_picosoc.v}
vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc {/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc/picosoc_AIP.v}
vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc {/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc/picorv32m.v}

vlog -vlog01compat -work work +incdir+/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc_AIP/../picosoc {/home/luis/Documents/picorv32_InterfaceAIP_quartus/picosoc_AIP/../picosoc/testbench_DE1SOC_picosoc.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  testbench_DE1SOC_picosoc

add wave *
view structure
view signals
run -all
