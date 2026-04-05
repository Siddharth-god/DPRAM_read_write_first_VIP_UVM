package ram_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter WIDTH = 8;
    parameter DEPTH = 16;
    parameter ADDR_BUS = 4;
endpackage

import uvm_pkg::*;
`include "uvm_macros.svh"
import ram_pkg::*;

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx RTL xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
module ram #(
    WIDTH,
    DEPTH,
    ADDR_BUS,

    // Behavior selection (future use)
    parameter MODE = 0   // 0 = READ_FIRST, 1 = WRITE_FIRST
)(
    input clk,
    input rst,

    // Write port
    input we,
    input [ADDR_BUS-1:0] wr_adr,
    input [WIDTH-1:0] din,

    // Read port
    input re,
    input [ADDR_BUS-1:0] rd_adr,
    output reg [WIDTH-1:0] dout
);

localparam READ_FIRST  = 0;
localparam WRITE_FIRST = 1;

reg [WIDTH-1:0] mem [0:DEPTH-1];
integer i;

always @(posedge clk) begin
    if (rst) begin
        dout <= 0;
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] <= 0;   // simulation friendly
    end 
    else begin

        // -------------------------
        // SAME ADDRESS COLLISION
        // -------------------------
        if (we && re && (wr_adr == rd_adr)) begin
            if (MODE == WRITE_FIRST)
                dout <= din;           // future behavior
            else
                dout <= mem[rd_adr];   // current behavior (READ_FIRST)

            mem[wr_adr] <= din;
        end

        // -------------------------
        // NORMAL OPERATIONS
        // -------------------------
        else begin
            if (we)
                mem[wr_adr] <= din;

            if (re)
                dout <= mem[rd_adr];
        end
    end
end

endmodule

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx INTERACE xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

interface dpram_if #(WIDTH,
					ADDR_BUS)(input bit clk);

	logic rst; 
	logic we;
	logic re;
	logic [ADDR_BUS-1:0] wr_adr;
	logic [ADDR_BUS-1:0] rd_adr;
	logic [WIDTH-1:0] din;
	logic [WIDTH-1:0]dout;

	clocking wr_drv_cb@(posedge clk);
		output rst; 
		output we;
		output wr_adr;
		output din;
	endclocking

	clocking wr_mon_cb@(posedge clk);
		input rst; 
		input we;
		input wr_adr;
		input din;
	endclocking

	clocking rd_drv_cb@(posedge clk);
		input rst; //! Only be observed so input. 
		output re;
		output rd_adr;
		input dout;
	endclocking

	clocking rd_mon_cb@(posedge clk);
		input rst; 
		input re;
		input rd_adr;
		input dout;
	endclocking

	modport WR_DRV_MD(clocking wr_drv_cb);
	modport WR_MON_MD(clocking wr_drv_cb);
	modport RD_MON_MD(clocking wr_drv_cb);
	modport RD_DRV_MD(clocking wr_drv_cb);

endinterface 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx UVM xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------DEFAULT MACROS--------------------------------
    //****NEW COMPONENT****//
    `define NEW_COMP    \
        function new(string name ="", uvm_component parent);    \
            super.new(name,parent);    \
        endfunction

    //****NEW OBJECT****//
    `define NEW_OBJ    \
        function new(string name ="");    \
            super.new(name);    \
        endfunction
//------------------------------------------------------------------------------

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TRANSACTIONS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

// WRITE XTN 
class ram_wr_xtn extends uvm_sequence_item;
    `uvm_object_utils(ram_wr_xtn)
    `NEW_OBJ

    logic rst; 
	rand bit we;
	rand bit [ADDR_BUS-1:0] wr_adr;
	rand bit [WIDTH-1:0] din;

    function void do_print(uvm_printer printer);
        printer.print_field("we",we,1,UVM_DEC);
        printer.print_field("wr_adr",wr_adr,4,UVM_DEC);
        printer.print_field("din",din,8,UVM_DEC);
    endfunction 
endclass 


// READ XTN
class ram_rd_xtn extends uvm_sequence_item;
    `uvm_object_utils(ram_rd_xtn)
    `NEW_OBJ

	logic re;
	rand bit [ADDR_BUS-1:0] rd_adr;
	rand bit [WIDTH-1:0] dout;

    function void do_print(uvm_printer printer);
        printer.print_field("re",re,1,UVM_DEC);
        printer.print_field("rd_adr",rd_adr,4,UVM_DEC);
        printer.print_field("dout",dout,8,UVM_DEC);
    endfunction 
endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx CONFIG xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

// READ CONFIG
class ram_wr_agent_config extends uvm_object;
    `uvm_object_utils(ram_wr_agent_config)
    `NEW_OBJ

    virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) vif; 
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    // static int drv_data_xtn_count = 0;
    // static int mon_data_xtn_count = 0; 
endclass 

// WRITE CONFIG
class ram_rd_agent_config extends uvm_object;
    `uvm_object_utils(ram_rd_agent_config)
    `NEW_OBJ

    virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) vif; 
    uvm_active_passive_enum is_active = UVM_ACTIVE;
endclass 

// ENV CONFIG
class ram_env_config extends uvm_object;
    `uvm_object_utils(ram_env_config)
    `NEW_OBJ

    // ENV CONFIG DOES NOT HAVE => uvm_active_passive_enum & vif (only in low lvl cfg)

    int has_rd_agent = 1; // Values by default
    int has_wr_agent = 1; 
    int has_sb = 1; 
    int no_of_duts = 1;
    int has_functional_cov = 0;

    ram_wr_agent_config wr_cfg[]; // every low lvl agent will have it's own config.
    ram_rd_agent_config rd_cfg[];

endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SEQUENCES xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

// WRITE SEQS 
class ram_wr_seq extends uvm_sequence #(ram_wr_xtn);
    `uvm_object_utils(ram_wr_seq)
    `NEW_OBJ
endclass 

// READ SEQ 
class ram_rd_seq extends uvm_sequence #(ram_rd_xtn);
    `uvm_object_utils(ram_rd_seq)
    `NEW_OBJ
endclass 

// WRITE SEQR
class ram_wr_seqr extends uvm_sequencer #(ram_wr_xtn);
    `uvm_component_utils(ram_wr_seqr)
    `NEW_COMP
endclass 


// READ SEQR
class ram_rd_seqr extends uvm_sequencer #(ram_rd_xtn);
    `uvm_component_utils(ram_rd_seqr)
    `NEW_COMP
endclass 


// WRITE DRV 
class ram_wr_drv extends uvm_driver #(ram_wr_xtn);
    `uvm_component_utils(ram_wr_drv)
    `NEW_COMP

    virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) vif;
    ram_wr_agent_config wr_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(ram_wr_agent_config)::get(this,"","ram_wr_agent_config",wr_cfg))
            `uvm_fatal(get_type_name(),"Failed to get wr_cfg in [WR_DRV] from ENV")

    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = wr_cfg.vif;
    endfunction

endclass 


// READ DRV
class ram_rd_drv extends uvm_driver #(ram_rd_xtn);
    `uvm_component_utils(ram_rd_drv)
    `NEW_COMP

    virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) vif;
    ram_rd_agent_config rd_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(ram_rd_agent_config)::get(this,"","ram_rd_agent_config",rd_cfg))
            `uvm_fatal(get_type_name(),"Failed to get rd_cfg in [RD_DRV] from ENV")

    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = rd_cfg.vif;
    endfunction
endclass 


// WRITE MON
class ram_wr_mon extends uvm_monitor;
    `uvm_component_utils(ram_wr_mon)
    `NEW_COMP

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

    endfunction 

endclass 


// READ MON 
class ram_rd_mon extends uvm_monitor;
    `uvm_component_utils(ram_rd_mon)
    `NEW_COMP

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

    endfunction 

endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx AGENTS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------------------------------- WRITE_AGT -------------------------------------------------
class ram_wr_agt extends uvm_agent;
    `uvm_component_utils(ram_wr_agt)
    `NEW_COMP

    ram_wr_drv ram_wr_drvh;
    ram_wr_seqr ram_wr_seqrh;
    ram_wr_mon ram_wr_monh; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ram_wr_drvh = ram_wr_drv::type_id::create("ram_wr_drvh",this);
        ram_wr_seqrh = ram_wr_seqr::type_id::create("ram_wr_seqrh",this);
        ram_wr_monh = ram_wr_mon::type_id::create("ram_wr_monh",this);
    endfunction 

    function void connect_phase(uvm_phase phase);
        ram_wr_drvh.seq_item_port.connect(ram_wr_seqrh.seq_item_export);
    endfunction

endclass 



//------------------------------------------------------- READ_AGT -------------------------------------------------

class ram_rd_agt extends uvm_agent;
    `uvm_component_utils(ram_rd_agt)
    `NEW_COMP

    ram_rd_drv ram_rd_drvh;
    ram_rd_seqr ram_rd_seqrh;
    ram_rd_mon ram_rd_monh; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ram_rd_drvh = ram_rd_drv::type_id::create("rd_drvh",this);
        ram_rd_seqrh = ram_rd_seqr::type_id::create("ram_rd_seqrh",this);
        ram_rd_monh = ram_rd_mon::type_id::create("ram_rd_monh",this);
    endfunction 

    function void connect_phase(uvm_phase phase);
        ram_rd_drvh.seq_item_port.connect(ram_rd_seqrh.seq_item_export);
    endfunction

endclass 



//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TOP_AGENTS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------------------------------- WRITE_AGT_TOP -------------------------------------------------
class ram_wr_agt_top extends uvm_agent;
    `uvm_component_utils(ram_wr_agt_top)
    `NEW_COMP

    ram_wr_agt ram_wr_agth; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ram_wr_agth = ram_wr_agt::type_id::create("ram_wr_agth",this);
    endfunction 


endclass 

//------------------------------------------------------- READ_AGT_TOP -----------------------------------------------------
class ram_rd_agt_top extends uvm_agent;
    `uvm_component_utils(ram_rd_agt_top)
    `NEW_COMP

    ram_rd_agt ram_rd_agth; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ram_rd_agth = ram_rd_agt::type_id::create("ram_rd_agth",this);
    endfunction 


endclass 


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SB xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------------------------------- SB -----------------------------------------------------
class ram_sb extends uvm_scoreboard;
    `uvm_component_utils(ram_sb)
    `NEW_COMP

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

    endfunction 

    // function void exp_out/s

endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ENV xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------------------------------- ENV -----------------------------------------------------
class ram_env extends uvm_env;
    `uvm_component_utils(ram_env)
    `NEW_COMP

    ram_rd_agt_top ram_rd_agt_toph[];
    ram_wr_agt_top ram_wr_agt_toph[];
    ram_sb ram_sbh[]; // Each agent top will have different sb for comparision.  

    ram_env_config env_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get the config 
        if(!uvm_config_db #(ram_env_config)::get(this,"","ram_env_config",env_cfg))
            `uvm_fatal(get_type_name(),"Failed to get env_cfg into ENV from TEST")


        // Create Write agents ---------------------
        if(env_cfg.has_wr_agent) begin 
            ram_wr_agt_toph = new[env_cfg.no_of_duts];

            foreach(ram_wr_agt_toph[i]) begin 
                ram_wr_agt_toph[i] = ram_wr_agt_top::type_id::create($sformatf("ram_wr_agt_toph[%0d]",i),this);
                // Till now we haven't set agent_configs which holds is active and vif to low lvl components (here we do that)
                // we use $sformatf(%0d,i) ==> While only getting ==> While setting we can directly set with [i]
                
                uvm_config_db #(ram_wr_agent_config)::set(this,"*","ram_wr_agent_config",env_cfg.wr_cfg[i]);
            end
        end


        // Create Read agents ---------------------
        if(env_cfg.has_rd_agent) begin 
            ram_rd_agt_toph = new[env_cfg.no_of_duts];

            foreach(ram_rd_agt_toph[i]) begin 
                ram_rd_agt_toph[i] = ram_rd_agt_top::type_id::create($sformatf("ram_rd_agt_toph[%0d]",i),this);
                // Till now we haven't set agent_configs which holds is active and vif to low lvl components (here we do that)

                uvm_config_db #(ram_rd_agent_config)::set(this,"*","ram_rd_agent_config",env_cfg.rd_cfg[i]);
            end
        end

        // Create Virtual Seqr ----------------------
        //...

        // Create Scoreboards -----------------------
        if(env_cfg.has_sb) begin 
            ram_sbh = new[env_cfg.no_of_duts];

            foreach(ram_sbh[i])
                ram_sbh[i] = ram_sb::type_id::create($sformatf("ram_sbh[%0d]",i),this);
        end
    endfunction 

    function void connect_phase(uvm_phase phase);

        // Connect Virtual Seqr to seqrs of agents 
        //...

        // Connect the monitor with SB
        // if(env_cfg.has_sb) begin 
            // foreach(ram_wr_agt_toph[i])
            //     ram_wr_agt_toph[i].wr_agenth.wr_monh.mon_port.connect(ram_sbh[i].fifo_wr_analysis_export);
        // end
    endfunction 
endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TEST xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------------------------------- TEST -----------------------------------------------------

class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)
    `NEW_COMP

    ram_env ram_envh; 
    ram_wr_seq ram_wr_seqh;
    ram_rd_seq ram_rd_seqh;

    int has_rd_agent = 1; 
    int has_wr_agent = 1; 
    // int has_sb = 1;  ===> SB is created in ENV
    int no_of_duts = 1;

    ram_wr_agent_config wr_cfg[]; // every top agent will have it's own config. / We can also have multiple agents inside one agent top, but that approach is harder to debug and not scalable. (That works fine only when many agents have almost same behaviour)
    ram_rd_agent_config rd_cfg[];

    ram_env_config env_cfg;

    function void create_config();
        if(has_wr_agent) begin 
            wr_cfg = new[no_of_duts];
            foreach(wr_cfg[i]) begin
                wr_cfg[i] = ram_wr_agent_config::type_id::create($sformatf("wr_cfg[%0d]",i));

                if(!uvm_config_db #(virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)))::get(this,"",$sformatf("vif[%0d]",i),wr_cfg[i].vif))
                    `uvm_fatal(get_type_name(),$sformatf("Failed to get vif[%0d] in TEST WR_AGT_CFG from TOP",i))

                wr_cfg[i].is_active = UVM_ACTIVE;
                env_cfg.wr_cfg[i] = wr_cfg[i];
            end
        end

        if(has_rd_agent) begin 
                rd_cfg = new[no_of_duts];
                foreach(rd_cfg[i]) begin 
                    rd_cfg[i] = ram_rd_agent_config::type_id::create($sformatf("rd_cfg[%0d]",i));

                    if(!uvm_config_db #(virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)))::get(this,"",$sformatf("vif[%0d]",i),rd_cfg[i].vif))
                        `uvm_fatal(get_type_name(),$sformatf("Failed to get vif[%0d] in TEST RD_AGT_CFG from TOP",i))

                    rd_cfg[i].is_active = UVM_ACTIVE;
                    env_cfg.rd_cfg[i] = rd_cfg[i];
                end
            end

        env_cfg.no_of_duts = no_of_duts;
        env_cfg.has_rd_agent = has_rd_agent;
        env_cfg.has_wr_agent = has_wr_agent; 
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_cfg = ram_env_config::type_id::create("env_cfg");

        if(has_wr_agent)  
            env_cfg.wr_cfg = new[no_of_duts]; 
/*
        //! Assigning size for the cfg inside env_config, coz ENVIRONMENT CLASS uses env_config (while in text create_config() function has temporary size assignment just to create objects in test and then pass vif to them.)
*/
        if(has_rd_agent)  
            env_cfg.rd_cfg = new[no_of_duts]; 

        create_config();

        uvm_config_db #(ram_env_config)::set(this,"*","ram_env_config",env_cfg);

        ram_wr_seqh = ram_wr_seq::type_id::create("ram_wr_seqh");
        ram_rd_seqh  = ram_rd_seq::type_id::create("ram_rd_seqh");
        ram_envh = ram_env::type_id::create("ram_envh",this);
    endfunction 

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction 

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        // ---
        phase.drop_objection(this);
    endtask 
endclass 

// TOP------------------------------------------------
module dpram;

    import ram_pkg::*;
    import uvm_pkg::*;
    bit clk = 0;
    always #5 clk = ~clk; 

    dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) IF(clk);

    ram #(.WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .ADDR_BUS(ADDR_BUS)
        )DUT(
            .clk(clk),
            .rst(IF.rst),
            .din(IF.din),
            .dout(IF.dout),
            .wr_adr(IF.wr_adr),
            .rd_adr(IF.rd_adr),
            .we(IF.we),
            .re(IF.re)
        );
    
    initial begin 
        uvm_config_db #(virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)))::set(null,"*","vif[0]",IF);
        run_test("ram_test");
    end
endmodule 