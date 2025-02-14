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
  signal A_i : std_logic_vector(1 downto 0) := "00";
  signal E_i : std_logic := '0';
  signal Y_o : std_logic_vector(3 downto 0);

  component decoder_2_4
    port(
      A_i : in std_logic_vector(1 downto 0);
      E_i : in std_logic;
      Y_o : out std_logic_vector(3 downto 0)
    );
  end component;

begin
uut: entity design_lib.decoder_2_4 port map (A_i => A_i, E_i => E_i, Y_o => Y_o);


  main : process
  begin
    test_runner_setup(runner, runner_cfg);
   
    A_i <= "11"; 
    E_i <= '1';
    wait for 10 ns;  
    A_i <= "00"; 
    E_i <= '0';
    wait for 10 ns;  

    while test_suite loop
      if run("test_output_disabled") then
        check_equal(
          Y_o, 
          std_logic_vector'("0000"),
          "Y_o != 0000 when E_i=0"
        );

      elsif run("test_output_enabled") then
        for a_val in 0 to 3 loop
          A_i <= std_logic_vector(to_unsigned(a_val, 2));
          E_i <= '1';
          wait for 10 ns;  
          check_equal(
            Y_o, 
            std_logic_vector(to_unsigned(2**a_val, 4)),
            "Test failed for A_i=" & to_string(A_i)
          );
        end loop;

      elsif run("test_output_toggle") then
        A_i <= "01";
        E_i <= '1';
        wait for 10 ns; 
        check_equal(
          Y_o, 
          std_logic_vector'("0010"),
          "Y_o != 0010 after enable"
        );

        E_i <= '0';
        wait for 10 ns; 
        check_equal(
          Y_o, 
          std_logic_vector'("0000"),
          "Y_o != 0000 after disable"
        );
      end if;
    end loop;

    test_runner_cleanup(runner);
    wait;  
  end process;
  test_runner_watchdog(runner, 10 ms);
end architecture arch; 