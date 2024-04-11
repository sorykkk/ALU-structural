export TEST_NAME = row_syn_tb
FILE_LIST = files.f


PLATFORM = LINUX64
waveform = waves.fsdb
 
vcs_all: clean vcs_compile vcs_simulate
vcs_compile:
	vcs -notice -debug_acc+all -j8 -timescale=1ns/1ps \
        -sverilog -LDFLAGS -rdynamic -full64 \
        -P $(VERDI_HOME)/share/PLI/VCS/$(PLATFORM)/novas.tab \
           $(VERDI_HOME)/share/PLI/VCS/$(PLATFORM)/pli.a \
        -f $(FILE_LIST) \
        +vcs+lic+wait \
        -l vcs_com.log
        
vcs_simulate:
	./simv \
    +fsdb+autoflush \
    -l vcs_sim.log \
    +mda+packedmda+struct \
    -ucli -do vcs.tcl 

#if it is needed only to view wates then use:
#	nWaves waves.fsdb & 
#	then press g (to get waves)
#
run_verdi:
	verdi -nologo -sv -f $(FILE_LIST) -ssf waves.fsdb &


clean:
	@rm -rf csrc DVEfiles simv simv.daidir ucli.key novas* VCS* *dat
