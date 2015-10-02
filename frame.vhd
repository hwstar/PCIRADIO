--
-- frame.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
-- Authors: Jim Dixon, Stephen A. Rodgers
--
-- Copyright (c) 2004, Jim Dixon
-- Copyright (c) 2004, Stephen A. Rodgers
--
-- Jim Dixon <jim@lambdatel.com>
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

entity frame is
	port
		(
			arn		:	in std_logic;
			clk		:	in std_logic;
			
			clk2048	:	out std_logic;
			tjfsc	:	out std_logic;
			ledpwm	:	out std_logic;
			fsync	:	out std_logic_vector(3 downto 0)
		);

end frame;

architecture rtl of frame is

--
-- Signals
--


signal	framephase	:	std_logic_vector(8 downto 0);

begin

--
-- Processes
--

-- 9 bit frame phase counter

framectr	:	process(arn, clk)
begin
	if(arn = '0') then
		framephase <= "000000000";
	elsif(clk'event) and (clk = '0') then
		framephase <= framephase + 1;
	end if;
end process framectr;


-- frame phase decoder

framedec	:	process(framephase)
begin
	tjfsc <= '0';
	fsync <= "0000";
	if (framephase = "00000000") then -- is this really ok?
		tjfsc <= '1';
	elsif (framephase = "111111110") then
		fsync <= "0001";
	elsif (framephase = "000001110")then
		fsync <= "0010";
	elsif (framephase = "000011110") then
		fsync <= "0100";
	elsif (framephase = "000101110") then
		fsync <= "1000";
	end if;
end process framedec;
	
--		
-- concurrent statements
--

clk2048 <= not framephase(0);
ledpwm <= framephase(7);

end rtl;


			
