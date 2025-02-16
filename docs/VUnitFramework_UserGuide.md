# VUnit Framework User Guide

**For more details, refer to the official project page at [vunit.github.io](https://vunit.github.io), where all the information for this user guide was collected and is continuously updated.**

---

## About

VUnit is an open-source unit testing framework for VHDL/SystemVerilog that simplifies and automates the process of verifying your hardware designs. This guide is intended to showcase VUnit's capabilities by explaining how to set up the framework, integrate your designs with testbenches, and run your tests via VUnit.

---

## Key Features

### **Automated Testing**
VUnit allows you to write test benches that can automatically execute a series of tests on your hardware design. This helps in detecting issues early in the design cycle and ensures that changes to the design do not introduce regressions.

### **Python Integration**
One of VUnit's key features is its integration with Python. Python serves as the scripting language for setting up test environments, selecting tests to run, and handling simulation results. This integration simplifies automation and makes it easier to incorporate VUnit into continuous integration (CI) pipelines and other automation tools such as GitHub Actions, GitLab CI, and Jenkins.

### **Multiple Simulator Support**
VUnit is designed to be simulator-agnostic. It supports several popular simulation backends (like GHDL, ModelSim, Riviera-PRO, and others), which means you can use VUnit with your preferred simulator without major changes to your test benches.

### **Modular and Reusable Test Benches**
By encouraging modularity in test bench design, VUnit makes it easier to reuse components across different tests and projects. This is particularly useful for large projects where different parts of the design need to be tested in various configurations.

### **Enhanced Reporting and Diagnostics**
VUnit automates the collection and reporting of simulation results. When tests fail, it provides detailed logs and diagnostics that help identify and resolve issues quickly.

### **Support for Parameterized Tests**
You can define parameterized tests that run the same test bench with different configurations. This data-driven testing approach is especially valuable for verifying a design's behavior under various conditions without duplicating test code.

### **Community and Open Source**
Being open source, VUnit has a community of users and contributors. This fosters an environment of shared improvements and extensions. The project is hosted on platforms like GitHub, where users can contribute, report issues, or get help.

---

## Installation Process

### Prerequisites
- **Python 3**: VUnit is driven by a Python-based test runner.
- **VHDL Simulator**: Any supported simulator (e.g., GHDL, ModelSim, Riviera-PRO).

### Installing VUnit
Open a terminal and install VUnit via pip:
```bash
pip install vunit_hdl
```
This command installs the VUnit framework along with its dependencies. No additional configuration is required for basic usage.

For installing the **Development Version** or getting the **VUnit Developers Installation**, refer to the [Installation section of the project page](https://vunit.github.io/installing.html).

By default, VUnit automatically detects and selects a supported VHDL/Verilog simulator. The selection process follows a priority order, ensuring that if multiple simulators are installed, the one with the highest predefined priority available is used. For more instructions on which simulator to choose or how you can override VUnit’s default simulator selection and specify which simulator to use, consult the [simulator selection guide](https://vunit.github.io/cli.html#simulator-selection).

---

## Testbench Modification

When integrating an existing VHDL testbench into the VUnit framework, the following changes should be made to the testbench:

1. **Include VUnit Libraries and Context**
```vhdl
library vunit_lib;
context vunit_lib.vunit_context;
```
   We are adding a declaration for the VUnit library at the top of the file and including the VUnit context to access pre-defined types, procedures, and functions.

2. **Modify the Testbench Entity**
```vhdl
entity my_testbench is
  generic (runner_cfg : string);
end entity;
```
   We are updating our testbench entity to include a generic parameter that VUnit uses for configuration.

3. **Set Up the Test Runner in the Architecture**
```vhdl
test_process : process
  begin
    -- Initialize VUnit Test Runner
    test_runner_setup(runner, runner_cfg);
    -- Clean up and end simulation
    test_runner_cleanup(runner);
    wait;
end process test_process;
```
   At the beginning of our main test process, call the VUnit procedure to set up the test runner. At the end of the process, call the cleanup routine, this ends the simulation and also allows VUnit to collect and report test results.

   If the testbench includes auxiliary processes (e.g., clock generation, stimulus generation), these should run concurrently without interfering with VUnit’s simulation control. Only the main process, which controls the test lifecycle, should call `test_runner_setup` and `test_runner_cleanup`.

For more information about preparing a testbench for VUnit, as well as an example, consult the [VUnit User Guide](https://vunit.github.io/user_guide.html).

---

## Usage

The test runner script (`run.py`) is the entry point for VUnit.

The script automatically:
- Compiles all the source files from your design and test directories.
- Discovers and registers the testbenches (thanks to VUnit's context and setup calls).
- Runs the simulation, executing all test cases using the selected simulator.
- Generates reports of the test results.

### Practical Example: Integrating VHDL Designs with VUnit

To demonstrate the usage of VUnit, this guide provides a practical example of integrating a VHDL design with a corresponding testbench. In this example, we have two different VHDL designs:

- **decoder_2_4**
- **eight_bit_multiplier**

Each design comes with a testbench that has been modified for VUnit use.

Our project now looks like this:

```plaintext
fpga-sonar/
├── scripts/
│   └── run.py
└── hardware/
    ├── design/
    │   ├── decoder_2_4.vhd
    │   └── eight_bit_multiplier.vhd
    └── tests/
        ├── decoder_2_4_tb.vhd
        └── eight_bit_multiplier_tb.vhd
```
If we navigate to the scripts/ in the command prompt and run :
```bash
python run.py
```
We should get a test report that looks like this :

![TestReport](https://github.com/user-attachments/assets/ee74c148-a4cc-4d77-9e2c-5c8951627d39)

If a test were to fail the reasons would be included in the report and the test would be marked as a fail.

The primary outputs of the VUnit process are the compiled libraries, which can be found in:

    scripts\vunit_out\modelsim\libraries

In our case, these are **design_lib** and **testbench_lib**, serving as organized containers for our compiled design and testbench source files.

The Python script `run.py` supports additional command-line arguments that enable users to customize its behavior according to their testing requirements. For further details regarding these available options and their proper usage, please refer to the [VUnit CLI documentation](https://vunit.github.io/cli.html).

Some options are e.g. :

Run all testbenches where the name starts with decoder_2_4_tb :
```bash
python run.py -v testbench_lib.decoder_2_4_tb*
```
Run a specific testbench named decoder_2_4_tb :
```bash
python run.py -v testbench_lib.decoder_2_4_tb.all
```

In our practical example the **eight_bit_multiplier** includes a testbench that is considered a minimal VUnit testbench that has the basic requirements to run in VUnit environment.

The **decoder_2_4** testbench on the other hand utilizes features that can be found in the **VHDL Run Library**

---
## VHDL Run Library
The VHDL run library is made up of a number of VHDL packages providing additional functionality for running a VUnit testbench.
The detailed information on the library can be seen here : [VHDL Run Library](https://vunit.github.io/run/user_guide.html#).

The main addition we use here is a set of test cases called a **test suite** .


In VUnit, a test suite is a collection of test cases that are grouped together to verify different aspects of a design. It allows for common initialization and cleanup routines to be applied across all test cases while still ensuring that each test runs in isolation (although these test cases share a common environment and setup, they execute independently). This approach enhances modularity, simplifies debugging, and provides detailed reporting for each individual test case.


```vhdl
architecture arch of tb_test is
begin
test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);

    -- Put test suite setup code here. This code is common to the entire test suite
    -- and is executed *once* prior to all test cases.

    -- vunit: run_all_in_same_sim running all the test cases in the same simulation
    while test_suite loop

      -- Put test case setup code here. This code is executed before *every* test case.

      if run("Test to_string for integer") then
        -- The test case code is placed in the corresponding (els)if branch.
        check_equal(to_string(17), "17");

      elsif run("Test to_string for boolean") then
        check_equal(to_string(true), "true");

      end if;

      -- Put test case cleanup code here. This code is executed after *every* test case.

    end loop;

    -- Put test suite cleanup code here. This code is common to the entire test suite
    -- and is executed *once* after all test cases have been run.

    test_runner_cleanup(runner);
  end process;
  test_runner_watchdog(runner, 10 ms);
end architecture;
```

Using a test suite in our testbench offers several benefits:

- **Modular Organization:**  
  A test suite allows us to group related test cases within a single testbench. This modularity makes it easier to manage, maintain, and scale our testing environment.

- **Automatic Test Discovery:**  
  With a test suite, VUnit can automatically scan for and register test cases (via the `run` function), reducing the need for manual test case registration.

- **Selective Execution:**  
  We can selectively run specific test cases or groups of tests using command-line filters. This is particularly useful when debugging or performing regression testing.

- **Common Setup and Teardown:**  
  Test suites allow us to define common setup and cleanup code that runs once per test suite, which avoids duplicating initialization or reset logic across multiple test cases.

- **Isolated Test Cases:**  
  Running test cases independently ensures that a failure in one test does not affect the execution of others. This isolation leads to more reliable and granular test reporting.

- **Enhanced Reporting:**  
  Test suites provide detailed feedback by reporting results on a per-test-case basis. This makes it easier to pinpoint and address issues.

- **Scalability:**  
  As the complexity of our design increases, test suites help manage a growing number of test cases effectively, facilitating continuous integration and automated testing workflows.

By default the test suite automatically iterates through every test case that has been registered via the `run` function and since each test case runs in its own simulation instance any side effects, state changes, or errors in one test case do not affect the execution or outcome of other test cases.


We can list out all the available tests with: 
```bash
python run.py --list
```
If we wanted to e.g run 2 of the 4 available tests in our project we could do it like this:
```bash
python run.py *test_output_enabled *test_output_toggle
```
Possible drawback of test cases running independently is the overhead of starting a new simulation for each test case ,we can instead force all test cases of a testbench to be run in the same simulation. This is done by adding the `run_all_in_same_sim` before the test suite loop.

Another functionality of VHDL Run Library we use in our **decoder_2_4** testbench is the **The VUnit Watchdog**.

The VUnit Watchdog is a feature designed to monitor test execution and prevent stalled or indefinitely running tests from blocking the entire test suite. It enforces a timeout on each test case, ensuring that if a test case runs longer than the specified period, it is terminated and marked as failed.

Some of the benefits: 

- **Timeout Enforcement:**  
  The watchdog monitors the simulation and triggers a timeout if a test case does not complete within the designated period.
  
- **Stall Detection:**  
  It is particularly useful for detecting issues like infinite loops, deadlocks, or any other scenarios where a test might hang, ensuring that such conditions do not halt the overall testing process.

- **Independent Test Runs:**  
  Since VUnit typically runs each test case in isolation, the watchdog ensures that even if one test stalls, it will not prevent the execution of subsequent tests.
  
We can configure it outside of the process with e.g:
```vhdl
test_runner_watchdog(runner, 10 ms);
```
This sets a timeout of 10 milliseconds for each test case, the watchdog timer is applied to each individual test case not the entire test suite (so it's 10 ms per test case).

For more information on : 

- **Distributed Testbenches**
- **Controlling Which Test Cases to Run**
- **Running Test Cases Independently**
- **The VUnit Watchdog**
- **What Makes a Test Fail**
- **Counting Errors with VUnit Logging/Check Libraries**
- **Running a VUnit Testbench Standalone**
- **And more...**

  refer to the official project page.
---
