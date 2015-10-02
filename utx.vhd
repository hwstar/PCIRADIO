--
-- utx.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
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
-- UART transmitter
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity utx is
port	(
			arn		:	in std_logic;
			clk		:	in std_logic;
			bclken	:	in std_logic;
			txgo	:	in std_logic;
			txbyte	:	in std_logic_vector(7 downto 0);
			
			txdone	:	out std_logic;
			txd		:	out std_logic
		);
end utx;

architecture rtl of utx is

type txstate is (s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12);
signal	cur_state, next_state	:	txstate;

signal	txbit			:	std_logic;
signal	utxregister		:	std_logic_vector(7 downto 0);


begin

-- synchronize the transmit data to the system clock to clean up mux glitches

utx_bitsync	:	process(arn, clk)
begin
	if(arn = '0') then
		txd <= '1';
	elsif(clk'event) and (clk = '1') then
		txd <= txbit;
	end if;
end process utx_bitsync;
		
-- register the byte to be sent

utx_reg		:	process(arn, clk)
begin
	if(arn = '0') then
		utxregister <= "00000000";
	elsif(clk'event) and (clk = '1') then
		if(txgo = '1') then
			utxregister <= txbyte;
		end if;
	end if;
end process utx_reg;


-- async part of main state machine

sm_async	:	process(bclken, txgo, utxregister, cur_state)
begin
		txdone <= '0';
		txbit <= '1';
		
		case cur_state is
			when s0 => -- look for txgo
				if(txgo = '1') then
					next_state <= s1;
				else
					next_state <= s0;
				end if;
		
			when s1 => -- wait for a bclken event
				if(bclken = '1') then
					txbit <= '0'; -- send start bit
					next_state <= s2;
				else
					next_state <= s1;
				end if;
				
			when s2 => -- wait for a bclken event
				txbit <= '0'; -- start bit
				if(bclken = '1') then
					txbit <= utxregister(0); -- send bit 0
					next_state <= s3;
				else
					next_state <= s2;
				end if;
					
			when s3 => -- wait for a bclken event
				txbit <= utxregister(0); -- bit 0
				if(bclken = '1') then
					txbit <= utxregister(1); -- send bit 1
					next_state <= s4;
				else
					next_state <= s3;
				end if;

			when s4 => -- wait for a bclken event
				txbit <= utxregister(1); -- bit 1
				if(bclken = '1') then
					txbit <= utxregister(2); -- send bit 2
					next_state <= s5;
				else
					next_state <= s4;
				end if;

			when s5 => -- wait for a bclken event
				txbit <= utxregister(2); -- bit 2
				if(bclken = '1') then
					txbit <= utxregister(3); -- send bit 3
					next_state <= s6;
				else
					next_state <= s5;
				end if;

			when s6 => -- wait for a bclken event
				txbit <= utxregister(3); -- bit 3
				if(bclken = '1') then
					txbit <= utxregister(4); -- send bit 4
					next_state <= s7;
				else
					next_state <= s6;
				end if;							

			when s7 => -- wait for a bclken event
				txbit <= utxregister(4); -- bit 4
				if(bclken = '1') then
					txbit <= utxregister(5); -- send bit 5
					next_state <= s8;
				else
					next_state <= s7;
				end if;		


			when s8 => -- wait for a bclken event
				txbit <= utxregister(5); -- bit 5
				if(bclken = '1') then
					txbit <= utxregister(6); -- send bit 6
					next_state <= s9;
				else
					next_state <= s8;
				end if;

			when s9 => -- wait for a bclken event
				txbit <= utxregister(6); -- bit 6
				if(bclken = '1') then
					txbit <= utxregister(7); -- send bit 7
					next_state <= s10;
				else
					next_state <= s9;
				end if;			

			when s10 => -- wait for a bclken event
				txbit <= utxregister(7); -- bit 7
				if(bclken = '1') then
					txbit <= '1'; -- send stop bit
					next_state <= s11;
				else
					next_state <= s10;
				end if;
					
			when s11 => -- wait for a bclken event
				txbit <= '1'; -- stop bit
				if(bclken = '1') then	
					next_state <= s12; -- done
				else
					next_state <= s11;
				end if;
				
			when s12 =>
				txdone <= '1';
				next_state <= s0;
			
			when others =>
				next_state <= s0;
							
		end case;
end process sm_async;



-- sync part of main state machine

sm_sync	:	process(arn, clk)
begin
		if(arn = '0') then
			cur_state <= s0;
		elsif(clk'event) and (clk = '1') then
			cur_state <= next_state;
		end if;
end process sm_sync;

end rtl;

-- end of file


			
			