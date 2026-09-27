-- File: rtl/frame_extender.vhd
-- Purpose: receive a continuous 8 Mbit/s serial input stream,
--          identifies the bit position of a single '1' bit within each frame,
--          and outputs an extended frame containing the original 128 bit data followed
--          by an 8 bit binary representation of the detected bit position.
-- Notes  : Input sampling occurs on rising edge of in_clk; output data
--          changes on falling edge of out_clk and is sampled on out_clk rising.
--          Max latency from input to output should be < 2 frames.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serial_frame_extender is
  port (
    rst_n    : in  std_logic;  -- active-low synchronous reset
    in_clk   : in  std_logic;  -- 8 MHz input clock (reference for input sampling)
    clk64    : in  std_logic;  -- 64 MHz system clock; synchronous to in_clk
    in_data  : in  std_logic;  -- serial data in (sampled on in_clk rising edge)
    out_clk  : out std_logic;  -- generated output clock
    out_data : out std_logic   -- serial data out; changes on falling edge of out_clk
  );
end entity;

architecture rtl of serial_frame_extender is

  ---------------------------------------------------------------------------
  -- Constants from spec
  ---------------------------------------------------------------------------
  constant START_PATTERN     : std_logic_vector(7 downto 0) := "01001110"; -- MSB-first
  constant PAYLOAD_BITS      : integer := 120;
  constant FRAME_BITS        : integer := 8 + PAYLOAD_BITS;   -- 128
  constant EXT_BITS          : integer := 8;
  constant OUT_BITS          : integer := FRAME_BITS + EXT_BITS; -- 136


begin

  -- replace architecture body of your own implementation
  -- edit script for running if changing or adding file name
  out_clk  <= in_clk;
  out_data <= in_data;

end architecture;
