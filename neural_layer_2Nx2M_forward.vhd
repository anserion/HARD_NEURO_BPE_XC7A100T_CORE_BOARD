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
-- Description: neural network Layer forward step
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_signed.all;

entity neural_layer_2Nx2M_forward is
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
      W_cwr   : out std_logic;
      W_addr  : out std_logic_vector(N+M-1 downto 0);
      W_rd_value : in std_logic_vector(W_WIDTH-1 downto 0);
      W_wr_value : out std_logic_vector(W_WIDTH-1 downto 0)
	 );
end neural_layer_2Nx2M_forward;

architecture XC7A100T of neural_layer_2Nx2M_forward is
signal W_addr_reg: std_logic_vector(N+M-1 downto 0):=(others=>'0');
signal A_addr_reg: std_logic_vector(M-1 downto 0):=(others=>'0');
signal X_addr_reg: std_logic_vector(N-1 downto 0):=(others=>'0');

component rnd16_module is
    Generic (seed:STD_LOGIC_VECTOR(31 downto 0));
    Port ( 
      clk: in  STD_LOGIC;
      rnd16: out STD_LOGIC_VECTOR(15 downto 0)
	 );
end component;
signal rnd16: std_logic_vector(15 downto 0):=(others=>'0');

component rom_sigmoid is
    Port ( 
		clk       : in STD_LOGIC;
		addr      : in STD_LOGIC_VECTOR(7 downto 0);
		data      : out STD_LOGIC_VECTOR(7 downto 0)
	 );
end component;
signal sigmoid_key:std_logic_vector(7 downto 0):=(others=>'0');
signal sigmoid_value:std_logic_vector(7 downto 0):=(others=>'0');

begin
sigmoid_rom: rom_sigmoid port map(clk,sigmoid_key,sigmoid_value);
rnd16_chip: rnd16_module generic map (conv_std_logic_vector(26535,32))
								 port map(clk,rnd16);

W_addr<=W_addr_reg;
A_addr<=A_addr_reg;
X_addr<=X_addr_reg;
                         
forward_gen: process (clk)
variable fsm:natural range 0 to 15:=0;
variable scalar: integer:=0;
variable tmp_idx: integer:=0;
begin
   if rising_edge(clk) then
   case fsm is
   ----------------------------------
   -- init (W - small random numbers)
   ----------------------------------
   --  for k:=0 to M-1 do
   --    for i:=0 to N-1 do
   --      W[k,i]:=0; //random(16)-8;   
   when 0=> W_cwr<='1'; W_addr_reg<=(others=>'0'); fsm:=1;
   when 1=> W_wr_value<=((W_WIDTH-5 downto 0 =>'0')&rnd16(3 downto 0))-conv_std_logic_vector(8,W_WIDTH);
            fsm:=2;
   when 2=> W_addr_reg<=W_addr_reg+1; fsm:=3;
   when 3=> if W_addr_reg=0 then W_cwr<='0'; fsm:=4; else fsm:=1; end if;
   
   ------------------------------------
   -- neural network layer forward step
   ------------------------------------
   --  for k:=0 to M-1 do
   --  begin
   --    scalar:=0;
   --    for i:=0 to N-1 do
   --       scalar:=scalar+L1_w[k,i]*X[i];
   --    tmp_idx:=scalar*16 div (256*256) +128;
   --    if tmp_idx<0 then tmp_idx:=0;
   --    if tmp_idx>255 then tmp_idx:=255;
   --    A[k]:=sigmoid(tmp_idx);
   --  end;
   when 4 => W_addr_reg<=(others=>'0');
             A_addr_reg<=(others=>'0');
             X_addr_reg<=(others=>'0');
             fsm:=5;
   when 5 => scalar:=0; fsm:=6;
   when 6 => scalar:=scalar+conv_integer("0"&X_value)*conv_integer(W_rd_value);
             fsm:=7;
   when 7 => W_addr_reg<=W_addr_reg+1;
             X_addr_reg<=X_addr_reg+1;
             fsm:=8;
   when 8 => if X_addr_reg=0
             then 
               tmp_idx:=(scalar*20)/(1024*1024)+128; -- <== tune parameter
               if tmp_idx<0 then tmp_idx:=0; end if;
               if tmp_idx>255 then tmp_idx:=255; end if;
               fsm:=9;
             else fsm:=6;
             end if;
   when 9 => fsm:=10; sigmoid_key<=conv_std_logic_vector(tmp_idx,8);
   when 10=> fsm:=11; A_value<=sigmoid_value;
   when 11=> A_addr_reg<=A_addr_reg+1; fsm:=12;
   when 12=> if A_addr_reg=0 then fsm:=4; else fsm:=5; end if;
   when others=> NULL;
   end case;
   end if;
end process;
end;
