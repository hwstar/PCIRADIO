--
-- pciradio_xilinx.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
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

-- Top level for Xilinx implementation
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity pciradio_xilinx is
	port	(
				arn			:	in std_logic; -- global reset
				clko_tj		:	in std_logic; -- clock from TJ oscillator cell
				from_mx828	:	in std_logic; -- serial data from MX828 chips
				irqn_mx828	:	in std_logic; -- IRQ from MX828
				rdn			:	in std_logic; -- read strobe in from tigerjet
				wrn			:	in std_logic; -- write strobe in from tigerjet
				cor			:	in std_logic_vector(3 downto 0); -- cor status bits in
				ha			:	in std_logic_vector(3 downto 0); -- tigerjet GPIO address bus in
								
				hd			:	inout std_logic_vector(7 downto 0); -- tigerjet GPIO data bus
				testhdr		:	inout std_logic_vector(3 downto 0); -- test header pins
				uioa		:	inout std_logic_vector(3 downto 0); -- uio port a
				uiob		:	inout std_logic_vector(3 downto 0); -- uio port b
				
				clk2048		:	out std_logic; -- 2048 KHz clock out
				tjfsc		:	out std_logic; -- tigerjet frame sync out
				clk_mx828	:	out std_logic; -- serial clock to MX828's
				to_mx828	:	out std_logic; -- serial data to MX828's 
				tjirq		:	out std_logic; -- IRQ to tigerjet
				fsync		:	out std_logic_vector(3 downto 0); -- frame syncs to codecs
				csbn_mx828	:	out std_logic_vector(3 downto 0); -- low chip selects to MX828's
				pttn		:	out std_logic_vector(3 downto 0); -- low-true PTT outputs
				led0		:	out std_logic_vector(1 downto 0); -- LED for channel 0
				led1		:	out std_logic_vector(1 downto 0); -- LED for channel 1
				led2		:	out std_logic_vector(1 downto 0); -- LED for channel 2
				led3		:	out std_logic_vector(1 downto 0)  -- LED for channel 3
			);
end pciradio_xilinx;

architecture struct of pciradio_xilinx is

signal	rdn_fixed	:	std_logic;


component pciradio
	port	(
				arn			:	in std_logic; -- global reset
				clko_tj		:	in std_logic; -- clock from TJ oscillator cell
				from_mx828	:	in std_logic; -- serial data from MX828 chips
				irqn_mx828	:	in std_logic; -- IRQ from MX828
				rdn			:	in std_logic; -- read strobe in from tigerjet
				wrn			:	in std_logic; -- write strobe in from tigerjet
				cor			:	in std_logic_vector(3 downto 0); -- cor status bits in
				ha			:	in std_logic_vector(3 downto 0); -- tigerjet GPIO address bus in
								
				hd			:	inout std_logic_vector(7 downto 0); -- tigerjet GPIO data bus
				testhdr		:	inout std_logic_vector(3 downto 0); -- test header pins
				uioa		:	inout std_logic_vector(3 downto 0); -- uio port a
				uiob		:	inout std_logic_vector(3 downto 0); -- uio port b
				
				clk2048		:	out std_logic; -- 2048 KHz clock out
				tjfsc		:	out std_logic; -- tigerjet frame sync out
				clk_mx828	:	out std_logic; -- serial clock to MX828's
				to_mx828	:	out std_logic; -- serial data to MX828's 
				tjirq		:	out std_logic; -- IRQ to tigerjet
				fsync		:	out std_logic_vector(3 downto 0); -- frame syncs to codecs
				csbn_mx828	:	out std_logic_vector(3 downto 0); -- low chip selects to MX828's
				pttn		:	out std_logic_vector(3 downto 0); -- low-true PTT outputs
				led0		:	out std_logic_vector(1 downto 0); -- LED for channel 0
				led1		:	out std_logic_vector(1 downto 0); -- LED for channel 1
				led2		:	out std_logic_vector(1 downto 0); -- LED for channel 2
				led3		:	out std_logic_vector(1 downto 0)  -- LED for channel 3
			);
end component;

component ibufg
	port
		(
			i	:	in std_logic;
			o	:	out std_logic
		);
end component;


begin

ipciradio	:	pciradio
	port map
		(
			arn => arn,
			clko_tj => clko_tj,
			from_mx828 => from_mx828,
			irqn_mx828 => irqn_mx828,
			rdn => rdn_fixed,
			wrn => wrn,
			cor => cor,
			ha => ha,
			
			hd => hd,
			testhdr => testhdr,
			uioa => uioa,
			uiob => uiob,
			
			clk2048 => clk2048,
			tjfsc => tjfsc,
			clk_mx828 => clk_mx828,
			to_mx828 => to_mx828,
			tjirq => tjirq,
			fsync => fsync,
			csbn_mx828 => csbn_mx828,
			pttn => pttn,
			led0 => led0,
			led1 => led1,
			led2 => led2,
			led3 => led3
		);

ibufgrdn	:	ibufg
	port map
		(
			i => rdn,
			o => rdn_fixed
		);
		
			
end struct;
