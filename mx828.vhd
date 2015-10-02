--
-- mx828.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
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
use ieee.std_logic_arith.all;

entity mx828 is
	port
			(
				signal	arn			:	in std_logic;
				signal	clk			:	in std_logic;
				signal	from_mx828	:	in std_logic;
				signal	go			:	in std_logic;
				signal	cdata		:	in std_logic;
				signal	cword		:	in std_logic;
				signal	crdwrn		:	in std_logic;
				signal	cmd			:	in std_logic_vector(7 downto 0);
				signal	fb			:	in std_logic_vector(7 downto 0);
				signal	sb			:	in std_logic_vector(7 downto 0);

				
				signal	done		:	out std_logic;
				signal	to_mx828	:	out std_logic;
				signal	clk_mx828	:	out std_logic;
				signal	rdb_mx828	:	out std_logic_vector(7 downto 0)
			);
end mx828;

architecture rtl of mx828 is

type cbus_states is 	(cbus_idle, cbus_wait1, cbus_cmd, cbus_wait2, cbus_byte1,
					 	cbus_wait3, cbus_byte2, cbus_wait4, cbus_done);

signal	cbus_cur_state	: cbus_states;
signal	cbus_next_state	: cbus_states;

signal	shiftstart					: std_logic;
signal	shiftload					: std_logic;
signal	shifte						: std_logic;
signal	shiftinbit					: std_logic;
signal	nextbit						: std_logic;
signal	shiftbits					: std_logic;
signal	wait32						: std_logic;

signal	bitctr						: std_logic_vector(2 downto 0);
signal	sclkphase					: std_logic_vector(3 downto 0);
signal	dlyctr						: std_logic_vector(4 downto 0);
signal	shiftout					: std_logic_vector(7 downto 0);
signal	shiftin						: std_logic_vector(7 downto 0);


begin


-- Generate a delay for the interbyte and CS timings

delay32	:	process(arn, clk)
begin
		if(arn = '0') then
			dlyctr <= "00000";
		elsif(clk'event) and (clk = '1') then
			if(wait32 = '1') then
				if(dlyctr /= 31) then
					dlyctr <= dlyctr + 1;
				end if;
			else
				dlyctr <= "00000";
			end if;
		end if;
end process delay32;

-- Count the bits as they get shifted out

bitctrp	:	process(arn, clk)
begin
		if (arn = '0') then
			bitctr <= "000";
		elsif(clk'event) and (clk = '1')then
			if(shiftbits= '1') then
				if(nextbit = '1') then
					if(bitctr /= 7) then
						bitctr <= bitctr + 1;
					end if;
				end if;
			else
				bitctr <= "000";
			end if;
		end if;
end process bitctrp;


-- Main shift register (shifts left). Used for both input and output

shiftreg	:	process(arn, clk)
begin
		if (arn = '0') then
				shiftout <= "00000000";
		elsif(clk'event) and (clk = '1') then
			if(shiftload = '1') then
				shiftout <= shiftin;
			elsif(shifte = '1') then
				shiftout <= shiftout(6 downto 0) & shiftinbit;
			end if;
		end if;
end process shiftreg;

-- Manage the process of shifting a byte in or out.

shiftabyte	:	process(arn, clk)
begin
	if(arn = '0') then
		shiftbits <= '0';
	elsif(clk'event) and (clk = '1') then
		if(shiftstart = '1') then
			shiftbits <= '1';
		end if;
		if(shiftbits = '1') then
			if(bitctr = 7) and (sclkphase = 15) then -- End 
				shiftbits <= '0';
			end if;
		end if;
	end if;
end process shiftabyte;


-- Output serial clocks for as long as shiftbits is active.		

clkseq	:	process(arn, clk)
begin
		if(arn = '0') then
			sclkphase <= "0000";
			shifte <= '0';
			nextbit <= '0';
			clk_mx828 <= '1';
		elsif(clk'event) and (clk = '1') then
			shifte <= '0';
			nextbit <= '0';
			if(shiftbits = '1') then
				if(sclkphase = 0) then
					clk_mx828 <= '0';
				elsif(sclkphase = 8) then
					clk_mx828 <= '1';
				elsif(sclkphase = 12) then
					shifte <= '1';
				elsif(sclkphase = 15) then
					nextbit <= '1';
				end if;
				sclkphase <= sclkphase + 1;
			else
				sclkphase <= "0000";
			end if;
		end if;
end process clkseq;

-- Async part of state machine

cbus_sm_async	:	process( go, crdwrn, cword, cdata, shiftbits,  dlyctr, cmd, fb, sb, cbus_cur_state)
begin
	shiftstart <= '0'; -- precondition these so we don't get an implied latch
	wait32 <= '0';
	done <= '0';
	shiftload <='0';
	shiftin <= "00000000";
		
	case cbus_cur_state is -- idle loop
		when cbus_idle =>
			if(go = '1') then
				cbus_next_state <= cbus_wait1;
			else
				cbus_next_state <= cbus_idle;
			end if;
		
		when cbus_wait1 => -- wait 32 clocks for chip select delay
			wait32 <= '1';
			if(dlyctr = 31) then
				wait32 <= '0';
				shiftstart <= '1';
				shiftload <= '1';
				shiftin <= cmd;
				cbus_next_state <= cbus_cmd;
			else
				cbus_next_state <= cbus_wait1;
			end if;
			
		when cbus_cmd => -- output the command byte
			shiftin <= cmd;
			if(shiftbits = '0') then
				if(cdata = '1') then -- we have data to transfer?
					cbus_next_state <= cbus_wait2;
				else
					cbus_next_state <= cbus_wait4;
				end if;
			else
				cbus_next_state <= cbus_cmd;
			end if;
				
		when cbus_wait2 => -- wait 32 clocks for interbyte delay
			wait32 <= '1';
			if(dlyctr = 31) then
				wait32 <= '0';
				shiftin <= fb;
				shiftstart <= '1';
				shiftload <= not crdwrn;
				cbus_next_state <= cbus_byte1;
			else
				cbus_next_state <= cbus_wait2;
			end if;			
			
		when cbus_byte1 => -- input or output byte1
			shiftin <= fb;
			if(shiftbits = '0') then
				if(cword = '1') then -- we have another byte to transfer?
					cbus_next_state <= cbus_wait3;
				else
					cbus_next_state <= cbus_wait4;
				end if;
			else
				cbus_next_state <= cbus_byte1;	
			end if;
				
		when cbus_wait3 => -- wait 32 clocks for interbyte delay
			wait32 <= '1';
			if(dlyctr = 31) then
				wait32 <= '0';
				shiftin <= sb;
				shiftstart <= '1';
				shiftload <= not crdwrn;
				cbus_next_state <= cbus_byte2;
			else
				cbus_next_state <= cbus_wait3;
			end if;					
	
		when cbus_byte2 => -- output byte2
			shiftin <= sb;
			if(shiftbits = '0') then
				cbus_next_state <= cbus_wait4;
			else
				cbus_next_state <= cbus_byte2;				
			end if;
			
		when cbus_wait4 => -- wait 32 clocks for interbyte delay
			wait32 <= '1';
			if(dlyctr = 31) then
				wait32 <= '0';
				cbus_next_state <= cbus_done;
			else
				cbus_next_state <= cbus_wait4;
			end if;	
			
		when cbus_done => -- send done pulse
			done <= '1';
			cbus_next_state <= cbus_idle;	
	end case;
end process cbus_sm_async;

					
-- Sync part of state machine

cbus_sm_sync	:	process(arn, clk)
begin
	if(arn = '0') then
		cbus_cur_state <= cbus_idle;
	elsif(clk'event) and (clk = '1') then
		cbus_cur_state <= cbus_next_state;
	end if;
end process cbus_sm_sync;




			
-- concurrent statements

shiftinbit <= '0' when crdwrn = '0' else from_mx828;
to_mx828 <= shiftout(7);
rdb_mx828 <= shiftout;


end rtl;
		
	 




