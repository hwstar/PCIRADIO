--
-- rbs.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
-- Author: Stephen A. Rodgers
--
-- Copyright (c) 2004, Stephen A. Rodgers
--
-- Steve Rodgers <hwstar@rodgers.sdcoxmail.com>
--
-- This program is free software, and the design, schematics, layout,
-- and artwork for the hardware on which it runs is free, and all are
-- distributed under the terms of the GNU General Public License.
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity rbs is
	port
			(
					arn		:	in std_logic;
					clk		:	in std_logic;
					wrn		:	in std_logic;
					regsel	:	in std_logic;
					cmdsel	:	in std_logic;
					wdb		:	in std_logic_vector(7 downto 0);

					rbsclk	:	out std_logic;
					rbsdata	:	out std_logic;
					busy	:	out std_logic;
					bq		:	out std_logic_vector(2 downto 0)
			);
end rbs;

architecture rtl of rbs is

-- signals

type bts_states is 	(bts_idle, bts_check, bts_bit_out, bts_wait);
type rbcs_states is (rbcs_idle, rbcs_test_done, rbcs_load_byte, rbcs_incb, 
					rbcs_wait_shift, rbcs_start_delay, rbcs_wait_delay1, rbcs_wait_delay2);

signal	bts_cur_state, bts_next_state	:	bts_states;
signal	rbcs_cur_state, rbcs_next_state	:	rbcs_states;

signal	clkcntena	:	std_logic;
signal	clkdone		:	std_logic;
signal	dobyte		:	std_logic;
signal	bytebsy		:	std_logic;
signal	ibdlyctren	:	std_logic;
signal	shiften		:	std_logic;
signal	shiftld		:	std_logic;
signal	dodly		:	std_logic;
signal	doclk		:	std_logic;
signal	obcinc		:	std_logic;
signal	obcclr		:	std_logic;
signal	start		:	std_logic;
signal	goclr		:	std_logic;


signal	ibceqobc	:	std_logic_vector(1 downto 0);
signal	ibctr		:	std_logic_vector(2 downto 0);
signal	obctr		:	std_logic_vector(2 downto 0);
signal	go			:	std_logic_vector(2 downto 0);
signal	bitctr		:	std_logic_vector(2 downto 0);
signal	reg0		:	std_logic_vector(7 downto 0);
signal	reg1		:	std_logic_vector(7 downto 0);
signal	reg2		:	std_logic_vector(7 downto 0);
signal	reg3		:	std_logic_vector(7 downto 0);
signal	reg4		:	std_logic_vector(7 downto 0);
signal	reg5		:	std_logic_vector(7 downto 0);
signal	shiftin		:	std_logic_vector(7 downto 0);
signal	shiftreg	:	std_logic_vector(7 downto 0);
signal	clkcectr	:	std_logic_vector(9 downto 0);


begin


-- clock counter used to generate delays and serial clock timing

clkce	:	process(arn, clk)
begin
	if(arn = '0') then
		clkcectr <= "0000000000";
	elsif(clk'event) and (clk = '1') then
		if(ibdlyctren = '1') or (clkcntena = '1') then -- only count when needed
			clkcectr <= clkcectr + 1;
		else
			clkcectr <= "0000000000";
		end if;
	end if;
end process clkce;


-- resource, wait for a doclk signal then enable the clock phase counter

clkphctl	:	process(arn, clk)
begin
	if(arn = '0') then
		clkcntena <= '0';
	elsif(clk'event) and (clk = '1') then
		if(clkcectr = "0111111111") then
			clkcntena <= '0';
		elsif(doclk = '1') then
			clkcntena <= '1';
		end if;
	end if;
end process clkphctl;


-- output control signals based on clock phases

clkphctrl	:	process(clkcectr, clkcntena)
begin
	rbsclk <= '1';
	shiften <= '0';
	clkdone <= '0';
		if(clkcntena = '1') then	
			case clkcectr(8 downto 6) is
				when "000" =>
					rbsclk <= '0';
				when "001" =>
					rbsclk <= '0';
				when "010" =>
					rbsclk <= '0';
				when "011" =>
					rbsclk <= '1';
				when "100" =>
					rbsclk <= '1';
				when "101" =>
					rbsclk <= '1';
				when "110" =>
					rbsclk <= '1';
					if(clkcectr(5 downto 0) = "000000") then
						shiften <= '1';
					end if;
				when "111" =>
					if(clkcectr(5 downto 0) = "111111") then
						clkdone <= '1';
					end if;
					rbsclk <= '1';
				when others =>
					rbsclk <= '0';
			end case;
		end if;
end process clkphctrl;


-- resource, interbyte delay control

ibdelayctrl	:	process(arn, clk)
begin
	if(arn = '0') then
		ibdlyctren <= '0';
	elsif(clk'event) and (clk = '1') then
		if(clkcectr = "1111111111") then
			ibdlyctren <= '0';
		elsif(dodly = '1') then
			ibdlyctren <= '1';
		end if;
	end if;
end process ibdelayctrl;


-- byte queing and commands: act on decode strobes and write clock

bytqc	:	process(arn, wrn, goclr)
begin
	if(arn = '0') then
		ibctr <= "000";
		go(0) <= '0';
	elsif(goclr = '1') then
		go(0) <= '0';
		ibctr <= "000";
	elsif(wrn'event) and (wrn = '1') then
		if(cmdsel = '1') and (wdb = "00000000") then
			ibctr <= "000";
		elsif(cmdsel = '1') and (wdb = "00000001") then
			go(0) <= '1';
		elsif(regsel = '1') then
			if(ibctr /= 6) then
				ibctr <= ibctr + 1;
			end if;
		end if;
	end if;
end process bytqc;


-- sync go to system clock to detect a 0 -> 1 transition

gosyncp		:	process(arn, clk)
begin
	if(arn = '0') then
		go(2 downto 1) <= "00";
	elsif(clk'event) and (clk = '1') then
		go(2) <= go(1);
		go(1) <= go(0);
	end if;
end process gosyncp;

-- synchronize ibcequobc to system clock

ibceqobcp	:	process(arn, clk)
begin
	if(arn = '0') then
		ibceqobc(1) <= '0';
	elsif(clk'event) and (clk = '1') then
		ibceqobc(1) <= ibceqobc(0);
	end if;
end process ibceqobcp;

	
-- fifo output address counter

obctrp		:	process(arn, clk)
begin
	if(arn = '0') then
		obctr <= "000";
	elsif(clk'event) and (clk = '1') then
		if(obcclr = '1') then
			obctr <= "000";
		elsif(obcinc = '1') then
			obctr <= obctr + 1;
		end if;
	end if;
end process obctrp;
			

-- fifo register 0

qr0		:	process(arn, wrn)
begin
	if(arn = '0') then
		reg0 <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(regsel = '1') and (ibctr = "000") then
			reg0 <= wdb;
		end if;
	end if;
end process qr0;

-- fifo register 1

qr1		:	process(arn, wrn)
begin
	if(arn = '0') then
		reg1 <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(regsel = '1') and (ibctr = "001") then
			reg1 <= wdb;
		end if;
	end if;
end process qr1;

-- fifo register 2

qr2		:	process(arn, wrn)
begin
	if(arn = '0') then
		reg2 <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(regsel = '1') and (ibctr = "010") then
			reg2 <= wdb;
		end if;
	end if;
end process qr2;

-- fifo register 3

qr3		:	process(arn, wrn)
begin
	if(arn = '0') then
		reg3 <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(regsel = '1') and (ibctr = "011") then
			reg3 <= wdb;
		end if;
	end if;
end process qr3;

-- fifo register 4

qr4		:	process(arn, wrn)
begin
	if(arn = '0') then
		reg4 <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(regsel = '1') and (ibctr = "100") then
			reg4 <= wdb;
		end if;
	end if;
end process qr4;

-- fifo register 5

qr5		:	process(arn, wrn)
begin
	if(arn = '0') then
		reg5 <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(regsel = '1') and (ibctr = "101") then
			reg5 <= wdb;
		end if;
	end if;
end process qr5;

-- fifo output mux

fifoomuxp	:	process(obctr, reg0, reg1, reg2, reg3, reg4, reg5)
begin
	case obctr is
		when "000" =>
			shiftin <= reg0;
		when "001" =>
			shiftin <= reg1;
		when "010" =>
			shiftin <= reg2;
		when "011" =>
			shiftin <= reg3;
		when "100" =>
			shiftin <= reg4;
		when "101" =>
			shiftin <= reg5;
		when others =>
			shiftin <= "00000000";
	end case;
end process fifoomuxp;

-- output shift register (LSB first) 

shiftrtp	:	process(arn, clk)
begin
	if(arn = '0') then
		shiftreg <= "00000000";
	elsif(clk'event) and (clk = '1') then
		if(shiftld = '1') then
			shiftreg <= shiftin;
		elsif(shiften = '1') then
			shiftreg <= '0' & shiftreg(7 downto 1);
		end if;
	end if;
end process shiftrtp;

-- count bits

bitctrp	:	process(arn, clk)
begin
	if(arn = '0') then
		bitctr <= "000";
	elsif(clk'event) and (clk = '1') then
		if(clkdone = '1') then
			bitctr <= bitctr + 1;
		end if;
	end if;
end process bitctrp;
			

-- state machine to shift out an entire byte

dobytap:	process(dobyte, clkdone, bitctr, bts_cur_state)
begin
	bytebsy <= '0';
	doclk <= '0';
	case bts_cur_state is
		when bts_idle =>
			if(dobyte = '1') then
				bytebsy <= '1';
				bts_next_state <= bts_bit_out;
			else
				bts_next_state <= bts_idle;
			end if;
		
		when bts_check =>
			if(clkdone = '1') then
				if(bitctr = 7) then
					bts_next_state <= bts_idle; -- byte done
				else
					bytebsy <= '1';
					bts_next_state <= bts_bit_out;
				end if;
			else
				bytebsy <= '1';
				bts_next_state <= bts_check;
			end if;
		
		when bts_bit_out =>
			bytebsy <= '1';
			doclk <= '1';
			bts_next_state <= bts_wait;
			
		when bts_wait =>
			bytebsy <= '1';
			bts_next_state <= bts_check;
		
		when others =>
			bts_next_state <= bts_idle;
	end case;
			
end process dobytap;

-- sync part of byte state machine (above)

dobytsp	:	process(arn, clk)
begin
	if(arn = '0') then
		bts_cur_state <= bts_idle;
	elsif(clk'event) and (clk = '1') then
		bts_cur_state <= bts_next_state;
	end if;
end process dobytsp;


-- async part of main state machine

rbcstap		:	process(start, bytebsy, ibdlyctren, ibceqobc(1), rbcs_cur_state)
begin
	shiftld <= '0';
	dodly <= '0';
	dobyte <= '0';
	obcclr <= '0';
	obcinc <= '0';
	goclr <= '0';

	case rbcs_cur_state is
		when rbcs_idle =>
			if(start = '1') then
				rbcs_next_state <= rbcs_test_done;
			else
				rbcs_next_state <= rbcs_idle;
			end if;

		when rbcs_test_done =>
			if(ibceqobc(1) = '1') then
				goclr <= '1';
				obcclr <= '1';
				rbcs_next_state <= rbcs_idle;
			else
				rbcs_next_state <= rbcs_load_byte;
			end if;
						
		when rbcs_load_byte =>
			shiftld <= '1';
			dobyte <= '1';
			rbcs_next_state <= rbcs_incb;
			
		when rbcs_incb =>
			obcinc <= '1';
			rbcs_next_state <= rbcs_wait_shift;
			
		when rbcs_wait_shift =>
			if(bytebsy = '0') then
				rbcs_next_state <= rbcs_start_delay;
			else
				rbcs_next_state <= rbcs_wait_shift;
			end if;
				
		when rbcs_start_delay =>
			dodly <= '1';
			rbcs_next_state <= rbcs_wait_delay1;
			
		when rbcs_wait_delay1 =>
			rbcs_next_state <= rbcs_wait_delay2;
			
		when rbcs_wait_delay2 =>
			if(ibdlyctren = '0') then
				rbcs_next_state <= rbcs_test_done;
			else
				rbcs_next_state  <= rbcs_wait_delay2;
			end if;
			
		when others =>
			rbcs_next_state <= rbcs_idle;
	end case;
end process rbcstap;
	
-- sync part of main state machine (above)

rbcstsp	:	process(arn, clk)
begin
	if(arn = '0') then
		rbcs_cur_state <= rbcs_idle;
	elsif(clk'event) and (clk = '1') then
		rbcs_cur_state <= rbcs_next_state;
	end if;
end process rbcstsp;		
		

-- concurrent statements

start <= '1' when go(1) = '1' and go(2) = '0' else '0';
ibceqobc(0) <= '1' when ibctr = obctr else '0';
rbsdata <= shiftreg(0);
busy <= go(0);
bq <= ibctr;


end rtl;



	
			
		
	
			
					
