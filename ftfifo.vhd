--
-- ftfifo.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
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
-- Fall through (pipeline) fifo
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ftfifo is
port
		(
			arn			:	in std_logic;
			clk			:	in std_logic;
			inld		:	in std_logic;
			inbyte		:	in std_logic_vector(7 downto 0);
			outunld		:	in std_logic;
			
			dav			:	out std_logic;
			dirty		:	out std_logic;
			ovrrun		:	out std_logic;
			outbyte		:	out std_logic_vector(7 downto 0)
		);
end ftfifo;

architecture rtl of ftfifo is

signal	bytewaiting,full		:	std_logic;
signal	reg0,reg1,reg2,reg3		:	std_logic_vector(7 downto 0);
signal	regflags				:	std_logic_vector(3 downto 0);

begin

ftfifodo	:	process(arn, clk)
begin
		if(arn = '0') then
			reg0 <= "00000000";
			reg1 <= "00000000";
			reg2 <= "00000000";
			reg3 <= "00000000";
			regflags <= "0000";
			bytewaiting <= '0';
			dav <= '0';
			ovrrun <= '0';
		elsif(clk'event) and (clk = '1') then
			dav <='0';
			if(full = '1') and (inld = '1') then
				ovrrun <= '1';
			end if;
			if(bytewaiting = '0') and (inld = '1') and (full = '0') then
				bytewaiting <= '1';
			end if;
			if(outunld = '1') and (regflags(3) = '1') then
				ovrrun <= '0';
				regflags(3) <= '0';
			elsif(regflags(3) = '0') and (regflags(2) = '1') then
				dav <= '1';
				reg3 <= reg2;
				regflags(3) <= '1';
				regflags(2) <= '0';
			elsif(regflags(2) = '0') and (regflags(1) = '1') then
				reg2 <= reg1;
				regflags(2) <= '1';
				regflags(1) <= '0';	
			elsif(regflags(1) = '0') and (regflags(0) = '1') then
				reg1 <= reg0;
				regflags(1) <= '1';
				regflags(0) <= '0';		
			elsif(regflags(0) = '0') and (bytewaiting = '1') then
				reg0 <= inbyte;
				regflags(0) <= '1';
				bytewaiting <= '0';
			end if;
		end if;
end process ftfifodo;

full <= regflags(3) and regflags(2) and regflags(1) and regflags(0);
dirty <= regflags(3) or regflags(2) or regflags(1) or regflags(0);
outbyte <= reg3;

end rtl;
			
				
				
			
				
	

			
			