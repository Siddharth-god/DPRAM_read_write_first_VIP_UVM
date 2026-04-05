
// TOP------------------------------------------------
module ram_top;

    import ram_pkg::*;
    import uvm_pkg::*;
    bit clk = 0;
    always #5 clk = ~clk; 

    dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) IF(clk);

    ram #(.WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .ADDR_BUS(ADDR_BUS),
        .MODE(1) // Write first mode 
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
        run_test();
    end
endmodule 