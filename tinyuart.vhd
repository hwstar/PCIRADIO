--
-- tinyuart.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
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
-- Tiny uart for PCI radio card
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tinyuart is
	port
			(
				arn			:	in std_logic;
				clk			:	in std_logic;
				txgo		:	in std_logic;
				rxrd		:	in std_logic;
				rxd			:	in std_logic;
				txdata		:	in std_logic_vector(7 downto 0);
				
				ovrrun		:	out std_logic;
				dirty		:	out	std_logic;
				dav			:	out std_logic;
				txdone		:	out std_logic;
				txd			:	out std_logic;
				bce9600		:	out std_logic;
				rxdata		:	out std_logic_vector(7 downto 0)
			);
end tinyuart;

architecture rtl of tinyuart is

signal	bclken, bclken16	:	std_logic;
signal	rxce,outunld		:	std_logic;
signal	rcvsr				:	std_logic_vector(7 downto 0);
signal	bauddiv16			:	std_logic_vector(3 downto 0);
signal	bauddiv				:	std_logic_vector(4 downto 0);

component	urx
	port
		(
			arn		:	in std_logic;
			clk		:	in std_logic;
			rxd		:	in std_logic;
			bclken16:	in std_logic;
			
			rxce	:	out std_logic;
			rxbyte	:	out std_logic_vector(7 downto 0)
		);
end component;

component utx
	port
		(
			arn		:	in std_logic;
			clk		:	in std_logic;
			bclken	:	in std_logic;
			txgo	:	in std_logic;
			txbyte	:	in std_logic_vector(7 downto 0);
			
			txdone	:	out std_logic;
			txd		:	out std_logic
		);
end component;

component	ftfifo
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
end component;

begin

murx	:	urx
	port map
	(
		arn => arn,
		clk => clk,
		rxd => rxd,
		bclken16 => bclken16,
			
		rxce => rxce,
		rxbyte => rcvsr
	);

mutx	:	utx
	port map
	(
		arn => arn,
		clk => clk,
		bclken => bclken,
		txgo => txgo,
		txbyte => txdata,
		
		txdone => txdone,
		txd => txd
	);
	
mftfifo	:	ftfifo
	port map
	(
		arn => arn,
		clk => clk,
		inld => rxce,
		inbyte => rcvsr,
		outunld => outunld,
		
		ovrrun => ovrrun,
		dav => dav,
		dirty => dirty,
		outbyte => rxdata
	);

-- divide 4.096 MHz clock by 26.6667 (27) to get 16x 9600 baud receive clock enable.

baud16	:	process(arn, clk)
begin
	if(arn = '0') then
		bauddiv <= "00000";
		bclken16 <= '0';
	elsif(clk'event) and (clk = '1') then
		bauddiv <= bauddiv + 1;
		if(bauddiv = 26) then
			bclken16 <= '1';
			bauddiv <= "00000";
		else
			bclken16 <= '0';
		end if;
	end if;
end process baud16;

-- divide receive clock enable by 16 to get the transmit clock enable

baud	:	process(arn,clk)
begin
	if(arn = '0') then
		bauddiv16 <= "0000";
		bclken <= '0';
	elsif(clk'event) and (clk = '1') then
		if(bclken16 = '1') then
			bauddiv16 <= bauddiv16 + 1;
			if(bauddiv16 = "0000") then
				bclken <= bclken16;
			end if;
		else
			bclken <= '0';
		end if;
	end if;
end process baud;

bce9600 <= bclken;
outunld <= rxrd; -- debug only;


end rtl;

	
		

		
		
		
		
		
				

			