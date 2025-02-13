library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vunit_lib;
library design_lib;
context vunit_lib.vunit_context;

entity decoder_2_4_tb is 
  generic (runner_cfg : string);
end entity;

architecture arch of decoder_2_4_tb is
  signal i_A : std_logic_vector(1 downto 0) := "00";
  signal i_E : std_logic := '0';
  signal o_Y : std_logic_vector(3 downto 0);

  component decoder_2_4
    port(
      i_A : in std_logic_vector(1 downto 0);
      i_E : in std_logic;
      o_Y : out std_logic_vector(3 downto 0)
    );
  end component;

begin
uut: entity design_lib.decoder_2_4 port map (i_A => i_A, i_E => i_E, o_Y => o_Y);


  main : process
  begin
    test_runner_setup(runner, runner_cfg);
   

  
    i_A <= "11"; 
    i_E <= '1';
    wait for 10 ns;  
    i_A <= "00"; 
    i_E <= '0';
    wait for 10 ns;  

    while test_suite loop
      if run("test_output_disabled") then
        check_equal(
          o_Y, 
          std_logic_vector'("0000"),
          "o_Y != 0000 when i_E=0"
        );

      elsif run("test_output_enabled") then
        for a_val in 0 to 3 loop
          i_A <= std_logic_vector(to_unsigned(a_val, 2));
          i_E <= '1';
          wait for 10 ns;  
          check_equal(
            o_Y, 
            std_logic_vector(to_unsigned(2**a_val, 4)),
            "Test failed for i_A=" & to_string(i_A)
          );
        end loop;

      elsif run("test_output_toggle") then
        i_A <= "01";
        i_E <= '1';
        wait for 10 ns; 
        check_equal(
          o_Y, 
          std_logic_vector'("0010"),
          "o_Y != 0010 after enable"
        );

        i_E <= '0';
        wait for 10 ns; 
        check_equal(
          o_Y, 
          std_logic_vector'("0000"),
          "o_Y != 0000 after disable"
        );
      end if;
    end loop;

    test_runner_cleanup(runner);
    wait;  
  end process;
  test_runner_watchdog(runner, 10 ms);
end architecture arch; 