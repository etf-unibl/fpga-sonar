## Interface circuit

Interfacing circuit for adapting sonar output to DE1-SoC input

The operating voltage of the sonar is 5V. The Echo signal is the sonar's output signal, and it needs to be adjusted to 3.3V, which is the operating voltage of the DE1-SoC board. The adjustment is done using a voltage divider (Picture 1.1).

![interfejs kolo](https://github.com/user-attachments/assets/fb105e81-3ed0-467a-9b5c-022bff3f5dd8) <br>
Picture 1.1 Circuit schematic 

Also, for the trigger signal, which is the input of the sonar, a sufficiently high voltage is required to be recognized as a high logic level. The output voltage of the DE1-SoC is 3.3V, which is high enough to be recognized as a high logic level.

The formula for calculating the voltage in a voltage divider is:

$$
V_{out} = V_{in} \times \frac{R_2}{R_1 + R_2}
$$

Where:
- $V_{in} = 5V$,
- $V_{out} = 3.3V$.

By setting $V_{out} = 3.3V$, we obtain the ratio:

$$
\frac{R_2}{R_1 + R_2} = \frac{3.3V}{5V} = 0.66
$$

**Selection of standard resistor values:**

If we choose $R_2 = 4.7k\Omega$, then from the formula:

$$
R_1 = R_2 \times \left( \frac{V_{in}}{V_{out}} - 1 \right)
$$

$$
R_1 = 4.7k\Omega \times \left( \frac{5V}{3.3V} - 1 \right) = 4.7k\Omega \times (1.515 - 1) = 4.7k\Omega \times 0.515 = 2.4k\Omega
$$

Now, if we calculate output voltage with this values of resistors, we get:

$$
V_{out} = 5 \times \frac{4.7}{4.7 + 2.4} = 3.309V
$$

We see that with this values, we get voltage little bit over 3.3V.
Therefore, **$R_1 = 2.7k\Omega$ and $R_2 = 4.7k\Omega$.**

