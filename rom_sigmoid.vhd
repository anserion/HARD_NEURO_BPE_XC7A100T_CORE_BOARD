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
-- Description: sigmoid:=1/(1+exp(-x)); scale 256
--      remember do *16 outside function before "div"
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity rom_sigmoid is
    Port ( 
		clk       : in STD_LOGIC;
		addr      : in STD_LOGIC_VECTOR(7 downto 0);
		data      : out STD_LOGIC_VECTOR(7 downto 0)
	 );
end rom_sigmoid;

architecture XC7A100T of rom_sigmoid is
   type rom_type is array (0 to 255) of natural range 0 to 255;--std_logic_vector(7 downto 0);
   constant ROM : rom_type:= (
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,
   1,1,1,1,1,1,1,1,1,1,1,
   2,2,2,2,2,2,2,
   3,3,3,3,4,4,4,4,5,5,5,6,6,7,7,7,
   8,8,9,10,10,11,12,12,13,14,15,16,
   17,18,19,20,21,22,24,25,27,28,30,
   32,33,35,37,39,41,44,46,48,51,54, 
   56,59,62,65,68,71,75,78,81,85,88, 
   92,96,100,103,107,111,115,119,123, 
   127,131,135,139,143,147,151,154, 
   158,162,166,169,173,176,179,183, 
   186,189,192,195,198,200,203,206, 
   208,210,213,215,217,219,221,222, 
   224,226,227,229,230,232,233,234, 
   235,236,237,238,239,240,241,
   242,242,243,244,244,245,246,246,
   247,247,247,248,248,249,249,249,
   250,250,250,250,251,251,251,251,
   252,252,252,252,252,252,252,
   253,253,253,253,253,253,253,253,253,253,253,
   254,254,254,254,254,254,254,254,
   254,254,254,254,254,254,254,254,
   254,254,254,254,254,254,254,254,
   254,254,254,254,254,254,254,254,
   254,254,254,254,254,254,254
);
   signal rdata: std_logic_vector(7 downto 0);
begin
	rdata<=conv_std_logic_vector(ROM(conv_integer(addr)),8);
   process(clk)
   begin
		if rising_edge(clk) then
            data<=rdata;
		end if;
	end process;
end;