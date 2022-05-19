------------------------------------------------------------------
--Copyright 2022 Andrey S. Ionisyan (anserion@gmail.com)
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--    http://www.apache.org/licenses/LICENSE-2.0
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.
------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Engineer: Andrey S. Ionisyan <anserion@gmail.com>
-- 
-- Description: neural network filter supervisor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_signed.all;

entity neural_triple_cpu is
    Port ( 
		clk           : in std_logic;
      pixel_in_addr : out std_logic_vector(15 downto 0);
      pixel_in      : in std_logic_vector(7 downto 0);
      pixel_out_addr: out std_logic_vector(15 downto 0);
      pixel_out     : out std_logic_vector(7 downto 0)
	 );
end neural_triple_cpu;

architecture XC7A100T of neural_triple_cpu is
constant n_L1:natural range 1 to 16 := 2;
constant n_L2:natural range 1 to 16 := 2;
constant n_L3:natural range 1 to 16 := 14;
constant W_WIDTH:natural range 1 to 16:=10;

COMPONENT RAM_2NxM_2out is
    generic (N:natural range 1 to 16:=0; M:natural range 1 to 32:=8);
    port (CLK : in std_logic;
          WE  : in std_logic_vector(0 downto 0);
          ADDR: in std_logic_vector(N-1 downto 0);
          DIN : in std_logic_vector(M-1 downto 0);
          ADDR1: in std_logic_vector(N-1 downto 0);
          DOUT1: out std_logic_vector(M-1 downto 0);
          ADDR2: in std_logic_vector(N-1 downto 0);
          DOUT2: out std_logic_vector(M-1 downto 0)
    );
END COMPONENT;

COMPONENT RAM_2NxM_2in_2out is
    generic (N:natural range 1 to 16:=0; M:natural range 1 to 32:=8);
    port (CLK  : in std_logic;
          WEA  : in std_logic_vector(0 downto 0);
          WEB  : in std_logic_vector(0 downto 0);
          ADDRA: in std_logic_vector(N-1 downto 0);
          DINA : in std_logic_vector(M-1 downto 0);
          DOUTA: out std_logic_vector(M-1 downto 0);
          ADDRB: in std_logic_vector(N-1 downto 0);
          DINB : in std_logic_vector(M-1 downto 0);
          DOUTB: out std_logic_vector(M-1 downto 0)
    );
end COMPONENT;

--scale src-target components and signals
COMPONENT image_2Nx2N_scale_down is
   Generic (N:natural range 1 to 16:=8);
    Port ( 
		clk     : in std_logic;
      pixel_in_addr: out std_logic_vector(2*N-1 downto 0);
      pixel_in : in std_logic_vector(7 downto 0);
      addr_out : out std_logic_vector(2*N-3 downto 0);
      pixel_out: out std_logic_vector(7 downto 0)
	 );
END COMPONENT;

COMPONENT image_2Nx2N_scale_up is
   Generic (N:natural range 1 to 16:=8);
    Port ( 
		clk     : in std_logic;
      addr_in : out std_logic_vector(2*N-1 downto 0);
      pixel_in: in std_logic_vector(7 downto 0);
      pixel_out_addr  : out std_logic_vector(2*N+1 downto 0);
      pixel_out : out std_logic_vector(7 downto 0)
	 );
END COMPONENT;

signal source_rd_addr: std_logic_vector(n_L3-1 downto 0):=(others=>'0');
signal source_rd_value: std_logic_vector(7 downto 0):=(others=>'0');
signal target_rd_addr: std_logic_vector(n_L3-1 downto 0):=(others=>'0');
signal target_rd_value: std_logic_vector(7 downto 0):=(others=>'0');
signal scale_down_wr_addr: std_logic_vector(n_L3-1 downto 0):=(others=>'0');
signal scale_down_wr_value: std_logic_vector(7 downto 0):=(others=>'0');

---------------------------------------
-- forward steps neural Layer component
---------------------------------------
COMPONENT neural_layer_2Nx2M_forward is
   Generic (N:natural range 1 to 16:=2;
            M:natural range 1 to 16:=2;
            W_WIDTH:natural range 1 to 16:=8
            );
    Port ( 
		clk     : in std_logic;
      X_addr  : out std_logic_vector(N-1 downto 0);
      X_value : in std_logic_vector(7 downto 0);
      A_addr  : out std_logic_vector(M-1 downto 0);
      A_value : out std_logic_vector(7 downto 0);
      W_cwr     : out std_logic;
      W_addr  : out std_logic_vector(N+M-1 downto 0);
      W_rd_value : in std_logic_vector(W_WIDTH-1 downto 0);
      W_wr_value : out std_logic_vector(W_WIDTH-1 downto 0)    
	 );
END COMPONENT;

--------------------------------------------------
-- neural network Back Propagation Error component
--------------------------------------------------
COMPONENT neural_network_bpe is
   Generic (n_L1: natural range 1 to 16:=2;
            n_L2: natural range 1 to 16:=2;
            n_L3: natural range 1 to 16:=14;
            W_WIDTH:natural range 1 to 16:=8
           );
   Port ( 
		clk : in std_logic;
      L1_rd_addr : out std_logic_vector(n_L1-1 downto 0);
      L1_rd_value: in std_logic_vector(7 downto 0);
      L2_rd_addr : out std_logic_vector(n_L2-1 downto 0);
      L2_rd_value: in std_logic_vector(7 downto 0);
      L3_rd_addr : out std_logic_vector(n_L3-1 downto 0);
      L3_rd_value: in std_logic_vector(7 downto 0);
      Target_rd_addr  : out std_logic_vector(n_L3-1 downto 0);
      Target_rd_value : in std_logic_vector(7 downto 0);
      W1_cwr   : out std_logic;
      W1_addr  : out std_logic_vector(n_L3+n_L1-1 downto 0);
      W1_rd_value : in std_logic_vector(W_WIDTH-1 downto 0);
      W1_wr_value : out std_logic_vector(W_WIDTH-1 downto 0);
      W2_cwr   : out std_logic;
      W2_addr  : out std_logic_vector(n_L1+n_L2-1 downto 0);
      W2_rd_value : in std_logic_vector(W_WIDTH-1 downto 0);
      W2_wr_value : out std_logic_vector(W_WIDTH-1 downto 0);
      W3_cwr   : out std_logic;
      W3_addr  : out std_logic_vector(n_L2+n_L3-1 downto 0);
      W3_rd_value : in std_logic_vector(W_WIDTH-1 downto 0);
      W3_wr_value : out std_logic_vector(W_WIDTH-1 downto 0)
	 );
END COMPONENT;

--Layer 1 signals
signal L1_w_cwr_init : std_logic:='0';
signal L1_w_addr_forward : std_logic_vector(n_L1+n_L3-1 downto 0):=(others=>'0');
signal L1_w_rd_value_forward: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');
signal L1_w_wr_value_init: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');

signal L1_w_cwr_bpe: std_logic:='0';
signal L1_w_addr_bpe : std_logic_vector(n_L1+n_L3-1 downto 0):=(others=>'0');
signal L1_w_rd_value_bpe: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');
signal L1_w_wr_value_bpe: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');

signal L1_out_rd_addr_forward: std_logic_vector(n_L1-1 downto 0):=(others=>'0');
signal L1_out_rd_value_forward: std_logic_vector(7 downto 0):=(others=>'0');
signal L1_out_rd_addr_bpe: std_logic_vector(n_L1-1 downto 0):=(others=>'0');
signal L1_out_rd_value_bpe: std_logic_vector(7 downto 0):=(others=>'0');
signal L1_out_wr_addr_forward: std_logic_vector(n_L1-1 downto 0):=(others=>'0');
signal L1_out_wr_value_forward: std_logic_vector(7 downto 0):=(others=>'0');

--Layer 2 signals
signal L2_w_cwr_init : std_logic:='0';
signal L2_w_addr_forward : std_logic_vector(n_L1+n_L2-1 downto 0):=(others=>'0');
signal L2_w_rd_value_forward: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');
signal L2_w_wr_value_init: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');

signal L2_w_cwr_bpe: std_logic:='0';
signal L2_w_addr_bpe  : std_logic_vector(n_L1+n_L2-1 downto 0):=(others=>'0');
signal L2_w_rd_value_bpe : std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');
signal L2_w_wr_value_bpe: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');

signal L2_out_rd_addr_forward: std_logic_vector(n_L2-1 downto 0):=(others=>'0');
signal L2_out_rd_value_forward: std_logic_vector(7 downto 0):=(others=>'0');
signal L2_out_rd_addr_bpe: std_logic_vector(n_L2-1 downto 0):=(others=>'0');
signal L2_out_rd_value_bpe: std_logic_vector(7 downto 0):=(others=>'0');
signal L2_out_wr_addr_forward: std_logic_vector(n_L2-1 downto 0):=(others=>'0');
signal L2_out_wr_value_forward: std_logic_vector(7 downto 0):=(others=>'0');

--Layer 3 signals
signal L3_w_cwr_init : std_logic:='0';
signal L3_w_addr_forward: std_logic_vector(n_L2+n_L3-1 downto 0):=(others=>'0');
signal L3_w_rd_value_forward: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');
signal L3_w_wr_value_init : std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');

signal L3_w_cwr_bpe: std_logic:='0';
signal L3_w_addr_bpe: std_logic_vector(n_L2+n_L3-1 downto 0):=(others=>'0');
signal L3_w_rd_value_bpe: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');
signal L3_w_wr_value_bpe: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');

signal L3_out_rd_addr_forward: std_logic_vector(n_L3-1 downto 0):=(others=>'0');
signal L3_out_rd_value_forward: std_logic_vector(7 downto 0):=(others=>'0');
signal L3_out_rd_addr_bpe: std_logic_vector(n_L3-1 downto 0):=(others=>'0');
signal L3_out_rd_value_bpe: std_logic_vector(7 downto 0):=(others=>'0');
signal L3_out_wr_addr_forward: std_logic_vector(n_L3-1 downto 0):=(others=>'0');
signal L3_out_wr_value_forward: std_logic_vector(7 downto 0):=(others=>'0');

-----------------------------------------
begin
----------------------------------
-- L3_out image scale up process
----------------------------------
L3_out_scale_up: image_2Nx2N_scale_up
   Generic map(7)
    Port map( 
		clk  => clk,
      addr_in  => L3_out_rd_addr_forward,
      pixel_in => L3_out_rd_value_forward,
      pixel_out_addr => pixel_out_addr,
      pixel_out => pixel_out
	 );

input_image_scale_down: image_2Nx2N_scale_down
   Generic map(8)
    Port map( 
		clk       => clk,
      pixel_in_addr => pixel_in_addr,
      pixel_in  => pixel_in,
      addr_out  => scale_down_wr_addr,
      pixel_out => scale_down_wr_value
	 );

source_RAM: RAM_2NxM_2out
    generic map(n_L3,8)
    port map(
          CLK  => clk,
          WE   => (0=>'1'),
          ADDR => scale_down_wr_addr,
          DIN  => scale_down_wr_value,
          ADDR1 => source_rd_addr,
          DOUT1 => source_rd_value,
          ADDR2 => target_rd_addr,
          DOUT2 => target_rd_value
    );
--------------------------------------------
-- Layer 1 memory blocks
--------------------------------------------
L1_w_RAM : RAM_2NxM_2in_2out
  GENERIC MAP(n_L1+n_L3,W_WIDTH)
  PORT MAP (
    clk  => clk,
    wea  => (0=>L1_w_cwr_init),
    addra=> L1_w_addr_forward,
    dina => L1_w_wr_value_init,
    douta=> L1_w_rd_value_forward,
    web  => (0=>L1_w_cwr_bpe),
    addrb=> L1_w_addr_bpe,
    dinb => L1_w_wr_value_bpe,
    doutb=> L1_w_rd_value_bpe
  );

L1_out_RAM : RAM_2NxM_2out
  GENERIC MAP(n_L1,8)
  PORT MAP (
    clk => clk,
    we  => (0=>'1'),
    addr=> L1_out_wr_addr_forward,
    din => L1_out_wr_value_forward,
    addr1 => L1_out_rd_addr_forward,
    dout1 => L1_out_rd_value_forward,
    addr2 => L1_out_rd_addr_bpe,
    dout2 => L1_out_rd_value_bpe
  );

----------------------------------
-- Layer 2 memory blocks
----------------------------------  
L2_w_RAM : RAM_2NxM_2in_2out
  GENERIC MAP(n_L1+n_L2,W_WIDTH)
  PORT MAP (
    clk  => clk,
    wea  => (0=>L2_w_cwr_init),
    addra=> L2_w_addr_forward,
    dina => L2_w_wr_value_init,
    douta=> L2_w_rd_value_forward,
    web  => (0=>L2_w_cwr_bpe),
    addrb=> L2_w_addr_bpe,
    dinb => L2_w_wr_value_bpe,
    doutb=> L2_w_rd_value_bpe
  );

L2_out_RAM : RAM_2NxM_2out
  GENERIC MAP(n_L2,8)
  PORT MAP (
    clk => clk,
    we  => (0=>'1'),
    addr=> L2_out_wr_addr_forward,
    din => L2_out_wr_value_forward,
    addr1 => L2_out_rd_addr_forward,
    dout1 => L2_out_rd_value_forward,
    addr2 => L2_out_rd_addr_bpe,
    dout2 => L2_out_rd_value_bpe
  );

-----------------------------------
-- Layer 3 memory blocks and target
-----------------------------------
L3_w_RAM : RAM_2NxM_2in_2out
  GENERIC MAP(n_L2+n_L3,W_WIDTH)
  PORT MAP (
    clk  => clk,
    wea  => (0=>L3_w_cwr_init),
    addra=> L3_w_addr_forward,
    dina => L3_w_wr_value_init,
    douta=> L3_w_rd_value_forward,
    web  => (0=>L3_w_cwr_bpe),
    addrb=> L3_w_addr_bpe,
    dinb => L3_w_wr_value_bpe,
    doutb=> L3_w_rd_value_bpe
  );

L3_out_RAM: RAM_2NxM_2out
    generic map(n_L3,8)
    port map(
       CLK  => clk,
       WE   => (0=>'1'),
       ADDR => L3_out_wr_addr_forward,
       DIN  => L3_out_wr_value_forward,
       ADDR1 => L3_out_rd_addr_forward,
       DOUT1 => L3_out_rd_value_forward,
       ADDR2 => L3_out_rd_addr_bpe,
       DOUT2 => L3_out_rd_value_bpe
    );
    
----------------------------------------
-- neural network init and forward chips
----------------------------------------
L1_forward_chip: neural_layer_2Nx2M_forward
   Generic map (n_L3,n_L1,W_WIDTH)
   Port map( 
		clk => clk,
      X_addr  => source_rd_addr,
      X_value => source_rd_value,
      A_addr  => L1_out_wr_addr_forward,
      A_value => L1_out_wr_value_forward,
      W_cwr   => L1_w_cwr_init,
      W_addr  => L1_w_addr_forward,
      W_rd_value => L1_w_rd_value_forward,
      W_wr_value => L1_w_wr_value_init
	 );

L2_forward_chip: neural_layer_2Nx2M_forward
   Generic map (n_L1,n_L2,W_WIDTH)
   Port map( 
		clk => clk,
      X_addr  => L1_out_rd_addr_forward,
      X_value => L1_out_rd_value_forward,
      A_addr  => L2_out_wr_addr_forward,
      A_value => L2_out_wr_value_forward,
      W_cwr   => L2_w_cwr_init,
      W_addr  => L2_w_addr_forward,
      W_rd_value => L2_w_rd_value_forward,
      W_wr_value => L2_w_wr_value_init
	 );

L3_forward_chip: neural_layer_2Nx2M_forward
   Generic map (n_L2,n_L3,W_WIDTH)
   Port map( 
		clk => clk,
      X_addr  => L2_out_rd_addr_forward,
      X_value => L2_out_rd_value_forward,
      A_addr  => L3_out_wr_addr_forward,
      A_value => L3_out_wr_value_forward,
      W_cwr   => L3_w_cwr_init,
      W_addr  => L3_w_addr_forward,
      W_rd_value => L3_w_rd_value_forward,
      W_wr_value => L3_w_wr_value_init
	 );

--------------------------------------
-- neural network BPE chip
--------------------------------------
BPE_chip: neural_network_bpe
    Generic map(n_L1,n_L2,n_L3,W_WIDTH)
    Port map( 
		clk => clk,
      L1_rd_addr  => L1_out_rd_addr_bpe,
      L1_rd_value => L1_out_rd_value_bpe,
      L2_rd_addr  => L2_out_rd_addr_bpe,
      L2_rd_value => L2_out_rd_value_bpe,
      L3_rd_addr  => L3_out_rd_addr_bpe,
      L3_rd_value => L3_out_rd_value_bpe,
      Target_rd_addr  => Target_rd_addr,
      Target_rd_value => Target_rd_value,
      W1_cwr      => L1_w_cwr_bpe,
      W1_addr     => L1_w_addr_bpe,
      W1_rd_value => L1_w_rd_value_bpe,
      W1_wr_value => L1_w_wr_value_bpe,
      W2_cwr      => L2_w_cwr_bpe,
      W2_addr     => L2_w_addr_bpe,
      W2_rd_value => L2_w_rd_value_bpe,
      W2_wr_value => L2_w_wr_value_bpe,
      W3_cwr      => L3_w_cwr_bpe,
      W3_addr     => L3_w_addr_bpe,
      W3_rd_value => L3_w_rd_value_bpe,
      W3_wr_value => L3_w_wr_value_bpe
	 );
end;
