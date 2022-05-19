------------------------------------------------ ------------------
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
-- Description: der_sigmoid:=y*(1-y); scale 256
--    remember do *256 outside function before "div"
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity rom_der_sigmoid is
    Port ( 
		clk       : in STD_LOGIC;
		addr      : in STD_LOGIC_VECTOR(7 downto 0);
		data      : out STD_LOGIC_VECTOR(7 downto 0)
	 );
end rom_der_sigmoid;

architecture XC7A100T of rom_der_sigmoid is
   type rom_type is array (0 to 255) of natural range 0 to 255; --std_logic_vector(7 downto 0);
   constant ROM : rom_type:= (
  0,0,1,2,3,4,5,6,7,8,9, 
  10,11,12,13,14,15,15,16, 
  17,18,19,20,20,21,22,23, 
  24,24,25,26,27,28,28,29, 
  30,30,31,32,33,33,34,35, 
  35,36,37,37,38,39,39,40, 
  40,41,42,42,43,43,44,44, 
  45,45,46,46,47,48,48,48, 
  49,49,50,50,51,51,52,52, 
  53,53,53,54,54,55,55,55, 
  56,56,56,57,57,57,58,58, 
  58,58,59,59,59,60,60,60, 
  60,60,61,61,61,61,61,62, 
  62,62,62,62,62,
  63,63,63,63,63,63,63,63,
  63,63,63,63,63,63,63,63,
  64, 
  63,63,63,63,63,63,63,63,
  63,63,63,63,63,63,63,63, 
  62,62,62,62,62,62,61,61, 
  61,61,61,60,60,60,60,60, 
  59,59,59,58,58,58,58,57, 
  57,57,56,56,56,55,55,55, 
  54,54,53,53,53,52,52,51, 
  51,50,50,49,49,48,48,48, 
  47,46,46,45,45,44,44,43, 
  43,42,42,41,40,40,39,39, 
  38,37,37,36,35,35,34,33, 
  33,32,31,30,30,29,28,28, 
  27,26,25,24,24,23,22,21, 
  20,20,19,18,17,16,15,15, 
  14,13,12,11,10,9,8,7, 
  6,5,4,3,2,1,0
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