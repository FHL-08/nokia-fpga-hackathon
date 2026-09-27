library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task_8_dual_port_ram is
    generic (
        ADDR_WIDTH : integer := 7;
        MEM_SIZE   : integer := 128;
        DATA_WIDTH : integer := 20
    );
    port (
        clk_a  : in  std_logic;
        en_a   : in  std_logic;
        we_a   : in  std_logic;
        addr_a : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        din_a  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        dout_a : out std_logic_vector(DATA_WIDTH-1 downto 0);

        clk_b  : in  std_logic;
        en_b   : in  std_logic;
        we_b   : in  std_logic;
        addr_b : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        din_b  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        dout_b : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity task_8_dual_port_ram;

architecture rtl of task_8_dual_port_ram is
    type ram_type is array (0 to MEM_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    shared variable ram : ram_type;
    attribute ram_style : string;
    attribute ram_style of ram : variable is "block";
begin

    process (clk_a)
    begin
        if rising_edge(clk_a) then
            if en_a = '1' then
                if we_a = '1' then
                    ram(to_integer(unsigned(addr_a))) := din_a;
                end if;
                dout_a <= ram(to_integer(unsigned(addr_a)));
            end if;
        end if;
    end process;

    process (clk_b)
    begin
        if rising_edge(clk_b) then
            if en_b = '1' then
                if we_b = '1' then
                    ram(to_integer(unsigned(addr_b))) := din_b;
                end if;
                dout_b <= ram(to_integer(unsigned(addr_b)));
            end if;
        end if;
    end process;

end architecture rtl;

