library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity HARD_NEURO_BPE_top is
    Port (
			CLK50_in : in  STD_LOGIC;
         key: in  STD_LOGIC_VECTOR(1 downto 0);
         led: out  STD_LOGIC_VECTOR(1 downto 0);

			OV7670_SIOC  : out   STD_LOGIC;
			OV7670_SIOD  : inout STD_LOGIC;
			OV7670_RESET : out   STD_LOGIC;
			OV7670_PWDN  : out   STD_LOGIC;
			OV7670_VSYNC : in    STD_LOGIC;
			OV7670_HREF  : in    STD_LOGIC;
			OV7670_PCLK  : in    STD_LOGIC;
			OV7670_XCLK  : out   STD_LOGIC;
			OV7670_D     : in    STD_LOGIC_VECTOR(7 downto 0);
		
			AN430_dclk : out  STD_LOGIC;
			AN430_red : out  STD_LOGIC_VECTOR (7 downto 0);
         AN430_green : out  STD_LOGIC_VECTOR (7 downto 0);
         AN430_blue : out  STD_LOGIC_VECTOR (7 downto 0);
         AN430_de : out  STD_LOGIC
		);
end HARD_NEURO_BPE_top;

architecture XC7A100T of HARD_NEURO_BPE_top is
component clk_core is
	port (
	CLK50_IN: in std_logic;
	CLK100: out std_logic;
	CLK25: out std_logic;
	CLK8: out std_logic
	);
end component;
signal clk100,clk25,clk8:std_logic;

component freq_div_module is
    Port ( 
		clk   : in  STD_LOGIC;
      value : in  STD_LOGIC_VECTOR(31 downto 0);
      result: out STD_LOGIC
	 );
end component;
signal clk_10Khz: std_logic:='0';

component keys_supervisor is
   Port ( 
      clk : in std_logic;
      key : in std_logic_vector(1 downto 0);
      noise  : out std_logic_vector(31 downto 0)
	);
end component;
signal noise_reg: std_logic_vector(31 downto 0):=(others=>'0');

component rnd16_module is
    Generic (seed:STD_LOGIC_VECTOR(31 downto 0));
    Port ( 
      clk: in  STD_LOGIC;
      rnd16: out STD_LOGIC_VECTOR(15 downto 0)
	 );
end component;
signal rnd16: std_logic_vector(15 downto 0):=(others=>'0');
	
component LCD_AN430 is
    Port ( lcd_clk   : in std_logic;
           lcd_r_out : out  STD_LOGIC_VECTOR (7 downto 0);
           lcd_g_out : out  STD_LOGIC_VECTOR (7 downto 0);
           lcd_b_out : out  STD_LOGIC_VECTOR (7 downto 0);
           lcd_de    : out  STD_LOGIC;
			  clk_wr: in std_logic;
           x : in  STD_LOGIC_VECTOR (9 downto 0);
           y : in  STD_LOGIC_VECTOR (9 downto 0);
			  pixel : in std_logic_vector(7 downto 0)
    );
end component;
signal lcd_clk: std_logic;
signal lcd_de: std_logic:='0';
signal lcd_pixel: STD_LOGIC_VECTOR (7 downto 0):=(others=>'0');
signal lcd_x: STD_LOGIC_VECTOR (9 downto 0):=(others=>'0');
signal lcd_y: STD_LOGIC_VECTOR (9 downto 0):=(others=>'0');
	
component CAM_OV7670 is
    Port (
      clk   : in std_logic;
      vsync : in std_logic;
		href  : in std_logic;
		din   : in std_logic_vector(7 downto 0);
      x : out std_logic_vector(9 downto 0);
      y : out std_logic_vector(9 downto 0);
      pixel : out std_logic_vector(7 downto 0);
      ready : out std_logic
		);
end component;
signal cam_ready    : std_logic;
signal cam_clk      : std_logic;
signal cam_pixel    : std_logic_vector(7 downto 0):=(others=>'0');
signal cam_x        : std_logic_vector(9 downto 0):=(others=>'0');
signal cam_y        : std_logic_vector(9 downto 0):=(others=>'0');
	
COMPONENT RAM_2NxM_2clk is
    generic (N:natural range 1 to 32:=0; M:natural range 1 to 32:=8);
    port (CLKA : in std_logic;
          WEA  : in std_logic_vector(0 downto 0);
          ADDRA: in std_logic_vector(N-1 downto 0);
          DINA : in std_logic_vector(M-1 downto 0);
          CLKB : in std_logic;
          ADDRB: in std_logic_vector(N-1 downto 0);
          DOUTB: out std_logic_vector(M-1 downto 0)
    );
END COMPONENT;

component neural_triple_cpu is
    Port ( 
		clk           : in std_logic;
      pixel_in_addr : out std_logic_vector(15 downto 0);
      pixel_in      : in std_logic_vector(7 downto 0);
      pixel_out_addr: out std_logic_vector(15 downto 0);
      pixel_out     : out std_logic_vector(7 downto 0)
	 );
end component;

signal lcd_flag: std_logic:='0';
signal buffer_flag: std_logic:='0';
signal noise_pixel: std_logic_vector(7 downto 0):=(others=>'0');
signal buffer_x,buffer_y:std_logic_vector(9 downto 0):=(others=>'0');

signal cpu_clk:std_logic;
signal cpu_lcd_pixel: std_logic_vector(7 downto 0):=(others=>'0');
signal cpu_pixel_in,cpu_pixel_out: std_logic_vector(7 downto 0):=(others=>'0');
signal cpu_addr_in, cpu_addr_out: std_logic_vector(15 downto 0):=(others=>'0');

begin
freq_10Khz_chip: freq_div_module port map(clk8,conv_std_logic_vector(400,32),clk_10Khz);
clk_chip : clk_core port map (CLK50_in,CLK100,CLK25,CLK8);
lcd_clk<=clk8;
cam_clk<=clk25;
cpu_clk<=clk100;

led<=key;
keys_chip: keys_supervisor port map(clk_10Khz,key,noise_reg);

rnd16_chip: rnd16_module generic map (conv_std_logic_vector(26535,32))
								 port map(cam_clk,rnd16);
     
AN430_dclk<=not(lcd_clk);
AN430_de<=lcd_de;
AN430_lcd: LCD_AN430 port map (
		lcd_clk,AN430_red,AN430_green,AN430_blue,lcd_de,
      cam_clk,lcd_x,lcd_y,lcd_pixel);

lcd_x<=cam_x-conv_std_logic_vector(80,10) when lcd_flag='1' else (others=>'0');
lcd_y<=cam_y-conv_std_logic_vector(104,10) when lcd_flag='1' else (others=>'0');
lcd_pixel<=cpu_lcd_pixel when buffer_flag='1' else noise_pixel;

--minimal OV7670 grayscale mode
OV7670_PWDN  <= '0'; --0 - power on
OV7670_RESET <= '1'; --0 - activate reset
OV7670_XCLK  <= cam_clk;
OV7670_siod  <= 'Z';
OV7670_sioc  <= '0';
   
OV7670_cam: CAM_OV7670 PORT MAP(
		clk   => OV7670_PCLK,
		vsync => OV7670_VSYNC,
		href  => OV7670_HREF,
		din   => OV7670_D,
      x =>cam_x,
      y =>cam_y,
      pixel =>cam_pixel,
      ready =>cam_ready
      );
      
lcd_flag<='1' when (cam_x>=80)and(cam_x<560)and(cam_y>=104)and(cam_y<376) else '0';      
buffer_flag<='1' when (cam_x>=192)and(cam_x<448)and(cam_y>=112)and(cam_y<368) else '0';

noise_pixel<=rnd16(7 downto 0) when
      rnd16<noise_reg(6 downto 0)*conv_std_logic_vector(655,10)
      else cam_pixel;
-----------------------------------------------------

buffer_x<=cam_x-conv_std_logic_vector(192,10) when buffer_flag='1' else (others=>'0');
buffer_y<=cam_y-conv_std_logic_vector(112,10) when buffer_flag='1' else (others=>'0');

cpu_img_in : RAM_2NxM_2clk
  GENERIC MAP (16,8)
  PORT MAP (
    clka => cam_clk,
    wea => (0=>cam_ready),
    addra => buffer_y(7 downto 0) & buffer_x(7 downto 0),
    dina => noise_pixel,
    clkb => cpu_clk,
    addrb => cpu_addr_in,
    doutb => cpu_pixel_in
  );

cpu_img_out : RAM_2NxM_2clk
  GENERIC MAP (16,8)
  PORT MAP (
    clka => cpu_clk,
    wea => (0=>'1'),
    addra => cpu_addr_out,
    dina => cpu_pixel_out,
    clkb => cam_clk,
    addrb => buffer_y(7 downto 0) & buffer_x(7 downto 0),
    doutb => cpu_lcd_pixel
  );

cpu: neural_triple_cpu port map(
		clk=>cpu_clk,
      pixel_in_addr=>cpu_addr_in,
      pixel_in=>cpu_pixel_in,
      pixel_out_addr=>cpu_addr_out,
      pixel_out=>cpu_pixel_out
	 );
end;
