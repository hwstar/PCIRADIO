--
-- urx.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
-- Author: Stephen A. Rodgers
--
-- Copyright (c) 2005, Stephen A. Rodgers
--
-- Steve Rodgers <hwstar@rodgers.sdcoxmail.com>
--
-- This program is free software, and the design, schematics, layout,
-- and artwork for the hardware on which it runs is free, and all are
-- distributed under the terms of the GNU General Public License.
--

--
-- UART receiver
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity urx is
port	(
			arn		:	in std_logic;
			clk		:	in std_logic;
			rxd		:	in std_logic;
			bclken16:	in std_logic;
			
			rxce	:	out std_logic;
			rxbyte	:	out std_logic_vector(7 downto 0)
		);
end urx;
		
		
architecture rtl of urx is

type rxstate is	(s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12);
signal cur_state, next_state	:	rxstate;

signal samplectren	:	std_logic;
signal initialsample:	std_logic;
signal samplebit	:	std_logic;
signal shiftena		:	std_logic;

signal urxregister	:	std_logic_vector(7 downto 0);
signal samplectr	:	std_logic_vector(4 downto 0);
signal rxdbits		:	std_logic_vector(1 downto 0);

begin

-- synchronize RX data to our system clock

rxdsync		:	process(arn, clk)
begin
		if(arn = '0') then
			rxdbits <= "11";
		elsif(clk'event) and (clk = '1') then
			rxdbits(0) <= rxd;
			rxdbits(1) <= rxdbits(0);
		end if;
end process rxdsync;

-- count at 16x baudrate when enabled
-- This generates the bit sample signal at the right place in the bit cell.

cntsamples	:	process(arn, clk)
begin
		if(arn = '0') then
			samplectr <= "00000";
			samplebit <= '0';
		elsif(clk'event) and (clk = '1') then
			samplebit <= '0';
			if(samplectren= '1') then
				if(bclken16 = '1') then
					samplectr <= samplectr + 1;
					if(initialsample = '1') then
						if(samplectr = 7) then -- 1/2 a bit cell
							samplebit <= '1';
							samplectr <= "00000";
						end if;
					else
						if(samplectr = 15) then -- a full bit cell
							samplebit <= '1';
							samplectr <= "00000";
						end if;
					end if;
				end if;
			else
				samplectr <= "00000";
			end if;
		end if;
end process cntsamples;	

-- receive shift register

rcv_sr		:	process(arn, clk)
begin
		if(arn = '0') then
			urxregister <= "00000000";
		elsif(clk'event) and (clk = '1') then
			if(samplebit = '1') and (shiftena = '1') then
				urxregister <= rxdbits(1) & urxregister(7 downto 1);
			end if;
		end if;
end process rcv_sr;


-- async. part of receiver state machine

sm_async	:	process(rxdbits(1), bclken16, samplebit, cur_state)
begin
		rxce <= '0';
		shiftena <= '0';
		samplectren <= '0';
		initialsample <= '0';

		
		case cur_state is
			when s0 => -- start bit edge detect
				if(bclken16 = '1') then
					if(rxdbits(1) = '0') then
						samplectren <= '1';
						initialsample <= '1';
						next_state <= s1;
					else
						next_state <= s0;
					end if;
				else
					next_state <= s0;
				end if;
			
						
			when s1 => -- start bit detect, center of bit cell
				samplectren <= '1';
				initialsample <= '1';
				if(samplebit = '1') then
					if(rxdbits(1) = '0') then
						shiftena <= '1';
						initialsample <= '0';
						next_state <= s2;
					else
						initialsample <= '0';
						samplectren <= '0';
						next_state <= s11; -- noise/glitch?
					end if;
				else
					next_state <= s1;
				end if;			
						
			when s2 => -- wait for bit cell center on bit 0
				shiftena <= '1';
				samplectren <= '1';
				if(samplebit = '1') then
					next_state <= s3;
				else
					next_state <= s2;
				end if;
				
			when s3 => -- wait for bit cell center on bit 1
				shiftena <= '1';
				samplectren <= '1';
				if(samplebit = '1') then
					next_state <= s4;
				else
					next_state <= s3;
				end if;				
				
			when s4 => -- wait for bit cell center on bit 2
				shiftena <= '1';
				samplectren <= '1';
				if(samplebit = '1') then
					next_state <= s5;
				else
					next_state <= s4;
				end if;
			
			when s5 => -- wait for bit cell center on bit 3
				shiftena <= '1';
				samplectren <= '1';
				if(samplebit = '1') then
					next_state <= s6;
				else
					next_state <= s5;
				end if;						
					
			when s6 => -- wait for bit cell center on bit 4
				shiftena <= '1';
				samplectren <= '1';
				if(samplebit = '1') then
					next_state <= s7;
				else
					next_state <= s6;
				end if;	
				
			when s7 => -- wait for bit cell center on bit 5
				shiftena <= '1';
				samplectren <= '1';
				if(samplebit = '1') then
					next_state <= s8;
				else
					next_state <= s7;
				end if;		

			when s8 => -- wait for bit cell center on bit 6
				shiftena <= '1';
				samplectren <= '1';
				if(samplebit = '1') then
					next_state <= s9;
				else
					next_state <= s8;
				end if;					
						
			when s9 => -- wait for bit cell center on bit 7
				shiftena <= '1';
				samplectren <= '1';
				if(samplebit = '1') then
					next_state <= s10;
				else
					next_state <= s9;
				end if;						
			
			when s10 => -- stop bit detect
				samplectren <= '1';
				if(samplebit = '1') then
					if(rxdbits(1) = '1') then
						next_state <= s12; -- done
					else
						samplectren <= '0';
						next_state <= s11; -- framing err?
					end if;
				else
					next_state <= s10;
				end if;
			
			when s11 => -- 0 detected for stop bit, framing err? Wait till line goes high			
				if(bclken16 = '1') then
					if(rxdbits(1) = '1') then
						next_state <= s0;
					else
						next_state <= s11;
					end if;
				else
					next_state <= s11;
				end if;
				
			when s12 => -- pulse the rxce high for one clock to indicate a byte is ready
				rxce <= '1';
				next_state <= s0;
				
			when others =>
				next_state <= s0;
		end case;
end process sm_async;

-- sync part of state machine 

sm_sync	:	process(arn, clk)
begin
		if(arn = '0') then
			cur_state <= s0;
		elsif(clk'event) and (clk = '1') then
			cur_state <= next_state;
		end if;
end process sm_sync;

rxbyte <= urxregister;

end rtl;

			

			
				
				

				
					
	
			
			
			
						
