
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TEST xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------------------------------- TEST -----------------------------------------------------

class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)
    `NEW_COMP

    ram_env ram_envh; 

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

                if(!uvm_config_db #(virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)))::get(this,"",$sformatf("vif[%0d]",i),wr_cfg[i].wvif))
                    `uvm_fatal(get_type_name(),$sformatf("Failed to get vif[%0d] in TEST WR_AGT_CFG from TOP",i))

                wr_cfg[i].is_active = UVM_ACTIVE;
                env_cfg.wr_cfg[i] = wr_cfg[i];
            end
        end

        if(has_rd_agent) begin 
                rd_cfg = new[no_of_duts];
                foreach(rd_cfg[i]) begin 
                    rd_cfg[i] = ram_rd_agent_config::type_id::create($sformatf("rd_cfg[%0d]",i));

                    if(!uvm_config_db #(virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)))::get(this,"",$sformatf("vif[%0d]",i),rd_cfg[i].rvif))
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

        ram_envh = ram_env::type_id::create("ram_envh",this);
    endfunction 

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction 

endclass 

//------------------------------------ SINGLE ADDR TEST --------------------------------------
class ram_test1 extends ram_test;
    `uvm_component_utils(ram_test1)
    `NEW_COMP

    seq_rst seq_rst_h; 
    seq_wr_single_addr seq_wr_single_addr_h; 
    seq_rd_single_addr seq_rd_single_addr_h; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        seq_rst_h = seq_rst::type_id::create("seq_rst_h");
        seq_wr_single_addr_h = seq_wr_single_addr::type_id::create("seq_wr_single_addr_h");
        seq_rd_single_addr_h = seq_rd_single_addr::type_id::create("seq_rd_single_addr_h");

        phase.raise_objection(this);
        // write seq
        seq_rst_h.start(ram_envh.ram_wr_agt_toph[0].ram_wr_agth.ram_wr_seqrh);
        seq_wr_single_addr_h.start(ram_envh.ram_wr_agt_toph[0].ram_wr_agth.ram_wr_seqrh);
        // read seq 
        seq_rd_single_addr_h.start(ram_envh.ram_rd_agt_toph[0].ram_rd_agth.ram_rd_seqrh);
        #50;
        phase.drop_objection(this);
    endtask 
endclass 


//------------------------------------ BURST TEST --------------------------------------
class ram_test2 extends ram_test;
    `uvm_component_utils(ram_test2)
    `NEW_COMP

    seq_rst seq_rst_h; 
    seq_wr_burst seq_wr_burst_h; 
    seq_rd_burst seq_rd_burst_h; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        //seq_rst_h = seq_rst::type_id::create("seq_rst_h");
        seq_wr_burst_h = seq_wr_burst::type_id::create("seq_wr_burst_h");
        seq_rd_burst_h = seq_rd_burst::type_id::create("seq_rd_burst_h");

        phase.raise_objection(this);
        // write seq
        // seq_rst_h.start(ram_envh.ram_wr_agt_toph[0].ram_wr_agth.ram_wr_seqrh);
        seq_wr_burst_h.start(ram_envh.ram_wr_agt_toph[0].ram_wr_agth.ram_wr_seqrh);
        // read seq 
        seq_rd_burst_h.start(ram_envh.ram_rd_agt_toph[0].ram_rd_agth.ram_rd_seqrh);
        #50;
        phase.drop_objection(this);
    endtask 
endclass 

