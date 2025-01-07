
module packet_gen_axi_tb();

    localparam TDATA_WIDTH = 32,
            TKEEP_WIDTH  = 8/8,
            CLK_PERIOD = 10;

    logic axis_aclk=0;
    logic axis_aresetn=0;
    logic enable=1;

    logic [TDATA_WIDTH-1:0] m_axis_tdata_rate;
    logic [TKEEP_WIDTH-1:0] m_axis_tkeep_rate;
    logic m_axis_tvalid_rate;
    logic m_axis_tlast_rate;
    logic m_axis_tready_rate=1;

    packet_gen_axi dut (.*);

    initial forever #(CLK_PERIOD/2) axis_aclk <= ~axis_aclk;

    initial begin
        @(posedge axis_aclk);
        #(CLK_PERIOD)
        axis_aresetn <= 1'b1;
        enable <= 1'b1;
        m_axis_tready_rate <= 1'b1;

        #(CLK_PERIOD*100);
    end
endmodule