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
-- Description: 
--    neural network Back Propagation Error algorithm
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_signed.all;

entity neural_network_bpe is
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
end neural_network_bpe;

architecture XC7A100T of neural_network_bpe is
COMPONENT rom_der_sigmoid is
    Port ( 
		clk       : in STD_LOGIC;
		addr      : in STD_LOGIC_VECTOR(7 downto 0);
		data      : out STD_LOGIC_VECTOR(7 downto 0)
	 );
END COMPONENT;
signal der_sigmoid_key1:std_logic_vector(7 downto 0):=(others=>'0');
signal der_sigmoid_key2:std_logic_vector(7 downto 0):=(others=>'0');
signal der_sigmoid_key3:std_logic_vector(7 downto 0):=(others=>'0');
signal der_sigmoid_value1:std_logic_vector(7 downto 0):=(others=>'0');
signal der_sigmoid_value2:std_logic_vector(7 downto 0):=(others=>'0');
signal der_sigmoid_value3:std_logic_vector(7 downto 0):=(others=>'0');

signal L1_rd_addr_reg: std_logic_vector(n_L1-1 downto 0):=(others=>'0');
signal L2_rd_addr_reg: std_logic_vector(n_L2-1 downto 0):=(others=>'0');
signal L3_rd_addr_reg: std_logic_vector(n_L3-1 downto 0):=(others=>'0');
signal Target_rd_addr_reg: std_logic_vector(n_L3-1 downto 0):=(others=>'0');

signal W1_addr_reg: std_logic_vector(n_L3+n_L1-1 downto 0):=(others=>'0');
signal W2_addr_reg: std_logic_vector(n_L1+n_L2-1 downto 0):=(others=>'0');
signal W3_addr_reg: std_logic_vector(n_L2+n_L3-1 downto 0):=(others=>'0');

------------------------------------------------------
begin
L1_rd_addr<=L1_rd_addr_reg;
L2_rd_addr<=L2_rd_addr_reg;
L3_rd_addr<=L3_rd_addr_reg;
Target_rd_addr<=Target_rd_addr_reg;

W1_addr<=W1_addr_reg;
W2_addr<=W2_addr_reg;
W3_addr<=W3_addr_reg;

der_sigmoid_rom1: rom_der_sigmoid port map(clk,der_sigmoid_key1,der_sigmoid_value1);
der_sigmoid_rom2: rom_der_sigmoid port map(clk,der_sigmoid_key2,der_sigmoid_value2);
der_sigmoid_rom3: rom_der_sigmoid port map(clk,der_sigmoid_key3,der_sigmoid_value3);

bpe_gen: process (clk)
variable fsm:natural range 0 to 63:=0;
type t_sigma1 is array(2**n_L1-1 downto 0) of std_logic_vector(7 downto 0);
type t_sigma2 is array(2**n_L2-1 downto 0) of std_logic_vector(7 downto 0);
type t_sigma3 is array(2**n_L3-1 downto 0) of std_logic_vector(7 downto 0);
variable sigma1: t_sigma1;
variable sigma2: t_sigma2;
variable sigma3: t_sigma3;

variable error1: integer:=0;
variable error2: integer:=0;
variable error3: integer:=0;
variable tmp_sigma1: integer:=0;
variable tmp_sigma2: integer:=0;
variable tmp_sigma3: integer:=0;
variable tmp,tmp1,tmp2,tmp3,tmp4: integer:=0;
variable tmp_w: std_logic_vector(W_WIDTH-1 downto 0):=(others=>'0');
--variable k1,i1: natural range 0 to 2**n_L1:=0;
--variable k2,i2: natural range 0 to 2**n_L2:=0;
--variable k3,i3,i0: natural range 0 to 2**n_L3:=0;
variable sigma3_addr: std_logic_vector(n_L3-1 downto 0):=(others=>'0');
variable sigma2_addr: std_logic_vector(n_L2-1 downto 0):=(others=>'0');

begin
   if rising_edge(clk) then
   case fsm is
   when 0=> w1_cwr<='0'; w2_cwr<='0'; w3_cwr<='0'; fsm:=10; --reserved
   ---------------------------
   -- neural network BPE steps
   ---------------------------
   --  for k:=0 to n_L3-1 do
   --  begin
   --    error_target_to_L3:=-(Target_elements[k]-L3_out[k]);
   --    sigma3[k]:=error_target_to_L3*der_sigmoid(L3_out[k]) div 256;
   --    for i:=0 to n_L2-1 do
   --    begin
   --      tmp:=L3_w[k,i]-(sigma3[k]*L2_out[i]) div 256; 
   --      if tmp<-2**(W_WIDTH-1)-1 then tmp:=-2**(W_WIDTH-1)-1;
   --      if tmp>2**(W_WIDTH-1) then tmp:=2**(W_WIDTH-1);
   --      L3_w[k,i]:=tmp;
   --    end;
   --  end;
   when 10=> W3_addr_reg<=(others=>'0');
             target_rd_addr_reg<=(others=>'0');
             L3_rd_addr_reg<=(others=>'0');
             fsm:=11;
   when 11=> error3:=conv_integer("0"&L3_rd_value) - conv_integer("0"&Target_rd_value);
             der_sigmoid_key3<=L3_rd_value;
             fsm:=12;
   when 12=> tmp_sigma3:=(error3*conv_integer("0"&der_sigmoid_value3))/256;
             sigma3(conv_integer(L3_rd_addr_reg)):=conv_std_logic_vector(tmp_sigma3,8);
             fsm:=13;
   when 13=> L2_rd_addr_reg<=(others=>'0'); fsm:=14;
   when 14=> tmp:=conv_integer(W3_rd_value)-(tmp_sigma3*conv_integer("0"&L2_rd_value))/256;
             if tmp<-2**(W_WIDTH-1) then tmp:=-2**(W_WIDTH-1); end if;
             if tmp>2**(W_WIDTH-1)-1 then tmp:=2**(W_WIDTH-1)-1; end if;
             tmp_w:=conv_std_logic_vector(tmp,W_WIDTH);
             fsm:=15;
   when 15=> W3_cwr<='1'; W3_wr_value<=tmp_w; fsm:=16;
   when 16=> W3_cwr<='0';
             L2_rd_addr_reg<=L2_rd_addr_reg+1;
             W3_addr_reg<=W3_addr_reg+1;
             fsm:=17;
   when 17=> if L2_rd_addr_reg=0
             then
               target_rd_addr_reg<=target_rd_addr_reg+1;
               L3_rd_addr_reg<=L3_rd_addr_reg+1;
               fsm:=18;
             else fsm:=14;
             end if;
   when 18=> if L3_rd_addr_reg=0 then fsm:=20; else fsm:=11; end if;
   
   --  for k:=0 to n_L2-1 do
   --  begin
   --    error_L3_to_L2:=0;
   --    for i:=0 to n_L3-1 do
   --        error_L3_to_L2:=error_L3_to_L2+sigma3[i]*L3_w[i,k] div 256;
   --    tmp_sigma2:=error_L3_to_L2*der_sigmoid(L2_out[k]) div (256*256);
   --    if tmp_sigma2<-128 then tmp_sigma2:=-128;
   --    if tmp_sigma2>127 then tmp_sigma2:=127;
   --    sigma2[k]:=tmp_sigma2;
   --    for i:=0 to n_L1-1 do
   --    begin
   --      tmp:=L2_w[k,i]-(sigma2[k]*L1_out[i]) div 256;
   --      if tmp<-128 then tmp:=-128;
   --      if tmp>127 then tmp:=127;
   --      L2_w[k,i]:=tmp;
   --    end;
   --  end;
   when 20=> W3_addr_reg<=(others=>'0');
             W2_addr_reg<=(others=>'0');
             L2_rd_addr_reg<=(others=>'0');
             fsm:=21;
   when 21=> der_sigmoid_key2<=L2_rd_value;
             error2:=0;
             sigma3_addr:=(others=>'0');
             fsm:=22;
   when 22=> tmp1:=conv_integer(sigma3(conv_integer(sigma3_addr)));
             tmp2:=conv_integer(W3_rd_value);
             fsm:=23;
   when 23=> error2:=error2+tmp1*tmp2;
             sigma3_addr:=sigma3_addr+1;
             fsm:=24;
   when 24=> if sigma3_addr=0
             then
               error2:=error2/256;
               tmp3:=conv_integer("0"&der_sigmoid_value2);
               fsm:=25;
             else W3_addr_reg<=sigma3_addr & L2_rd_addr_reg; fsm:=22;
             end if;
   when 25=> tmp4:=error2*tmp3;
             tmp_sigma2:=tmp4/(256*256);
             if tmp_sigma2<-128 then tmp_sigma2:=-128; end if;
             if tmp_sigma2>127 then tmp_sigma2:=127; end if;
             fsm:=26;
   when 26=> sigma2(conv_integer(L2_rd_addr_reg)):=conv_std_logic_vector(tmp_sigma2,8);
             fsm:=27;
   when 27=> L1_rd_addr_reg<=(others=>'0'); fsm:=28;
   when 28=> tmp:=conv_integer(W2_rd_value)-(tmp_sigma2*conv_integer("0"&L1_rd_value))/256;
             fsm:=29;
   when 29=> if tmp<-2**(W_WIDTH-1) then tmp:=-2**(W_WIDTH-1); end if;
             if tmp>2**(W_WIDTH-1)-1 then tmp:=2**(W_WIDTH-1)-1; end if;
             tmp_w:=conv_std_logic_vector(tmp,W_WIDTH);
             fsm:=30;   
   when 30=> W2_cwr<='1'; W2_wr_value<=tmp_w; fsm:=31;
   when 31=> W2_cwr<='0';
             L1_rd_addr_reg<=L1_rd_addr_reg+1;
             W2_addr_reg<=W2_addr_reg+1;
             fsm:=32;
   when 32=> if L1_rd_addr_reg=0
             then
               L2_rd_addr_reg<=L2_rd_addr_reg+1;
               fsm:=33;
             else fsm:=28;
             end if;
   when 33=> if L2_rd_addr_reg=0 then fsm:=40; else fsm:=21; end if;

   --  for k:=0 to n_L1-1 do
   --  begin
   --    error_L2_to_L1:=0;
   --    for i:=0 to n_L2-1 do
   --      error_L2_to_L1:=error_L2_to_L1+sigma2[i]*L2_w[i,k] div 256;
   --    tmp:=error_L2_to_L1*der_sigmoid(L1_out[k]) div (256*256);
   --    if tmp<-128 then tmp:=-128;
   --    if tmp>127 then tmp:=127;
   --    sigma1[k]:=tmp;
   --    for i:=0 to n_L1_inputs-1 do
   --    begin
   --      tmp:=L1_w[k,i]-(sigma1[k]*Target_elements[i]]) div 256;
   --      if tmp<-128 then tmp:=-128;
   --      if tmp>127 then tmp:=127;
   --      L1_w[k,i]:=tmp;
   --    end;
   --  end;      
   when 40=> W2_addr_reg<=(others=>'0');
             W1_addr_reg<=(others=>'0');
             L1_rd_addr_reg<=(others=>'0');
             fsm:=41;
   when 41=> der_sigmoid_key1<=L1_rd_value;
             error1:=0;
             sigma2_addr:=(others=>'0');
             fsm:=42;
   when 42=> tmp1:=conv_integer(sigma2(conv_integer(sigma2_addr)));
             tmp2:=conv_integer(W2_rd_value);
             fsm:=43;
   when 43=> error1:=error1+tmp1*tmp2;
             sigma2_addr:=sigma2_addr+1;
             fsm:=44;
   when 44=> if sigma2_addr=0
             then
               error1:=error1/256;
               tmp3:=conv_integer("0"&der_sigmoid_value1);
               fsm:=45;
             else W2_addr_reg<=sigma2_addr & L1_rd_addr_reg; fsm:=42;
             end if;
   when 45=> tmp4:=error1*tmp3;
             tmp_sigma1:=tmp4/(256*256);
             if tmp_sigma1<-128 then tmp_sigma1:=-128; end if;
             if tmp_sigma1>127 then tmp_sigma1:=127; end if;
             fsm:=46;
   when 46=> sigma1(conv_integer(L1_rd_addr_reg)):=conv_std_logic_vector(tmp_sigma1,8);
             fsm:=47;
   when 47=> Target_rd_addr_reg<=(others=>'0'); fsm:=48;
   when 48=> tmp:=conv_integer(W1_rd_value)-(tmp_sigma1*conv_integer("0"&Target_rd_value))/256;
             fsm:=49;
   when 49=> if tmp<-2**(W_WIDTH-1) then tmp:=-2**(W_WIDTH-1); end if;
             if tmp>2**(W_WIDTH-1)-1 then tmp:=2**(W_WIDTH-1)-1; end if;
             tmp_w:=conv_std_logic_vector(tmp,W_WIDTH);
             fsm:=50;   
   when 50=> W1_cwr<='1'; W1_wr_value<=tmp_w; fsm:=51;
   when 51=> W1_cwr<='0';
             Target_rd_addr_reg<=Target_rd_addr_reg+1;
             W1_addr_reg<=W1_addr_reg+1;
             fsm:=52;
   when 52=> if Target_rd_addr_reg=0
             then
               L2_rd_addr_reg<=L2_rd_addr_reg+1;
               fsm:=53;
             else fsm:=48;
             end if;
   when 53=> if L2_rd_addr_reg=0 then fsm:=63; else fsm:=41; end if;

   when 63=> fsm:=0;
   when others=> NULL;
   end case;
   end if;
end process;
end;
