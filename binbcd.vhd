library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
 
entity binbcd is
    GENERIC(
        NBITS  : integer :=  14; -- Number of bits of the binary number
        NOUT: integer := 16 -- Number of bits of the BCD number (output).
    );
    
    PORT(
        SW_EXP: in std_logic_vector(NBITS-1   downto 0); -- Input, switches (Binary)
        CLK: in std_logic;                               -- Clock signal
        LED_EXP: out std_logic_vector(NOUT-1 downto 0);  -- Output,LEDs (BCD)
        D_POS: out std_logic_vector(3 downto 0);         -- Display positions
        D_SEG: out std_logic_vector(6 downto 0)          -- Display segments
       );
end binbcd;
 
architecture Behavioral of binbcd is
    signal clk_10: std_logic := '0';                                        -- Clock 0.1 ms signal 
    signal tmp_10: std_logic_vector(7 downto 0) := (others => '0');         -- Hexadecimal value
    signal num_bcd: std_logic_vector(NOUT-1 downto 0):= (others => '0');    -- Result value in BCD
    signal numdis: std_logic_vector(3 downto 0) := (others => '0');         -- Split BCD value to represent into displays
    signal position: std_logic_vector(3 downto 0) := (others => '0');       -- Binary value
begin
    process_bcd: process(SW_EXP)
        variable z: std_logic_vector(NBITS+NOUT-1 downto 0);
    begin
        -- Initialization of data to zero
        z := (others => '0');
        -- First three left shifts
        z(NBITS+2 downto 3) := SW_EXP;
        -- Loop for the remaining shifts
        for i in 0 to NBITS-4 loop
            -- Units (4 bits).
            if z(NBITS+3 downto NBITS) > 4 then
                z(NBITS+3 downto NBITS) := z(NBITS+3 downto NBITS) + 3;
            end if;
            -- Tens (4 bits).
            if z(NBITS+7 downto NBITS+4) > 4 then
                z(NBITS+7 downto NBITS+4) := z(NBITS+7 downto NBITS+4) + 3;
            end if;
            -- Hundreds (4 bits).
            if z(NBITS+11 downto NBITS+8) > 4 then
                z(NBITS+11 downto NBITS+8) := z(NBITS+11 downto NBITS+8) + 3;
            end if;
            -- Thousands (4 bits).
            if z(NBITS+14 downto NBITS+12) > 4 then
                z(NBITS+14 downto NBITS+12) := z(NBITS+14 downto NBITS+12) + 3;
            end if;
            -- Shift to the left.
            z(NBITS+NOUT-1 downto 1) := z(NBITS+NOUT-2 downto 0);
        end loop;
        -- Assign z data to our BCD variable.
        num_bcd <= z(NBITS+NOUT-1 downto NBITS);        
    end process;
    
    
    -------------------------------------
    --    Show BCD value in the LEDs   --
    -------------------------------------
    LED_EXP <= num_bcd;
    
    
    -------------------------------------
    -- Show BCD value into the display --
    -------------------------------------
    
    -- Clock divider to 0.1 ms --
    -- Increment auxiliary counter every rising edge of CLK
    -- if you meet half a period of 0.1 ms invert clk_10
    -- Switch counter -- 
    process (CLK)
    begin
        if rising_edge(CLK) then
            tmp_10 <= tmp_10 + 1;
            if tmp_10 = x"32" then
                tmp_10 <= x"00";
                clk_10 <= not clk_10;
            end if;
        end if;
    end process;
    
    
    -- Switch between displays and its corresponding values --
    process (clk_10)
    begin
        if rising_edge(clk_10) then
            if position = "0111" then
                numdis <= num_bcd(3 downto 0);
                position <= "1110";
            elsif position = "1110" then
                numdis <= num_bcd(7 downto 4);  
                position <= "1101";
            elsif position = "1101" then 
                numdis <= num_bcd(11 downto 8); 
                position <= "1011";
            elsif position <= "1011" then
                numdis <= num_bcd(15 downto 12);   
                position <= "0111";
            end if;
         end if;
    end process;

    
    
    -- Counter to seven-segment display, low active --
    with numdis select                      --          0
        D_SEG <= "1111001" when "0001",     -- 1       ---
                 "0100100" when "0010",     -- 2    5 |   | 1
                 "0110000" when "0011",     -- 3       ---   <- 6
                 "0011001" when "0100",     -- 4    4 |   | 2
                 "0010010" when "0101",     -- 5       ---
                 "0000010" when "0110",     -- 6        3
                 "1111000" when "0111",     -- 7
                 "0000000" when "1000",     -- 8    
                 "0010000" when "1001",     -- 9
                 "1000000" when others;     -- 0
                 
    D_POS <= position;

end Behavioral;
