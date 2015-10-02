--
-- mxseq.vhd:	VHDL module for Zapata Telephony PCI Radio Card, Rev. A
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

entity mx_seq is
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
end mx_seq;

architecture rtl of mx_seq is

--
-- signals
--

type mxseq_states is 	(mxs_start, mxs_set_go_auto, mxs_wait_done_auto, mxs_cleanup_auto, 
						mxs_set_go_ucmd, mxs_wait_done_ucmd, mxs_forcecshigh_ucmd, mxs_cleanup_ucmd);

signal	mxseqs_cur	: mxseq_states;
signal	mxseqs_next	: mxseq_states;

signal	go			:	std_logic;
signal	done		:	std_logic;
signal	autostat	:	std_logic;
signal	freezereq	:	std_logic;
signal	freeze		:	std_logic;
signal	ucmdclr		:	std_logic;
signal	cvalid		:	std_logic;
signal	cdata		:	std_logic;
signal	cword		:	std_logic;
signal	crdwrn		:	std_logic;
signal	wait32		:	std_logic;
signal	forcecshigh	:	std_logic;



signal	addrctr		:	std_logic_vector(1 downto 0);
signal	da			:	std_logic_vector(1 downto 0);
signal	dau			:	std_logic_vector(1 downto 0);
signal	ucmdpend	:	std_logic_vector(1 downto 0);

signal	csb			:	std_logic_vector(3 downto 0);

signal	cmd			:	std_logic_vector(7 downto 0);
signal	fb			:	std_logic_vector(7 downto 0);
signal	sb			:	std_logic_vector(7 downto 0);
signal	rdb_mx828	:	std_logic_vector(7 downto 0);
signal	cmdu		:	std_logic_vector(7 downto 0);
signal	dlyctr	:	std_logic_vector(4 downto 0);


--
-- components
--

component mx828
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
end component;


begin

-- port maps

imx828	:	mx828
	port map
			(
				arn => arn,
				clk => clk,
				from_mx828 => from_mx828,
				go => go,
				cdata => cdata,
				cword => cword,
				crdwrn => crdwrn,
				cmd => cmd,
				fb => fb,
				sb => sb,
				
				done => done,
				to_mx828 => to_mx828,
				clk_mx828 => clk_mx828,
				rdb_mx828 => rdb_mx828
			);

--
-- processes
--

-- register a user command

cmdup	:	process(arn, wrn, ucmdclr)
begin
	if(arn = '0') or (ucmdclr = '1') then
		ucmdpend(0) <= '0';
		cmdu <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(cmdsel = '1') then
			ucmdpend(0) <= '1';
			cmdu <= wdb;
		end if;
	end if;
end process cmdup;

-- register the user's first byte

fbp	:	process(arn, wrn)
begin
	if(arn = '0') then
		fb <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(fbsel = '1') then
			fb <= wdb;
		end if;
	end if;
end process fbp;

-- register the user's second byte

sbp	:	process(arn, wrn)
begin
	if(arn = '0') then
		sb <= "00000000";
	elsif(wrn'event) and (wrn = '1') then
		if(sbsel = '1') then
			sb <= wdb;
		end if;
	end if;
end process sbp;

-- register the user's chip select address, and register freeze bit

daup	:	process(arn, wrn)
begin
	if(arn = '0') then
		dau <= "00";
		freezereq <= '0';
	elsif(wrn'event) and (wrn = '1') then
		if(adsel = '1') then
			dau <= wdb(1 downto 0);
			freezereq <= wdb(2);
		end if;
	end if;
end process daup;

-- synchonize freezereq to clock

frzsp	:	process(arn, clk)
begin
	if(arn = '0') then
		freeze <= '0';
	elsif(clk'event) and (clk = '1') then
		freeze <= freezereq;
	end if;
end process frzsp;

-- synchonize user command pending signal
ucsp	:	process(arn, clk)
begin
	if(arn = '0') then
		ucmdpend(1) <= '0';
	elsif(clk'event) and (clk = '1') then
		if(ucmdclr = '1') then
			ucmdpend(1) <= '0';
		else
			ucmdpend(1) <= ucmdpend(0);
		end if;
	end if;
end process ucsp;

		
-- update status register for channel 0

sp0		:	process(arn, clk)
begin
	if(arn = '0') then
		stat_mx8280 <= "00000000";
	elsif(clk'event) and (clk = '1') then
		if(done = '1') and (autostat = '1') and (csb(0) = '1') and (freeze = '0') then
			stat_mx8280 <= rdb_mx828;
		end if;
	end if;
end process sp0;

-- update status register for channel 1

sp1		:	process(arn, clk)
begin
	if(arn = '0') then
		stat_mx8281 <= "00000000";
	elsif(clk'event) and (clk = '1') then
		if(done = '1') and (autostat = '1') and (csb(1) = '1') and (freeze = '0') then
			stat_mx8281 <= rdb_mx828;
		end if;
	end if;
end process sp1;

-- update status register for channel 2

sp2		:	process(arn, clk)
begin
	if(arn = '0') then
		stat_mx8282 <= "00000000";
	elsif(clk'event) and (clk = '1') then
		if(done = '1') and (autostat = '1') and (csb(2) = '1') and (freeze = '0') then
			stat_mx8282 <= rdb_mx828;
		end if;
	end if;
end process sp2;		
		
-- update status register for channel 3

sp3		:	process(arn, clk)
begin
	if(arn = '0') then
		stat_mx8283 <= "00000000";
	elsif(clk'event) and (clk = '1') then
		if(done = '1') and (autostat = '1') and (csb(3) = '1') and (freeze = '0') then
			stat_mx8283 <= rdb_mx828;
		end if;
	end if;
end process sp3;

-- Generate a delay for force CS high function

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


-- make linear bit sequence for chip selects from address bits

makecsp	:	process(da, forcecshigh)
begin
	csb <= "0000";
	if(forcecshigh = '0') then
		case da is
			when "00" =>
				csb(0) <= '1';
			when "01" =>
				csb(1) <= '1';
			when "10" =>
				csb(2) <= '1';
			when "11" =>
				csb(3) <= '1';
			when others =>
				csb <= "0000";
		end case;
	 end if;
end process makecsp;

-- address counter used to read status bytes in a round robin fashion from CTCSS chips

adrctrp	:	process(arn, clk)
begin
	if(arn = '0') then
		addrctr <= "00";
	elsif(clk'event) and (clk = '1') then
		if(autostat = '1') and (done = '1') then
			addrctr <= addrctr + 1;
		end if;
	end if;
end process adrctrp;

-- validate the command on the command bus

cmddec	:	process(cmd)
begin
	
	crdwrn <= '0';
	cword <= '0';
	cdata <= '0';
	cvalid <= '0';
	
	case cmd is
		when	"10000000" => -- 0x80 (8 bit writes)
			cvalid <= '1';
			cdata <= '1';
		when	"10000010" => -- 0x82
			cvalid <= '1';
			cdata <= '1';
		when	"10000101" => -- 0x85
			cvalid <= '1';
			cdata <= '1';
		when	"10000110" => -- 0x86
			cvalid <= '1';
			cdata <= '1';
		when	"10000111" => -- 0x87
			cvalid <= '1';
			cdata <= '1';
		when	"10001000" => -- 0x88
			cvalid <= '1';
			cdata <= '1';
		when	"10001011" => -- 0x8B
			cvalid <= '1';
			cdata <= '1';
		when	"10001110" => -- 0x8E
			cvalid <= '1';
			cdata <= '1';
					
					
		when	"10000011" => -- 0x83 (16 bit writes)
			cvalid <= '1';
			cdata <= '1';
			cword <= '1';				
		when	"10000100" => -- 0x84
			cvalid <= '1';
			cdata <= '1';
			cword <= '1';
		when	"10001010" => -- 0x8A
			cvalid <= '1';
			cdata <= '1';
			cword <= '1';
		when	"10001101" => -- 0x8D
			cvalid <= '1';
			cdata <= '1';
			cword <= '1';
								
					
		when	"10000001" => -- 0x81 (8 bit reads)
			cvalid <= '1';
			cdata <= '1';
			crdwrn <= '1';			
		when	"10001111" => -- 0x8F
			cvalid <= '1';
			cdata <= '1';
			crdwrn <= '1';
					
		when	"00000001" => -- 0x01 (command only)
			cvalid <= '1';
			
		when others =>
			null;
	end case;
end process cmddec;		



-- asynchronous part of state machine
mxseq_async	:	process(done, ucmdpend(1), cvalid, mxseqs_cur, dlyctr)
begin
	go <= '0';
	autostat <= '1';
	ucmdclr <= '0';
	forcecshigh <= '0';
	wait32 <= '0';
	mxseqs_next <= mxs_start;
	

	case mxseqs_cur is
		when mxs_start => -- set state of autostat
			if(ucmdpend(1) = '1') then
				autostat <= '0';
				iF(cvalid = '1') then
					mxseqs_next <= mxs_set_go_ucmd;
				else
					mxseqs_next <= mxs_cleanup_ucmd; -- bad command!
				end if;
			else
				mxseqs_next <= mxs_set_go_auto;
			end if;
		
		when mxs_set_go_auto => -- pulse go to start the serializer
			go <= '1';
			mxseqs_next <= mxs_wait_done_auto;
		
		when mxs_wait_done_auto => -- wait for done from serializer
			if(done = '1') then
				mxseqs_next <= mxs_cleanup_auto;
			else
				mxseqs_next <= mxs_wait_done_auto;
			end if;
			
		when mxs_set_go_ucmd => -- pulse go to start the serializer
			go <= '1';
			autostat <= '0';
			mxseqs_next <= mxs_wait_done_ucmd;
		
		when mxs_wait_done_ucmd => -- wait for done from serializer
			autostat <= '0';
			if(done = '1') then
				mxseqs_next <= mxs_forcecshigh_ucmd;
			else
				mxseqs_next <= mxs_wait_done_ucmd;
			end if;	
			
		when mxs_cleanup_auto => -- wait an extra clock to allow flops to clear
			mxseqs_next <= mxs_start;
		

		when mxs_forcecshigh_ucmd => -- allow CS inactive time for user command to autostat
			wait32 <= '1';
			forcecshigh <= '1';
			if(dlyctr = 31) then
				mxseqs_next <= mxs_cleanup_ucmd;
			else
				mxseqs_next <= mxs_forcecshigh_ucmd;
			end if;
			
		when mxs_cleanup_ucmd => -- clear the user command if it was pending
			ucmdclr <= '1';
			mxseqs_next <= mxs_start;

	end case;
end process mxseq_async;

-- synchronous part of state machine

mxseq_sync	:	process(arn, clk)
begin
	if(arn = '0') then
		mxseqs_cur <= mxs_start;
	elsif(clk'event) and (clk = '1') then
		mxseqs_cur <= mxseqs_next;
	end if;
end process mxseq_sync;

		
-- concurrent statements
busy <= ucmdpend(0);
da <= addrctr when autostat = '1' else dau;
cmd <= "10000001" when autostat = '1' else cmdu;
mxaccess <= freeze;

csb_mx828 <= csb;


end rtl;
