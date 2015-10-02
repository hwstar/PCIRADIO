--
-- pciradio.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
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
--

-- I/O Map
-- 
--	Addr			Read						Write
--	0				MX_828_status_ch0			MX_828_address
--	1				MX_828_status_ch1			MX_828_first_byte/Xilinx programming
--	2				MX_828_status_ch2			MX_828 second byte
--	3				MX_828_status_ch3			MX_828_command
--	4				Uart Receive Data			Uart Transmit Data
--	5				-							-
--	6				-							-
--	7				-							-
--	8				UIO_AB						UIO_AB
--	9				COR							LED control
--	A				TEST/PTT					TEST/PTT
--	B				RBS_Bytes_Queued			RBS_Cmd
--	C				General_Status				RBS_Data
--	D				IRQ_mask					IRQ_mask
--	E				Control1 					Control1
--	F				Control2					Control2 

--
--	*** Control1 ***
--

--	Read/Write
--
--	7		6		5		4		3		2		1		0
--	UIOBD3	UIOBD2	UIOBD1	UIOBD0	UIOAD3	UIOAD2	UIOAD1	UIOAD0
--
--	This register controls the direction of the UIOA and UIOB ports.
--	Writing a 0 sets the port bit as an output, writing a 1 sets the
--  port bit as an input. 
--
--	This register is cleared at power up.	


--
--	*** Control2 ***
--

--	Read/Write
--
--	7		6		5		4		3		2		1		0
--	SERSEL1	SERSEL0	SERC1	SERC0	TESTD3	TESTD2	TESTD1	TESTD0
--
--	This register controls the direction of the TEST port, and assigns the
--	remote base serializer to a specific channel.
--
--	SERSEL[1:0]
--
--  Select which serializer to use:
--
--	00	-	None
--	01	-	RBI
--	10	-	UART
--	11	-	Reserved for future use
--	
--
--	SERC[1:0]
--	Select the channel to assign the remote base serializer to using
--	the following truth table:
--
--	00	-	Channel 0
--	01	-	Channel	1
--	10	-	Channel 2
--	11	-	Channel 3
--
--	To use the remote base serializer on a given channel, that channel must
--	have both its UIOA and UIOB direction bits set as output (0), and preferably
--	have 0's programmed into the output register to prevent false clocking, if 
--	the serializer is dynamically shared between channels.
--
--
--	TESTD[3:0]
--
--	Writing a 0 sets the port bit as an output, writing a 1 sets the
--  port bit as an input. This register is cleared at power up.	
--
--	This register is cleared at power up.

--
--  *** USTAT/COR ***
--


--	7		6		5		4		3		2		1		0
--	UTXBUSY	UOVRRUN	UDIRTY	UDAV	COR3	COR2	COR1	COR0
--
--
-- These bits reflect the state of the UART and of the cor lines.
--

--
--	*** General Status ***
--

-- Read only
--
--	7		6		5		4		3		2		1		0
--	INT		IMX828	RBSDN	PLSDN	-		TXWTRIP	RBSBSY	PLSBSY
--
--
--
--	INT		-	State of the interrupt line prior to reading this register
--	IMX828	-	Reflects the state of the MX828 wire-or interrupt 
--	PLSDN	-	Set to 1 when a command to the PL serializer completes
--	RBSDN	-	Set to 1 when a command to the remote base serializer completes
--	TXWTRIP	-	Set when the PTT's get inhibited by the TX watchdog
--	RBSBSY	-	Set to 1 when the remote serializer is busy
--	PLSBSY	-	Set to 1 when the PL serializer is busy

--
-- To clear RBSDN and PLSDN, see the IRQ mask register.
--
--
--
--	*** IRQ mask ***
--

--	Read/Write
--
--	7		6		5		4		3		2		1		0
--	MASTERM	-		-		-		-		MMX828	MRBS	MPLS
--
-- MASTERM	-	Master mask. Masks the IRQ line when set to 1.
-- MPLS		-	Masks the MX828 serializer completion interrupt
-- MRBS 	-	Masks the RBS serializer completion interrupt
-- MMX828	-	Masks the wire-or MX828 chip interrupt pins
--
-- Mask = 1, Unmask = 0
-- This register will be set to 10000111 on power up
--
-- Interrupts will be generated for the following events:
--
-- High-to-low transition of the PLSBSY status bit (edge)
-- High-to-low transition of the RBSBSY status bit (edge)
-- When the IMX828 status bit is set (level).
--
-- When the PLSDN or or RBSDN bits are set in the status
-- register and you wish to clear them, you must mask then
-- unmask them to clear them.
--

--
--
--	*** LED control ***
--

--  Write only
--
--	7		6		5		4		3		2		1		0
--	LED31	LED30	LED21	LED20	LED11	LED10	LED01	LED00

--	Where LEDx1 and LEDx0 are a truth table of:
--
--	00	-	LED off
--	01	-	LED green
--	10	-	LED red
--	11	-	LED yellow
--
--	This register will be cleared on power up

--
--	*** MX828 address ***
--

-- Write only

--	7		6		5		4		3		2		1		0
--	-		-		-		-		-		FREEZE		MXA1	MXA0

-- This is the address used to select a particular MX828 device
-- to issue a command to. This address doubles as the address used
-- to program the Xilinx at initialization.

-- The freeze bit is used to freeze the status update to the 4 MX828 status
-- registers. Once the status has been read, the freeze bit should be cleared.
--
-- Important: the freeze bit must be set and unset periodically to reset the
-- TX watchdog. the TX watchdog will time out in 100 milliseconds if there is no
-- freeze/unfreeze activity present.

--
--	*** MX828_command ***
--
--	Write only
--
--	Command code to send to MX828
--	Refer to the MX828 data sheet
--

-- Writing to this address starts the MX828 command serializer.

--
--	*** MX828_first_byte ***
--

--	Write only
--
--	First data byte sent to MX828, also doubles as Xilinx programming write location.
--	Refer to the MX828 data sheet.
--

--
--	*** MX828_status_ch0 ***
--  *** MX828_status_ch1 ***
--  *** MX828_status_ch2 ***
--  *** MX828_status_ch3 ***
--

--	Read only
--
--	Byte of data returned when MX828 read commands ar executed
--	Refer to the MX828 data sheet

--
--	*** MX828_second_byte ***
--

--	Write only
--
--	Second data byte sent to MX828.
--	Refer to the MX828 data sheet
--

--
--	*** TEST/PTT ***
--

--	Read/Write
--
--	7		6		5		4		3		2		1		0
--
--	TEST3	TEST2	TEST1	TEST0	PTT3	PTT2	PTT1	PTT0
--
-- Write a 1 to set PTT, 0 to clear PTT.
-- Write 1 1 to set a test bit, and a 0 to clear a test bit
-- This register will be cleared on power up. 

--
--	*** RBS_Bytes_Queued ***
--

-- Read only
--
--	7		6		5		4		3		2		1		0
--
--	-		-		-		-		-		BQ2		BQ1		BQ0

--	Indicates number of remote base serializer bytes queued in fifo (up to 6)
--	This register will be cleared on power up.


--
-- 	*** RBS_Cmd ***
--

-- 	Write only
--
-- 	0x00			- Clear Queue
-- 	0x01			- Send bytes

--
-- 	*** RBS_Data ***
--

--	Write only
--
--	Writing a byte to this register places it into the serializer FIFO.
--	The FIFO can hold up to 6 bytes
--

--
--	*** UIO_AB ***
--

--	Read/Write
--
--	7		6		5		4		3		2		1		0
--	UIOB3	UIOB2	UIOB1	UIOB0	UIOA3	UIOA2	UIOA1	UIOA0
--
-- This register will be cleared on power up.



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pciradio is
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
				csbn_mx828	:	out std_logic_vector(3 downto 0); -- low-true chip selects to MX828's
				pttn		:	out std_logic_vector(3 downto 0); -- low-true PTT outputs
				led0		:	out std_logic_vector(1 downto 0); -- LED for channel 0
				led1		:	out std_logic_vector(1 downto 0); -- LED for channel 1
				led2		:	out std_logic_vector(1 downto 0); -- LED for channel 2
				led3		:	out std_logic_vector(1 downto 0)  -- LED for channel 3
			);
end pciradio;
				

architecture rtl of pciradio is


signal	busy_mx828			:	std_logic;
signal	rd					:	std_logic;
signal	clk					:	std_logic;
signal	cmdsel_mx828		:	std_logic;
signal	fbsel_mx828			:	std_logic;
signal	sbsel_mx828			:	std_logic;
signal	adsel_mx828			:	std_logic;
signal	sel_uio				:	std_logic;
signal	sel_testptt			:	std_logic;
signal	sel_ctrl1			:	std_logic;
signal	sel_ctrl2			:	std_logic;
signal	sel_leds			:	std_logic;
signal	sel_irqmask			:	std_logic;
signal	sel_uarttx			:	std_logic;
signal	ledpwm				:	std_logic;
signal	rbs_regsel			:	std_logic;
signal	rbs_cmdsel			:	std_logic;
signal	rbsclk				:	std_logic;
signal	rbsdata				:	std_logic;
signal	rbs_busy			:	std_logic;
signal	irq_mx828			:	std_logic;
signal	mxaccess			:	std_logic;
signal	tjirqint			:	std_logic;


signal	rbs_bq				:	std_logic_vector(2 downto 0);
signal	csb_mx828			:	std_logic_vector(3 downto 0);
signal	stat_mx8280			:	std_logic_vector(7 downto 0);
signal	stat_mx8281			:	std_logic_vector(7 downto 0);
signal	stat_mx8282			:	std_logic_vector(7 downto 0);
signal	stat_mx8283			:	std_logic_vector(7 downto 0);
signal	uart_rxdata			:	std_logic_vector(7 downto 0);
signal	uioin				:	std_logic_vector(7 downto 0);
signal	uioout				:	std_logic_vector(7 downto 0);
signal	testpttin			:	std_logic_vector(7 downto 0);
signal	testpttout			:	std_logic_vector(7 downto 0);
signal	wdb					:	std_logic_vector(7 downto 0);
signal	rdb					:	std_logic_vector(7 downto 0);
signal	statusreg			:	std_logic_vector(7 downto 0);
signal	ctrlout1			:	std_logic_vector(7 downto 0);
signal	ctrlout2			:	std_logic_vector(7 downto 0);
signal	corbits				:	std_logic_vector(7 downto 0);
signal	irqmaskbits			:	std_logic_vector(7 downto 0);



		
component	mx_seq
	port
			(
				signal	arn			:	in std_logic;
				signal	clk			:	in std_logic;
				signal	from_mx828	:	in std_logic;
				signal	wrn			:	in std_logic;
				signal	cmdsel		:	in std_logic;
				signal	fbsel		:	in std_logic;
				signal	sbsel		:	in std_logic;
				signal	adsel		:	in std_logic;
				signal	wdb			:	in std_logic_vector(7 downto 0);
				
				signal	busy		:	out std_logic;
				signal	to_mx828	:	out std_logic;
				signal	clk_mx828	:	out std_logic;
				signal	mxaccess	:	out std_logic;
				signal	csb_mx828	:	out std_logic_vector(3 downto 0);
				signal	stat_mx8280	:	out std_logic_vector(7 downto 0);
				signal	stat_mx8281	:	out std_logic_vector(7 downto 0);
				signal	stat_mx8282	:	out std_logic_vector(7 downto 0);
				signal	stat_mx8283	:	out std_logic_vector(7 downto 0)
			);
end component;




component	io
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
end component;

component frame
	port
		(
			arn		:	in std_logic;
			clk		:	in std_logic;
			
			clk2048	:	out std_logic;
			tjfsc	:	out std_logic;
			ledpwm	:	out std_logic;
			fsync	:	out std_logic_vector(3 downto 0)
		);
end component;

component	rbs
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
end component;

begin			
				
mxseq_i	:	mx_seq
	port map
			(
				arn => arn,
				clk => clk,
				from_mx828 => from_mx828,
				wrn => wrn,
				cmdsel => cmdsel_mx828,
				fbsel => fbsel_mx828,
				sbsel => sbsel_mx828,
				adsel => adsel_mx828,
				wdb => wdb,
				
				busy => busy_mx828,
				to_mx828 => to_mx828,
				clk_mx828 => clk_mx828,
				csb_mx828 => csb_mx828,
				mxaccess => mxaccess,
				stat_mx8280 => stat_mx8280,
				stat_mx8281 => stat_mx8281,
				stat_mx8282 => stat_mx8282,
				stat_mx8283 => stat_mx8283			
			);

			
io_i	:	io
	port map
			(
				arn => arn,
				clk => clk,
				wrn => wrn,
				rd => rd,
				sel_uio => sel_uio,
				sel_testptt => sel_testptt,
				sel_ctrl1 => sel_ctrl1,
				sel_ctrl2 => sel_ctrl2,
				sel_leds => sel_leds,
				sel_irqmask => sel_irqmask,
				sel_uarttx => sel_uarttx,
				rbsclk => rbsclk,
				rbsdata => rbsdata,
				irq_mx828 => irq_mx828,
				ledpwm => ledpwm,
				rbs_busy => rbs_busy,
				busy_mx828 => busy_mx828,
				mxaccess => mxaccess,
				uioinlsb => uioin(3 downto 0),
				cor	=> cor,
				
				wdb => wdb,
				
				tjirq => tjirqint,
				led0 => led0,
				led1 => led1,
				led2 => led2,
				led3 => led3,
				uioout => uioout,
				testpttout => testpttout,
				ctrlout1 => ctrlout1,
				ctrlout2 => ctrlout2,
				statusreg => statusreg,
				corbits => corbits,
				irqmaskbits => irqmaskbits,
				uart_rxdata => uart_rxdata
			);

frame_i	:	frame
	port map
			(
				arn => arn,
				clk => clk,
				
				clk2048 => clk2048,
				tjfsc => tjfsc,
				ledpwm => ledpwm,
				fsync => fsync
			);
			
rbs_i	:	rbs
	port map
			(
				arn => arn,
				clk => clk,
				wrn => wrn,
				regsel => rbs_regsel,
				cmdsel => rbs_cmdsel,
				wdb => wdb,
				
				rbsclk => rbsclk,
				rbsdata => rbsdata,
				busy => rbs_busy,
				bq => rbs_bq
			);			
			
-- multiplex all read ports

rd_mux	:	process( ha, stat_mx8280, stat_mx8281, stat_mx8282, stat_mx8283,
			testpttin, uioin, ctrlout1, ctrlout2, rbs_bq, statusreg, corbits, irqmaskbits, uart_rxdata) 
begin

	case ha is
		when "0000" =>
			rdb <= stat_mx8280;
		when "0001" =>
			rdb <= stat_mx8281;
		when "0010" =>
			rdb <= stat_mx8282;
		when "0011" =>
			rdb <= stat_mx8283;
		when "0100" =>
			rdb	<= uart_rxdata;
		when "1000" =>
			rdb <= uioin;
		when "1001" =>
			rdb <= corbits;
		when "1010" =>
			rdb <= testpttin;
		when "1011" =>
			rdb <= "00000" & rbs_bq;	
		when "1100" =>
			rdb <= statusreg;
		when "1101" =>
			rdb <= irqmaskbits;
		when "1110" =>
			rdb <= ctrlout1;
		when "1111" =>
			rdb <= ctrlout2;		
		when others =>
			rdb <= "00000000";
	end case;
end process rd_mux;	
	
-- decode individual  selects

sel_dec	:	process(ha)
begin
	cmdsel_mx828 <= '0';
	fbsel_mx828 <= '0';
	sbsel_mx828 <= '0';
	adsel_mx828 <= '0';
	sel_uio <= '0';
	sel_testptt <= '0';
	sel_ctrl1 <= '0';
	sel_ctrl2 <= '0';
	sel_irqmask <= '0';
	sel_uarttx <= '0';
	sel_leds <= '0';
	rbs_regsel <= '0';
	rbs_cmdsel <= '0';
	
	
	case ha is
		when "0000" =>
			adsel_mx828 <= '1';
		when "0001" =>
			fbsel_mx828 <= '1';
		when "0010" =>
			sbsel_mx828 <= '1';
		when "0011" =>
			cmdsel_mx828 <= '1';
		when "0100" =>
			sel_uarttx <= '1';
		when "1000" => 
			sel_uio <= '1';
		when "1001" =>
			sel_leds <= '1';
		when "1010" => 
			sel_testptt <= '1';
		when "1011" =>
			rbs_cmdsel <= '1';
		when "1100" =>
			rbs_regsel <= '1';
		when "1101" =>
			sel_irqmask <= '1';		
		when "1110" =>
			sel_ctrl1 <= '1';
		when "1111" =>
			sel_ctrl2 <= '1';
			
		
		when others =>
			null;
	end case;
end process sel_dec;


--
-- concurrent statements
--

clk <= clko_tj;

rd <= not rdn;

irq_mx828 <= not irqn_mx828;


-- data bus bidirect
hd <= rdb when rd = '1' and wrn = '1' else "ZZZZZZZZ"; -- drive data bus on rd active; don't drive the bus during a reset
wdb <= hd;

-- interrupt tristate driver

tjirq <= 'Z';


-- implement tristate control for bidirects
GEN_testhdr	:	for I in 0 to 3 generate
	testhdr(I) <= testpttout(I+4) when ctrlout2(I) = '0' else 'Z';
end generate GEN_testhdr;

GEN_uioa	:	for I in 0 to 3 generate
	uioa(I) <= uioout(I) when ctrlout1(I) = '0' else 'Z';
end generate GEN_uioa;


GEN_uiob	:	for I in 0 to 3 generate
	uiob(I) <= uioout(I+4) when ctrlout1(I+4) = '0' else 'Z';
end generate GEN_uiob;


uioin <= uiob(3 downto 0) & uioa(3 downto 0);
testpttin <= testhdr(3 downto 0) & testpttout(3 downto 0);
	
-- invert outputs which need to be
csbn_mx828 <= not csb_mx828;
pttn <= not testpttout(3 downto 0);


end rtl;








		
			

			
		
			
				
				