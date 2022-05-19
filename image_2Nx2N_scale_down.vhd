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
use ieee.std_logic_unsigned.all;

entity image_2Nx2N_scale_down is
   Generic (N:natural range 1 to 16:=8);
    Port ( 
		clk     : in std_logic;
      pixel_in_addr: out std_logic_vector(2*N-1 downto 0);
      pixel_in : in std_logic_vector(7 downto 0);
      addr_out : out std_logic_vector(2*N-3 downto 0);
      pixel_out: out std_logic_vector(7 downto 0)
	 );
end image_2Nx2N_scale_down;

architecture XC7A100T of image_2Nx2N_scale_down is
signal x_in: std_logic_vector(N-1 downto 0):=(others=>'0');
signal y_in: std_logic_vector(N-1 downto 0):=(others=>'0');
signal addr_reg:std_logic_vector(2*N-3 downto 0);
begin
pixel_in_addr<=y_in & x_in;
addr_out<=addr_reg;

scale_down_gen: process (clk)
variable fsm:natural range 0 to 7:=0;
variable pixel,pixel1,pixel2,pixel3,pixel4:std_logic_vector(9 downto 0);
begin
   if rising_edge(clk) then
   case fsm is
   when 0=> fsm:=1; --reserved
   when 1=> addr_reg<=(others=>'0'); fsm:=2;
   when 2=> y_in<=addr_reg(2*N-3 downto N-1)&"0";
            x_in<=addr_reg(N-2 downto 0)&"0";
            pixel1:="00"&pixel_in;
            fsm:=3;
   when 3=> y_in<=addr_reg(2*N-3 downto N-1)&"0"+1;
            x_in<=addr_reg(N-2 downto 0)&"0";
            pixel2:="00"&pixel_in;
            fsm:=4;
   when 4=> y_in<=addr_reg(2*N-3 downto N-1)&"0";
            x_in<=addr_reg(N-2 downto 0)&"0"+1;
            pixel3:="00"&pixel_in;
            fsm:=5;
   when 5=> y_in<=addr_reg(2*N-3 downto N-1)&"0"+1;
            x_in<=addr_reg(N-2 downto 0)&"0"+1;
            pixel4:="00"&pixel_in;
            fsm:=6;
   when 6=> pixel:=pixel1+pixel2+pixel3+pixel4;
            pixel_out<=pixel(9 downto 2);
            fsm:=7;
   when 7=> addr_reg<=addr_reg+1;
            fsm:=2;
   when others=> NULL;
   end case;
   end if;
end process;
end;
