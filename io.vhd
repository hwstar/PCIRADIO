--
-- io.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
-- Author: Stephen A. Rodgers
--
-- Copyright (c) 2004,2005 Stephen A. Rodgers
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

entity io is
	port
			(
				arn			:	in std_logic;
				clk			:	in std_logic;
				wrn			:	in std_logic;
				rd			:	in std_logic;
				sel_uio		:	in std_logic;
				sel_testptt	:	in std_logic;
				sel_ctrl1	:	in std_logic;
				sel_ctrl2	:	in std_logic;
				sel_leds	:	in std_logic;
				sel_irqmask	:	in std_logic;
				sel_uarttx	:	in std_logic;
				rbsclk		:	in std_logic;
				rbsdata		:	in std_logic;
				irq_mx828	:	in std_logic;
				ledpwm		:	in std_logic;
				rbs_busy	:	in std_logic;
				busy_mx828	:	in std_logic;
				mxaccess	:	in std_logic;
				uioinlsb	:	in std_logic_vector(3 downto 0);
				cor			:	in std_logic_vector(3 downto 0);
				wdb			:	in std_logic_vector(7 downto 0);
				
				tjirq		:	out std_logic;
				led0		:	out std_logic_vector(1 downto 0);
				led1		:	out std_logic_vector(1 downto 0);
				led2		:	out std_logic_vector(1 downto 0);
				led3		:	out std_logic_vector(1 downto 0);
				uioout		:	out std_logic_vector(7 downto 0);
				testpttout	:	out std_logic_vector(7 downto 0);
				ctrlout1	:	out std_logic_vector(7 downto 0);
				ctrlout2	:	out std_logic_vector(7 downto 0);
				statusreg	:	out std_logic_vector(7 downto 0);
				corbits		:	out std_logic_vector(7 downto 0);
				irqmaskbits	:	out std_logic_vector(7 downto 0);
				uart_rxdata	:	out std_logic_vector(7 downto 0)
			);
			
end io;

architecture rtl of io is

signal	irqsum	:	std_logic;
signal	rxd		:	std_logic;
signal	txd		:	std_logic;
signal	ovrrun	:	std_logic;
signal	dirty	:	std_logic;
signal	dav		:	std_logic;
signal	txgo	:	std_logic;
signal	txdone	:	std_logic;
signal	txbusy	:	std_logic;
signal	bce9600	:	std_logic;
signal	txwdtrip:	std_logic;
signal	rxba	:	std_logic;
signal	leds2	:	std_logic_vector(1 downto 0);
signal	txgosync:	std_logic_vector(2 downto 0);
signal	rdsuart	:	std_logic_vector(2 downto 0);
signal	wdptts	:	std_logic_vector(3 downto 0);	
signal	irqmbits:	std_logic_vector(3 downto 0);
signal	plsdone :	std_logic_vector(3 downto 0);
signal	rbsdone :	std_logic_vector(3 downto 0);
signal	leds4	:	std_logic_vector(3 downto 0);
signal	davshift:	std_logic_vector(4 downto 0);
signal	leds6	:	std_logic_vector(5 downto 0);
signal	uarttx	:	std_logic_vector(7 downto 0);
signal	ledport	:	std_logic_vector(7 downto 0);
signal	ledctrl	:	std_logic_vector(7 downto 0);
signal	ledsync	:	std_logic_vector(7 downto 0);
signal	uiobits	:	std_logic_vector(7 downto 0);
signal	ctrl2	:	std_logic_vector(7 downto 0);

component	tinyuart
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
end component;

component	txwdog
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
end component;


begin

mtinyuart	:	tinyuart
port map
			(
				arn => arn,
				clk => clk,
				txgo => txgo,
				rxrd => rdsuart(2),
				rxd => rxd,
				txdata => uarttx,
				
				ovrrun => ovrrun,
				dirty => dirty,
				dav => dav,
				txdone => txdone,
				txd => txd,
				bce9600 => bce9600,
				rxdata => uart_rxdata
			);
			

mtxwdog		:	txwdog
port map
			(
				arn => arn,
				clk => clk,
				mxaccess => mxaccess,
				bce9600 => bce9600,
				txwdtrip => txwdtrip,
				pttin => wdptts,
				
				pttout => testpttout(3 downto 0)
			);
		
				
			
uiop	:	process(arn, wrn)
begin
	if(arn = '0') then
		uiobits <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(sel_uio = '1') then
			uiobits <= wdb;
		end if;
	end if;
end process uiop;

testpttp	:	process(arn, wrn)
begin
	if(arn = '0') then
		testpttout(7 downto 4) <= "0000";
		wdptts <= "0000";
	elsif(wrn'event) and (wrn = '1') then
		if(sel_testptt = '1') then
			testpttout(7 downto 4) <= wdb(7 downto 4);
			wdptts <= wdb(3 downto 0);
		end if;
	end if;
end process testpttp;		

ledp	:	process(arn, wrn)
begin
	if(arn = '0') then
		ledport <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(sel_leds = '1') then
			ledport <= wdb;
		end if;
	end if;
end process	ledp;					

ctrlp1	:	process(arn, wrn)
begin
	if(arn = '0') then
		ctrlout1 <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(sel_ctrl1 = '1') then
			ctrlout1 <= wdb;
		end if;
	end if;
end process ctrlp1;		

ctrlp2	:	process(arn, wrn)
begin
	if(arn = '0') then
		ctrl2 <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(sel_ctrl2 = '1') then
			ctrl2 <= wdb;
		end if;
	end if;
end process ctrlp2;		

irqmrp	:	process(arn, wrn)
begin
	if(arn = '0') then
		irqmbits <= "0000";
	elsif(wrn'event) and (wrn = '1') then
		if(sel_irqmask = '1') then
			irqmbits(2 downto 0) <= not wdb(2 downto 0);
			irqmbits(3) <= not wdb(7);
		end if;
	end if;
end process irqmrp;

-- prevent glitches on tjirq

irqsync	:	process(arn, clk)
begin
	if(arn = '0') then
		tjirq <= '0';
	elsif(clk'event) and (clk = '1') then
		tjirq <= irqsum;
	end if;
end process irqsync;


-- Generate UART unload strobe

rdsynca	:	process(arn, rdsuart, rd)
begin
	if(arn = '0') or (rdsuart(2) = '1') then
		rdsuart(0) <= '0';
	elsif(rd'event) and (rd = '0') then
		if(sel_uarttx = '1') then -- receive register read
			rdsuart(0) <= '1';
		end if;
	end if;
end process rdsynca;


rdsyncb	:	process(arn, clk, rdsuart)
begin
	if(arn = '0') then
		rdsuart(2 downto 1) <= "00";
	elsif(clk'event) and (clk = '1') then
		rdsuart(2) <= rdsuart(1);
		rdsuart(1) <= rdsuart(0);
	end if;
end process rdsyncb;

-- delay dav by 5 clocks 

davshftp	:	process(arn, clk)
begin
	if(arn = '0') then
		davshift <= "00000";
	elsif(clk'event) and (clk = '1') then
		davshift <= davshift(3 downto 0) & dav;
	end if;
end process davshftp;

-- rxba latch

rxbafm		:	process(arn, rd, davshift(4))
begin
	if(arn = '0') then
		rxba <= '0';
	elsif(davshift(4) = '1') then
		rxba <= '1'; -- byte available asynchronously sets
	elsif(rd'event) and (rd = '0') then
		if(sel_uarttx = '1') then -- receive register read
			rxba <= '0'; -- byte available clears on rising edge of rd.
		end if;
	end if;
end process rxbafm;


-- start to generate a load pulse from a tx write

puarttx1	:	process(arn, txgosync(2), wrn)
begin
	if(arn = '0') then
		txgosync(0) <= '0';
	elsif(txgosync(2) = '1') then
		txgosync(0) <= '0';
	elsif(wrn'event) and (wrn = '1') then
		if(sel_uarttx = '1') then
			txgosync(0) <= '1';
		end if;
	end if;
end process puarttx1;

-- set or clear txbusy

puarttx2	:	process(arn, wrn, txdone)
begin
	if(arn = '0') or (txdone = '1') then
		txbusy <= '0';
	elsif(wrn'event) and (wrn = '1') then
		if(sel_uarttx = '1') then
			txbusy <= '1';
		end if;
	end if;
end process puarttx2;
 
		
-- save byte to be transmitted

puarttx3	:	process(arn, wrn)
begin
	if(arn = '0') then
		uarttx <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(sel_uarttx = '1') then
			uarttx <= wdb;
		end if;
	end if;
end process puarttx3;

-- sequence the load pulse for the tx write


puarttx4	:	process(arn, clk)
begin
	if(arn = '0') then
		txgosync(2 downto 1) <= "00";
	elsif(clk'event) and (clk = '1') then
		txgosync(1) <= txgosync(0);
		txgosync(2) <= txgosync(1);
	end if;
end process puarttx4;



-- latch the transition of pl serializer busy from high to low

mxdnp	:	process(arn, clk)
begin
	if(arn = '0') then
		plsdone(2 downto 0) <= "000";
	elsif(clk'event) and (clk = '1') then
		plsdone(1) <= plsdone(0);
		plsdone(0) <= busy_mx828;
		if( irqmbits(0) = '0') then
			plsdone(2) <= '0';
		elsif(plsdone(3) = '1') then
			plsdone(2) <= '1';
		end if;
	end if;
end process mxdnp;

-- latch the transition of remote serializer busy from high to low

rbdnp	:	process(arn, clk)
begin
	if(arn = '0') then
		rbsdone(2 downto 0) <= "000";
	elsif(clk'event) and (clk = '1') then
		rbsdone(1) <= rbsdone(0);
		rbsdone(0) <= rbs_busy;
		if(irqmbits(1) = '0') then
			rbsdone(2) <= '0';
		elsif(rbsdone(3) = '1') then
			rbsdone(2) <= '1';
		end if;
	end if;
end process rbdnp;


-- handle status led modulation

ledmod	: process(ledpwm, ledport)
begin
	case ledport(1 downto 0) is
		when "00" =>
			ledctrl(1 downto 0) <= "00";
		when "01" =>
			ledctrl(1 downto 0) <= "01";
		when "10" =>
			ledctrl(1 downto 0) <= "10";
		when "11" =>
			ledctrl(0) <= ledpwm;
			ledctrl(1) <= not ledpwm;
		when others =>
			ledctrl(1 downto 0) <= "00";
	end case;
	
	case ledport(3 downto 2) is
		when "00" =>
			ledctrl(3 downto 2) <= "00";
		when "01" =>
			ledctrl(3 downto 2) <= "01";
		when "10" =>
			ledctrl(3 downto 2) <= "10";
		when "11" =>
			ledctrl(2) <= ledpwm;
			ledctrl(3) <= not ledpwm;
		when others =>
			ledctrl(3 downto 2) <= "00";
	end case;
	
	
	case ledport(5 downto 4) is
		when "00" =>
			ledctrl(5 downto 4) <= "00";
		when "01" =>
			ledctrl(5 downto 4) <= "01";
		when "10" =>
			ledctrl(5 downto 4) <= "10";
		when "11" =>
			ledctrl(4) <= ledpwm;
			ledctrl(5) <= not ledpwm;
		when others =>
			ledctrl(5 downto 4) <= "00";
	end case;

	case ledport(7 downto 6) is
		when "00" =>
			ledctrl(7 downto 6) <= "00";
		when "01" =>
			ledctrl(7 downto 6) <= "01";
		when "10" =>
			ledctrl(7 downto 6) <= "10";
		when "11" =>
			ledctrl(6) <= ledpwm;
			ledctrl(7) <= not ledpwm;
		when others =>
			ledctrl(7 downto 6) <= "00";
	end case;	
end process ledmod;

-- skew LED control signals to meet simultaneous switching limitations.

ledskew	:	process(arn, clk)
begin
	if(arn = '0') then
		ledsync <= "00000000";
		leds6 <= "000000";
		leds4 <= "0000";
		leds2 <= "00";
	elsif(clk'event) and (clk = '1') then
		ledsync <= ledctrl;
		leds6 <= ledsync(5 downto 0);
		leds4 <= leds6(3 downto 0);
		leds2 <= leds4(1 downto 0);
	end if;
end process ledskew;

-- map outbut modes to correct uioa/b bit pairs
-- 

outselp	:	process(ctrl2, uiobits, rbsdata, rbsclk, txd, uioinlsb)
begin
	if(ctrl2(7 downto 6) = "01") then -- select RBS on a port.
		rxd <= '1';
		case ctrl2(5 downto 4) is
			when "00" =>
				uioout <= uiobits(7 downto 5) & rbsdata & uiobits(3 downto 1) & rbsclk;
			when "01" =>
				uioout <= uiobits(7 downto 6) & rbsdata & uiobits(4 downto 2) & rbsclk & uiobits(0);
			when "10" =>
				uioout <= uiobits(7) & rbsdata & uiobits(5 downto 3) & rbsclk & uiobits(1 downto 0);
			when "11" =>
				uioout <= rbsdata & uiobits(6 downto 4) & rbsclk & uiobits(2 downto 0);
			when others =>
				uioout <= "00000000";
		end case;
	elsif(ctrl2(7 downto 6) = "10") then -- select UART on a port
		case ctrl2(5 downto 4) is
			when "00" =>
				rxd <= uioinlsb(0);
				uioout <= uiobits(7 downto 5) & txd & uiobits(3 downto 1) & '1';
			when "01" =>
				rxd <= uioinlsb(1);
				uioout <= uiobits(7 downto 6) & txd & uiobits(4 downto 2) & '1' & uiobits(0);
			when "10" =>
				rxd <= uioinlsb(2);
				uioout <= uiobits(7) & txd & uiobits(5 downto 3) & '1' & uiobits(1 downto 0);
			when "11" =>
				rxd <= uioinlsb(3);
				uioout <= txd & uiobits(6 downto 4) & '1' & uiobits(2 downto 0);
			when others =>
				rxd <= '1';
				uioout <= "00000000";
		end case;	
	else
		rxd <= '1';
		uioout <= uiobits;
	end if;
end process outselp;


	
--
-- Concurrent statements
--

led0 <= leds2;
led1 <= leds4(3 downto 2);
led2 <= leds6(5 downto 4);
led3 <= ledsync(7 downto 6);
	
ctrlout2 <= ctrl2;

plsdone(3) <= '1' when plsdone(0) = '0' and plsdone(1) = '1' else '0';
rbsdone(3) <= '1' when rbsdone(0) = '0' and rbsdone(1) = '1' else '0';

irqsum <= '1' when irqmbits(3) = '1' and ((irqmbits(2) = '1' and irq_mx828 = '1') or
					(irqmbits(1) = '1' and rbsdone(2) = '1') or
					(irqmbits(0) = '1' and plsdone(2) = '1')) else '0';

-- assemble general status register bits
statusreg <= irqsum & irq_mx828 & rbsdone(2) & plsdone(2) & '0' & txwdtrip & rbs_busy & busy_mx828;
-- assemble cbits for uart status/cor register
corbits <= txbusy & ovrrun & dirty & rxba & cor(3 downto 0);
-- assemble irqmaskbits
irqmaskbits <= not irqmbits(3) & "0000" & not irqmbits(2 downto 0);

txgo <= txgosync(1) and not txgosync(2);
			
end rtl;
	
			