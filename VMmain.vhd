library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity all_three_segments_module is
      port ( clock_in : in std_logic;
		reset : in std_logic;          -- reset money
       price_selector : in std_logic_vector(7 downto 0);
	       nickel : in std_logic;  -- 5 cents
		 dime : in std_logic; -- 10 cents
	      quarter : in std_logic; -- 50 cents
	       dollar : in std_logic; -- 100 cents
		  pay : in std_logic;
	          LED : out std_logic_vector(7 downto 0);
 Seven_Segment_Enable : out std_logic_vector(2 downto 0);
Seven_Segment_Display : out std_logic_vector(7 downto 0));

end all_three_segments_module;

architecture Behavioral of all_three_segments_module is

-- Internal signals for processing the two clocks and the 
-- signals to select which display to update and the internal 
-- signals required to drive the displays separately
signal refresh_count : integer := 0;
signal refresh_clk : std_logic := '1';

signal second_count : integer := 0;
signal second_clk : std_logic := '1';

signal digit_sel : unsigned(1 downto 0);
signal bcd : integer := 0;
signal Seven_Segment_Display_output : std_logic_vector (7 downto 0) := (others => '0');
signal bcd0, bcd1, bcd2 : integer := 0;

signal unit_count : integer := 0;
signal ten_count : integer := 0;
signal hundred_count : integer := 0;

type statetype is (Rst, PriceSelector, MoneyIn, Add, Check, Dispense);
signal state : statetype;

signal price, coin, total: unsigned (7 downto 0);

begin

-- Divide down the 12 MHz input clock to for the refresh rate
-- and the one second clock
-- change the values in the counters to change the refresh rate
-- and the clock update speed.

process(Clock_in)
begin
	if(clock_in'event and clock_in='1') then 
	   refresh_count <= refresh_count+1;
	   second_count <= second_count+1;
		
		if(second_count = 750000) then
			second_clk <= not second_clk;
			second_count <= 1;
		end if;
		
		if(refresh_count = 2400) then
			refresh_clk <= not refresh_clk;
			refresh_count <= 1;
		end if;
	end if;
end process; 

-- Next we have all of the internal signals needed for
-- processing the two clocks required along with counters and the
-- signals to select which display to update and the internal 
-- signals required to drive the displays separately. 

process(second_clk, reset, nickel, dime, quarter, dollar)
begin
	if (reset = '0') then
	state <= Rst;
	elsif rising_edge (second_clk) then
      bcd0 <= unit_count;
      bcd1 <= ten_count;
		bcd2 <= hundred_count;
		
	case (state) is
	
-- state machine 
	
		when Rst =>
				unit_count <= 0;
				ten_count <= 0;
				hundred_count <= 0;
				LED <= "00000000";
				total <= "00000000";
				state <= PriceSelector;

		when PriceSelector =>
			if (price_selector = "11111110") then
				unit_count <= 5; 
				ten_count <= 7; 
				hundred_count <= 0;
				price <= "01001011";
			   state <= MoneyIn;		
		
			elsif (price_selector = "11111101") then
				unit_count <= 0; 
				ten_count <= 0; 
				hundred_count <= 1;
				price <= "01100100";
			   state <= MoneyIn;		
		
			elsif (price_selector = "11111011") then
				unit_count <= 5; 
				ten_count <= 2; 
				hundred_count <= 1;
				price <= "01111101";
			   state <= MoneyIn;		
		
			elsif (price_selector = "11110111") then
				unit_count <= 0; 
				ten_count <= 5; 
				hundred_count <= 1;
				price <= "10010110";
			   state <= MoneyIn;		
		
			elsif (price_selector = "11101111") then
				unit_count <= 5; 
				ten_count <= 7; 
				hundred_count <= 1;
				price <= "10101111";
			   state <= MoneyIn;		
		
			elsif (price_selector = "11011111") then
				unit_count <= 0; 
				ten_count <= 0; 
				hundred_count <= 2;
				price <= "11001000";
			   state <= MoneyIn;		
		
			elsif (price_selector = "10111111") then
				unit_count <= 5; 
				ten_count <= 2; 
				hundred_count <= 2;
				price <= "11100001";
			   state <= MoneyIn;		
		
			elsif (price_selector = "01111111") then
				unit_count <= 0; 
				ten_count <= 5; 
				hundred_count <= 2;
				price <= "11111010";
			   state <= MoneyIn;		
			end if;
 
		when MoneyIn =>
		LED <= "11000000";
          if (nickel = '0') then
               coin <= "00000101"; -- 5
               state <= Add;
          elsif (dime = '0') then
               coin <= "00001010"; -- 10
               state <= Add;	
          elsif (quarter = '0') then
               coin <= "00011001"; -- 25
               state <= Add;
			 elsif (dollar = '0') then
               coin <= "01100100"; -- 100
               state <= Add;
          else
               state <= MoneyIn;
           end if; 

		when Add =>
			LED <= "00011000";
		   total <= coin + total;
         coin <= "00000000";
		   state <= Check;

		when Check =>
			LED <= "00000011";
				if (pay = '0') then
					if (total >= price) then
						state <= Dispense;
					else
						state <= MoneyIn;
					end if;
				end if;	 
				
		when Dispense =>
			LED <= "11111111";
			state <= Rst;

end case;
end if;
end process;

-- checks whether the refresh clock has changed state and is positive.  
-- If this is true then the appropriate seven segment display is selected, 
-- the value required is passed to the display and converted from an integer 
-- value into an inverted binary value to drive the appropriate segments

process(refresh_clk) --period of clk is 0.0001 seconds.
begin
	if(refresh_clk' event and refresh_clk='1') then
		digit_sel <= digit_sel + 1;
	end if;		
end process;

	-- multiplexer to select a BCD digit
   with digit_sel select
        bcd <= bcd0 when "00",
               bcd1 when "01",
               bcd2 when others;
					
	-- activate selected digit's anode
   with digit_sel select
        Seven_Segment_Enable <= "110" when "00",
                                "101" when "01",
                                "011" when others;

   with bcd select

	Seven_Segment_Display_output(7 downto 0) <= B"00000011" when 0,
						    B"10011111" when 1,
						    B"00100101" when 2,
						    B"00001101" when 3,
						    B"10011001" when 4,
						    B"01001001" when 5,
					            B"01000001" when 6,
						    B"00011111" when 7,
						    B"00000001" when 8,
						    B"00011001" when 9,
						    B"11111111" when others;
					  			
-- send data to seven segment display.
Seven_Segment_Display(7 downto 0) <= Seven_Segment_Display_output(7 downto 0);  

end Behavioral;  
