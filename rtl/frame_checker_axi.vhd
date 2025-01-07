
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity frame_checker_axi is
    generic (
    TDATA_WIDTH : integer := 32;
    USER_CHECKSUM : std_logic_vector := x"A254_FCDE"
    );
    port (
    axis_aclk : in std_logic;
    axis_aresetn : in std_logic;

    s_axis_tdata : in std_logic_vector(TDATA_WIDTH - 1 downto 0);
    s_axis_tvalid : in std_logic;
    s_axis_tlast : in std_logic;
    s_axis_tready : out std_logic;

    frame_count_out: out std_logic_vector (TDATA_WIDTH - 1 downto 0);
    error_count_out: out std_logic_vector (TDATA_WIDTH - 1 downto 0);
    frame_error : out std_logic
    );
end frame_checker_axi;

architecture rtl of frame_checker_axi is

    constant check_val: std_logic_vector(TDATA_WIDTH - 1 downto 0) := USER_CHECKSUM;
    signal frame_counter: integer;
    signal packet_counter: integer;
    signal error_counter: integer;
    signal flag_val: integer;

    signal packet_reg: std_logic_vector(TDATA_WIDTH - 1 downto 0);
    signal packet_checker: integer;

    constant HEADER_WIDTH: integer := 16;
    constant PAYLOAD_INDEX: integer := 17;
    begin

        process (axis_aclk)
        begin
            if rising_edge(axis_aclk) then 
                if (axis_aresetn = '0') then 
                    frame_counter <= 0;
                else
                    if (s_axis_tlast = '1' and s_axis_tvalid = '1') then
                        frame_counter <= frame_counter + 1;
                    end if;
                end if;
            end if;
        end process;

        process (axis_aclk)
        begin
            if rising_edge(axis_aclk) then 
                if (axis_aresetn = '0') then 
                    packet_counter <= 0;
                else
                    if (s_axis_tlast = '1') then
                        packet_counter <= 0;
                    elsif (s_axis_tvalid = '1') then
                        packet_counter <= packet_counter + 1;
                    end if;
                end if;
            end if;
        end process;

        process (axis_aclk)
        begin
            if rising_edge(axis_aclk) then 
                if (axis_aresetn = '0') then 
                    s_axis_tready <= '0';
                    flag_val <= 0;
                else
                    s_axis_tready <= '1';
                    if ((s_axis_tdata /= check_val) and (packet_counter = HEADER_WIDTH) and (s_axis_tvalid = '1')) then
                        flag_val <= 1;
                    elsif (s_axis_tlast = '1') then
                        flag_val <= 0;
                    end if;
                end if;
            end if;
        end process;

        process (axis_aclk)
        begin
            if rising_edge(axis_aclk) then 
                if (axis_aresetn = '0') then 
                    packet_reg <= (others => '0');
                    packet_checker <= 0;
                else

                    if (packet_counter = PAYLOAD_INDEX) then
                        packet_reg <= s_axis_tdata;
                    elsif (packet_counter > PAYLOAD_INDEX) then
                        if ((s_axis_tdata /= std_logic_vector(unsigned(packet_reg) + '1')) and s_axis_tvalid = '1') then
                            packet_checker <= packet_checker + 1;
                        end if;
                        if (s_axis_tvalid = '1') then
                            packet_reg <= s_axis_tdata;
                        end if;
                    elsif (s_axis_tlast = '1') then
                        packet_reg <= (others => '0');
                        packet_checker <= 0;
                    end if;
                end if;
            end if;
        end process;
        
        process (axis_aclk)
        begin
            if rising_edge(axis_aclk) then 
                if (axis_aresetn = '0') then 
                    error_counter <= 0;
                    frame_error <= '0';
                else
                    if (flag_val = 1) or (packet_checker /= 0) then
                        frame_error <= '1';
                    else
                        frame_error <= '0';
                    end if;

                    if (s_axis_tlast = '1' and s_axis_tvalid = '1' and ((flag_val = 1) or (packet_checker /= 0))) then
                        error_counter <= error_counter + 1;
                    else
                        error_counter <= error_counter;

                    end if;
                end if;
            end if;
        end process;

        error_count_out <= std_logic_vector(to_unsigned(error_counter,TDATA_WIDTH));
        frame_count_out <= std_logic_vector(to_unsigned(frame_counter,TDATA_WIDTH));
end rtl;
