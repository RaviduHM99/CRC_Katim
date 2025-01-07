
module crc_trans_tb();

    localparam DATA_WIDTH = 32,
            CLK_PERIOD = 10;

    logic axis_aclk=0;
    logic axis_aresetn=0;

    logic [DATA_WIDTH - 1:0] data_in = 'd0;
    logic [DATA_WIDTH - 1:0] data_out;

    logic frame_ready;
    logic data_in_valid = 'd0;

    crc_trans dut (.*);

    initial forever #(CLK_PERIOD/2) axis_aclk <= ~axis_aclk;

    initial begin
        @(posedge axis_aclk);
        #(CLK_PERIOD)
        axis_aresetn <= 1'b1;

        data_in_valid <= 1;
        data_in <= 'd5;
        #(CLK_PERIOD)

        data_in_valid <= 1;
        data_in <= 'd3;
        #(CLK_PERIOD)

        data_in_valid <= 1;
        data_in <= 'd678;
        #(CLK_PERIOD)

        data_in_valid <= 1;
        data_in <= 'd76;
        #(CLK_PERIOD)

        data_in_valid <= 1;
        data_in <= 'd89;
        #(CLK_PERIOD*10);
    end
endmodule