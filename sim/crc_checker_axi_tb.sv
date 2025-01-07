
module crc_checker_axi_tb();

    localparam DATA_WIDTH = 32,
            CLK_PERIOD = 10;

    logic axis_aclk=0;
    logic axis_aresetn=0;

    logic crc_flag;
    logic [DATA_WIDTH-1:0] crc_error_count;

    logic [DATA_WIDTH-1:0] s_axis_tdata;
    logic s_axis_tvalid;
    logic s_axis_tlast;
    logic s_axis_tready;

    logic [DATA_WIDTH-1:0] m_axis_tdata;
    logic m_axis_tvalid;
    logic m_axis_tlast;
    logic m_axis_tready;

    crc_checker_axi dut (.*);

    initial forever #(CLK_PERIOD/2) axis_aclk <= ~axis_aclk;

    initial begin
        @(posedge axis_aclk);
        #(CLK_PERIOD)
        axis_aresetn <= 1'b1;

        s_axis_tdata <= 32'd5;
        s_axis_tvalid <= 1'b1;
        s_axis_tlast <= 1'b0;
        m_axis_tready <= 1'b1;
        #(CLK_PERIOD)

        s_axis_tdata <= 32'd3;
        s_axis_tvalid <= 1'b1;
        s_axis_tlast <= 1'b0;
        #(CLK_PERIOD)

        s_axis_tdata <= 32'd678;
        s_axis_tvalid <= 1'b1;
        s_axis_tlast <= 1'b0;
        #(CLK_PERIOD)
        s_axis_tdata <= 32'd76;
        s_axis_tvalid <= 1'b1;
        s_axis_tlast <= 1'b0;
        #(CLK_PERIOD)
        s_axis_tdata <= 32'd89;
        s_axis_tvalid <= 1'b1;
        s_axis_tlast <= 1'b0;
        #(CLK_PERIOD)
        s_axis_tdata <= 32'h06b9a027;
        s_axis_tvalid <= 1'b1;
        s_axis_tlast <= 1'b1;
        #(CLK_PERIOD)
        s_axis_tlast <= 1'b0;
        #(CLK_PERIOD*10);
    end
endmodule