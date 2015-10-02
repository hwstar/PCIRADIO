--
-- txwdog.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
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
-- Transmit watchdog 
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity txwdog is
port
		(
			arn			:	in std_logic;
			clk			:	in std_logic;
			mxaccess	:	in std_logic;
			bce9600		:	in std_logic;
			pttin		:	in std_logic_vector(3 downto 0);
			
			txwdtrip	:	out std_logic;
			pttout		:	out std_logic_vector(3 downto 0)
			
		);
end txwdog;

architecture rtl of txwdog is

signal	txwdctr		:	std_logic_vector(9 downto 0);
signal	txwdreset	:	std_logic_vector(1 downto 0);
signal	trip 		:	std_logic;


begin

txwd	:	process(arn, clk)
begin
		if(arn = '0') then
			txwdctr <= "0000000000";
			trip <='0';
		elsif(clk'event) and (clk = '1') then
			if(txwdreset(0) = '1') and (txwdreset(1) = '0') then
				txwdctr <= "0000000000";
				trip <= '0';
			elsif(bce9600 = '1') then
				if(txwdctr = 1023) then
					trip <= '1';
				else
					txwdctr <= txwdctr + 1;

				end if;
			end if;
		end if;
end process txwd;

-- look for low to high transition on mxfreeze 

wdreset :	process(arn, clk)
begin
	if(arn = '0') then
		txwdreset <= "00";
	elsif(clk'event) and (clk = '1') then
		txwdreset(1) <= txwdreset(0);
		txwdreset(0) <= mxaccess;
	end if;
end process wdreset;

		
	

	


-- concurrent statements

txwdtrip <= trip;

GEN_protptts	:	for I in 0 to 3 generate
	pttout(I) <= pttin(I) when trip = '0' else '0';
end generate GEN_protptts;


end rtl;
						