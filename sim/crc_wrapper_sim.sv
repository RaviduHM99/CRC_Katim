
module crc_wrapper_tb();

    localparam DATA_WIDTH = 32,
            CLK_PERIOD = 10;

    logic axis_aclk=0;
    logic axis_aresetn=0;
    logic enable;

    logic crc_flag;
    logic [DATA_WIDTH-1:0] crc_error_count;

    logic [DATA_WIDTH-1:0] frame_count_out;
    logic [DATA_WIDTH-1:0] error_count_out;
    logic frame_error;

    crc_wrapper dut (.*);

    initial forever #(CLK_PERIOD/2) axis_aclk <= ~axis_aclk;

    initial begin
        @(posedge axis_aclk);
        #(CLK_PERIOD)
        axis_aresetn <= 1'b1;
        enable <= 1'b1;
    end
endmodule