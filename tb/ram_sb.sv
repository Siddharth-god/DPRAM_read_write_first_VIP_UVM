//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SB xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------------------------------- SB -----------------------------------------------------
class ram_sb extends uvm_scoreboard;
    `uvm_component_utils(ram_sb)
    `NEW_COMP

    uvm_tlm_analysis_fifo #(ram_rd_xtn) fifo_rd; 
    uvm_tlm_analysis_fifo #(ram_wr_xtn) fifo_wr; 

    ram_wr_xtn wr_xtn; 
    ram_rd_xtn rd_xtn; 

    static int match_counter = 0; 
    static int mismatch_counter = 0; 

    reg [WIDTH-1:0] exp_data [int]; // Associative array for higher protection


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        fifo_rd = new("fifo_rd",this);
        fifo_wr = new("fifo_wr",this); 
    endfunction 

    task run_phase(uvm_phase phase); 
        $display("!!! SCOREBOARD VERSION 2.0 RUNNING !!!");
        fork
            forever begin
                // Thread 1: Monitor Writes and update Reference Model
                fifo_wr.get(wr_xtn); 

                $display("\nData in fifo from WR MON :\n rst=%0d | we=%0d | wd_adr=%0d | din=%0d",
                    wr_xtn.rst,
                    wr_xtn.we,
                    wr_xtn.wr_adr,
                    wr_xtn.din
                );

                if(wr_xtn.we) begin 
                    exp_data[wr_xtn.wr_adr] = wr_xtn.din;

                     $display("Exp data = %p",exp_data);
                end
            end
            forever begin
                // Thread 2: Monitor Reads and Compare
                bit [WIDTH-1:0] exp_out; 
                fifo_rd.get(rd_xtn); 

                $display("\nData in fifo from RD MON :\n re=%0d | rd_adr=%0d | dout=%0d\n",
                        rd_xtn.re,
                        rd_xtn.rd_adr,
                        rd_xtn.dout
                    );
                    
                if(rd_xtn.re) begin // Begin only if valid read 
                    if(exp_data.exists(rd_xtn.rd_adr)) begin // Compare only if valid address to read from
                        exp_out = exp_data[rd_xtn.rd_adr]; // Getting expected form the local array
                        $display("Exp out = %0d",exp_out);

                        if(exp_out == rd_xtn.dout) begin 
                            `uvm_info(
                                get_type_name(),
                                $sformatf("\n\nScoreboard : [Data Match Successful]\n[dout : exp_out] = [%0d:%0d]",rd_xtn.dout,exp_out),
                                UVM_LOW)
                            match_counter++; 
                            $display("\ndata match : [%0d]\n",match_counter);
                        end
                        else begin
                            `uvm_error(
                                get_type_name(),
                                $sformatf("\n\nScoreboard : [Data Mismatch]\n[dout : exp_out] = [%0d:%0d]",rd_xtn.dout,exp_out))
                            mismatch_counter++; 
                            $display("\ndata mismatch : [%0d]\n",mismatch_counter);
                        end
                    end
                    else 
                        `uvm_warning(get_type_name(),$sformatf("Read from empty addr: %0d", rd_xtn.rd_adr))
                end
            end
        join
    endtask 

endclass 
