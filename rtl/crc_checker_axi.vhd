
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc_checker_axi is
    generic (
    PAYLOAD_WIDTH : integer := 124; ---- FRAME WIDTH = PAYLOAD WIDTH + CRC VAL
    DATA_WIDTH : integer := 32;
    CRC_WIDTH : integer := 32;
    CRC_POLY : std_logic_vector := x"04C1_1DB7"
    );
    port (
    axis_aclk : in std_logic;
    axis_aresetn : in std_logic;

    crc_flag : out std_logic;
    crc_error_count: out std_logic_vector(DATA_WIDTH - 1 downto 0);

    s_axis_tdata : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    s_axis_tvalid : in std_logic;
    s_axis_tlast : in std_logic;
    s_axis_tready : out std_logic;

    m_axis_tdata : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tlast : out std_logic;
    m_axis_tready : in std_logic
    );
end crc_checker_axi;

architecture rtl of crc_checker_axi is

    signal crc_reg: std_logic_vector(CRC_WIDTH - 1 downto 0);
    signal word_counter: integer range 0 to 500;
    
    function crc_calc (word_counter : in integer range 0 to 500; data_in : in std_logic_vector(DATA_WIDTH - 1 downto 0); crc_reg : in std_logic_vector(CRC_WIDTH - 1 downto 0)) return std_logic_vector is 
        variable crc_val : std_logic_vector(CRC_WIDTH - 1 downto 0) := (others => '0');
        variable crc_temp: std_logic_vector(CRC_WIDTH - 1 downto 0) := (others => '0');
        variable i : integer;

        constant loop_var : integer := CRC_WIDTH;
        constant crc_initial : std_logic_vector (CRC_WIDTH - 1 downto 0) := x"0000_0000";
        
        begin
            if (word_counter = 0) then
                crc_temp := crc_initial xor data_in;
            else
                crc_temp := crc_reg;
            end if;

            for i in 0 to loop_var-1 loop
                if (crc_temp(CRC_WIDTH-1) = '1') then
                    crc_temp := (crc_temp sll 1) xor CRC_POLY;
                else
                    crc_temp := crc_temp sll 1;
                end if;
            end loop;
            crc_val := crc_temp;
            return crc_val;
    end function crc_calc;
    
    begin

    process (axis_aclk)
    begin
        if rising_edge(axis_aclk) then
            if (axis_aresetn = '0') then
                word_counter <= 0;
            else
                if (s_axis_tlast = '1') then
                    word_counter <= 0;
                else  
                    if (s_axis_tvalid = '1' and m_axis_tready = '1') then
                        word_counter <= word_counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (axis_aclk)
    begin
        if rising_edge(axis_aclk) then
            if (axis_aresetn = '0') then
                crc_reg <= (others => '0');
            else
                if (s_axis_tlast = '1') then
                    crc_reg <= (others => '0');
                else
                    if (s_axis_tvalid = '1' and m_axis_tready = '1') then
                        crc_reg <= crc_calc(word_counter, s_axis_tdata, crc_reg);
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (axis_aclk)
    begin
        if rising_edge(axis_aclk) then
            if (axis_aresetn = '0') then
                m_axis_tdata <= (others => '0');
                m_axis_tvalid <= '0';
                crc_flag <= '0';
            else
                if (s_axis_tlast = '1') then
                    m_axis_tdata <= (others => '0');
                    m_axis_tvalid <= '0';
                    if (crc_reg /= s_axis_tdata) then
                        crc_flag <= '1';
                    else 
                        crc_flag <= '0';
                    end if;
                else
                    if (s_axis_tvalid = '1' and m_axis_tready = '1') then
                        m_axis_tdata <= s_axis_tdata;
                        m_axis_tvalid <= '1';
                    else
                        m_axis_tdata <= (others => '0');
                        m_axis_tvalid <= '0';
                    end if;

                    crc_flag <= '0';
                end if; 
            end if;
        end if;
    end process;

    process (axis_aclk)
    begin
        if rising_edge(axis_aclk) then
            if (axis_aresetn = '0') then
                crc_error_count <= (others => '0');
            else
                if (crc_flag = '1') then
                    crc_error_count <=  std_logic_vector(unsigned(crc_error_count) + '1');
                end if;
            end if;
        end if;
    end process;

    m_axis_tlast <= '1' when (word_counter = PAYLOAD_WIDTH and m_axis_tvalid = '1') else '0';

    s_axis_tready <= m_axis_tready;
end rtl;
