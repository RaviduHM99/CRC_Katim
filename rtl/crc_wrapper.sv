module crc_wrapper #(
    parameter DATA_WIDTH = 32
)(
    input logic axis_aclk,
    input logic axis_aresetn,
    input logic enable,

    output logic crc_flag,
    output logic [DATA_WIDTH-1:0] crc_error_count,

    output logic [DATA_WIDTH-1:0] frame_count_out,
    output logic [DATA_WIDTH-1:0] error_count_out,
    output logic frame_error
);

    logic [DATA_WIDTH-1:0] s_axis_tdata;
    logic s_axis_tvalid;
    logic s_axis_tlast;
    logic s_axis_tready;

    logic [DATA_WIDTH-1:0] m_axis_tdata;
    logic m_axis_tvalid;
    logic m_axis_tlast;
    logic m_axis_tready;

    logic [DATA_WIDTH-1:0] m_axis_tdata_checker;
    logic m_axis_tvalid_checker;
    logic m_axis_tlast_checker;
    logic m_axis_tready_checker;

    packet_gen_axi packet_gen (
        .axis_aclk(axis_aclk),
        .axis_aresetn(axis_aresetn),
        .enable(enable),
    
        .m_axis_tdata_rate(s_axis_tdata),
        .m_axis_tkeep_rate(),
        .m_axis_tvalid_rate(s_axis_tvalid),
        .m_axis_tlast_rate(s_axis_tlast),
        .m_axis_tready_rate(s_axis_tready)
    );

    crc_trans_axi crc_trans (
        .axis_aclk(axis_aclk),
        .axis_aresetn(axis_aresetn),
    
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready),
    
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );

    crc_checker_axi crc_checker (
        .axis_aclk(axis_aclk),
        .axis_aresetn(axis_aresetn),
    
        .crc_flag(crc_flag),
        .crc_error_count(crc_error_count),
    
        .s_axis_tdata(m_axis_tdata),
        .s_axis_tvalid(m_axis_tvalid),
        .s_axis_tlast(m_axis_tlast),
        .s_axis_tready(m_axis_tready),
    
        .m_axis_tdata(m_axis_tdata_checker),
        .m_axis_tvalid(m_axis_tvalid_checker),
        .m_axis_tlast(m_axis_tlast_checker),
        .m_axis_tready(m_axis_tready_checker)
    );

    frame_checker_axi frame_checker (
        .axis_aclk(axis_aclk),
        .axis_aresetn(axis_aresetn),
    
        .s_axis_tdata(m_axis_tdata_checker),
        .s_axis_tvalid(m_axis_tvalid_checker),
        .s_axis_tlast(m_axis_tlast_checker),
        .s_axis_tready(m_axis_tready_checker),
    
        .frame_count_out(frame_count_out),
        .error_count_out(error_count_out),
        .frame_error(frame_error)
    );



endmodule