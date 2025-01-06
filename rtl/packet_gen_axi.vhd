
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity packet_gen_axi is
    generic (
    TDATA_WIDTH : integer := 32;
    TKEEP_WIDTH : integer := 8/8;
    TUSER_WDITH : integer := 8
    );
    port (
    axis_aclk : in std_logic;
    axis_aresetn : in std_logic;
    enable : in std_logic;

    m_axis_tdata_rate : out std_logic_vector(TDATA_WIDTH - 1 downto 0);
    m_axis_tkeep_rate : out std_logic_vector(TKEEP_WIDTH - 1 downto 0);
    m_axis_tvalid_rate : out std_logic;
    m_axis_tlast_rate : out std_logic;
    m_axis_tready_rate : in std_logic
    );
end packet_gen_axi;

architecture rtl of packet_gen_axi is
    type t_hdr is array(0 to 16) of std_logic_vector(TDATA_WIDTH - 1 downto 0);
    signal hdr : t_hdr;
    signal byte_count : std_logic_vector(31 downto 0);
    constant byte_count_max : natural := 124;
    constant data_rate: natural := 57;
    signal tx_enable : std_logic;

    signal m_axis_tdata : std_logic_vector(TDATA_WIDTH - 1 downto 0);
    signal m_axis_tkeep :std_logic_vector(TKEEP_WIDTH - 1 downto 0);
    signal m_axis_tvalid : std_logic;
    signal m_axis_tlast : std_logic;
    signal m_axis_tready : std_logic;
    signal rate_count: integer;

    signal m_axis_tlast_edge : std_logic;
    signal m_axis_tvalid_edge : std_logic;
    begin

    hdr <= (0 => x"FFFFFFFF",
    1 => x"00000001",
    2 => x"000001B0",
    3 => x"00000009",
    4 => x"00001200",
    5 => x"00000080",
    6 => x"00000000",
    7 => x"00000000",
    8 => x"00000001",
    9 => x"00000000",
    10 => x"00000000",
    11 => x"00000003",
    12 => x"00000000",
    13 => x"11B002F4",
    14 => x"000B0003",
    15 => x"0183017F",
    16 => x"A254_FCDE");


    data_rate_proc: process(axis_aclk)
    begin
        if rising_edge(axis_aclk) then
            if axis_aresetn = '0' then
                rate_count <= 0;
                m_axis_tdata_rate <= (others => '0');
                m_axis_tkeep_rate <= (others => '0');
                m_axis_tvalid_rate <= '0';
                m_axis_tlast_edge <= '0';
                m_axis_tlast_rate <= '0';
            else
                if (rate_count < data_rate) then
                    if (m_axis_tready_rate = '1') then
                        rate_count <= rate_count + 1;
                        m_axis_tlast_rate <= '0';
                        m_axis_tvalid_rate <= '0';
                    end if;
                elsif (rate_count = data_rate) then 
                    rate_count <= 0; 
                    m_axis_tlast_rate <= m_axis_tlast_edge;
                    m_axis_tvalid_rate <= m_axis_tvalid_edge;
                else
                    m_axis_tlast_rate <= '0';
                    m_axis_tvalid_rate <= '0';
                end if;

                if (rate_count = 0) then 
                    m_axis_tready <= m_axis_tready_rate;
                    m_axis_tdata_rate <= m_axis_tdata;
                    m_axis_tkeep_rate <= m_axis_tkeep;
                    m_axis_tvalid_edge <= m_axis_tvalid;
                    m_axis_tlast_edge <= m_axis_tlast;
                else 
                    m_axis_tready <= '0';
                end if;
            end if;
         end if;
    end process;

    reg_proc: process(axis_aclk)
    begin
        if rising_edge(axis_aclk) then
            if axis_aresetn = '0' then
                byte_count <= (others => '0');
                tx_enable <= '0';
            else
            -- latch the enable input
                if enable = '1' then 
                    tx_enable <= '1';
                end if;
                if tx_enable = '1' then
                    if m_axis_tready = '1' then
                        if unsigned(byte_count) < to_unsigned(byte_count_max-1, byte_count'length) then
                            byte_count <= std_logic_vector(unsigned(byte_count) + 1);
                        else
                            -- only stop transmitting, if disabled, after completing a frame
                            tx_enable <= enable;
                            byte_count <= (others => '0');
                        end if;
                    end if;
                end if;
            end if;
         end if;
    end process;

    arb_proc: process(tx_enable, byte_count, hdr, m_axis_tready, tx_enable)
    begin
        if tx_enable = '1' then
            if unsigned(byte_count) <= to_unsigned(hdr'length-1, byte_count'length) then
                m_axis_tdata <= hdr(to_integer(unsigned(byte_count)));
            else
                m_axis_tdata <= byte_count(TDATA_WIDTH - 1 downto 0);
            end if;

            if unsigned(byte_count) = to_unsigned(byte_count_max-1, byte_count'length) then
                m_axis_tlast <= '1';
            else
                m_axis_tlast <= '0';
            end if;

            m_axis_tvalid <= tx_enable;

            if tx_enable = '1' then
                m_axis_tkeep <= "1";
            else
                m_axis_tkeep <= "0";
            end if;

        else
            m_axis_tdata <= (others => '0');
            m_axis_tkeep <= (others => '0');
            m_axis_tvalid <= '0';
            m_axis_tlast <= '0';
        end if;
    end process;

end rtl;
