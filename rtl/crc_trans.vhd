
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc_trans is
    generic (
    PAYLOAD_WIDTH : integer := 5;
    DATA_WIDTH : integer := 32;
    CRC_WIDTH : integer := 32;
    CRC_POLY : std_logic_vector := x"04C1_1DB7"
    );
    port (
    axis_aclk : in std_logic;
    axis_aresetn : in std_logic;

    data_in : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0);

    frame_ready : out std_logic;
    data_in_valid : in std_logic
    );
end crc_trans;

architecture rtl of crc_trans is

    signal crc_reg: std_logic_vector(CRC_WIDTH - 1 downto 0);
    signal byte_counter: integer range 0 to 500;
    

    function crc_calc (byte_counter : in integer range 0 to 500; data_in : in std_logic_vector(DATA_WIDTH - 1 downto 0); crc_reg : in std_logic_vector(CRC_WIDTH - 1 downto 0)) return std_logic_vector is 
        variable crc_val : std_logic_vector(CRC_WIDTH - 1 downto 0) := (others => '0');
        variable crc_temp: std_logic_vector(CRC_WIDTH - 1 downto 0) := (others => '0');
        variable i : integer;

        constant loop_var : integer := CRC_WIDTH;
        constant crc_initial : std_logic_vector (CRC_WIDTH - 1 downto 0) := x"FFFF_FFFF";
        
        begin
            if (byte_counter = 0) then
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
                byte_counter <= 0;
            else
                if (byte_counter = PAYLOAD_WIDTH) then
                    byte_counter <= 0;
                else  
                    if (data_in_valid = '1') then
                        byte_counter <= byte_counter + 1;
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
                if (byte_counter = PAYLOAD_WIDTH) then
                    crc_reg <= (others => '0');
                else
                    if (data_in_valid = '1') then
                        crc_reg <= crc_calc(byte_counter, data_in, crc_reg);
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (axis_aclk)
    begin
        if rising_edge(axis_aclk) then
            if (axis_aresetn = '0') then
                data_out <= (others => '0');
                frame_ready <= '0';
            else
                if (byte_counter < PAYLOAD_WIDTH) then
                    if (data_in_valid = '1') then
                        data_out <= data_in;
                    else
                        data_out <= (others => '0');
                    end if;
                    frame_ready <= '0';
                elsif (byte_counter = PAYLOAD_WIDTH) then
                    data_out <= crc_reg;
                    frame_ready <= '1';
                end if; 
            end if;
        end if;
    end process;

end rtl;
