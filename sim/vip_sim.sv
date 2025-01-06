`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/06/2025 09:04:28 AM
// Design Name: 
// Module Name: vip_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import axi4stream_vip_pkg::*;
import design_1_axi4stream_vip_0_0_pkg::*;
import design_1_axi4stream_vip_0_1_pkg::*;
import design_1_axi4stream_vip_0_2_pkg::*;

module vip_sim();
    axi4stream_transaction wr_transaction;
    axi4stream_ready_gen ready_gen;

    design_1_axi4stream_vip_0_0_mst_t mst_agent;
    design_1_axi4stream_vip_0_1_slv_t slv_agent;
    design_1_axi4stream_vip_0_2_passthrough_t passthrough_agent;

    localparam CLK_PERIOD = 10;
    logic aclk_0 = 0, aresetn_0 = 0;

    design_1_wrapper dut (.*);

    initial forever #(CLK_PERIOD/2) aclk_0 <= ~aclk_0;
    
    initial begin
        @(posedge aclk_0);
        #(CLK_PERIOD)
        aresetn_0 <= 1;

        
    end

    initial begin
        mst_agent = new("master vip agent", dut.design_1_i.axi4stream_vip_0.inst.IF);
        slv_agent = new("slave vip agent", dut.design_1_i.axi4stream_vip_1.inst.IF);
        passthrough_agent = new("passthrough vip agent", dut.design_1_i.axi4stream_vip_2.inst.IF);
        dut.design_1_i.axi4stream_vip_2.inst.set_passthrough_mode();
    
        mst_agent.start_master();
        slv_agent.start_slave();
        passthrough_agent.start_monitor();

        wait (aresetn_0 == 1'b1);

        wr_transaction = mst_agent.driver.create_transaction("write transaction");
        WR_TRANSACTION_FAIL: assert(wr_transaction.randomize());
        mst_agent.driver.send(wr_transaction);

        #(CLK_PERIOD*20);
        $display("========== end ==========");
        #(CLK_PERIOD*20);
        $finish;
    end

endmodule
