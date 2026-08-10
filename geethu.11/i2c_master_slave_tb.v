```verilog
`timescale 1ns/1ps

module i2c_master_slave_tb;

    // ============================================================
    // Clock and Reset
    // ============================================================

    reg clk;
    reg reset;

    // ============================================================
    // I2C Master Signals
    // ============================================================

    reg        start;
    reg [6:0]  slave_addr;
    reg        rw;
    reg [7:0]  master_tx_data;

    wire [7:0] master_rx_data;
    wire       busy;
    wire       done;

    // ============================================================
    // I2C Slave Signals
    // ============================================================

    reg  [7:0] slave_tx_data;
    wire [7:0] slave_rx_data;
    wire       slave_done;

    // ============================================================
    // I2C Bus
    // ============================================================

    wire sda;
    wire scl;

    // ============================================================
    // Test Variables
    // ============================================================

    integer errors;

    // ============================================================
    // I2C Master Instance
    // ============================================================

    i2c_master MASTER (

        .clk        (clk),
        .reset      (reset),

        .start      (start),
        .slave_addr (slave_addr),
        .rw         (rw),
        .tx_data    (master_tx_data),

        .rx_data    (master_rx_data),

        .busy       (busy),
        .done       (done),

        .sda        (sda),
        .scl        (scl)
    );

    // ============================================================
    // I2C Slave Instance
    // ============================================================

    i2c_slave #(
        .SLAVE_ADDRESS(7'h50)
    ) SLAVE (

        .reset   (reset),

        .sda     (sda),
        .scl     (scl),

        .tx_data (slave_tx_data),
        .rx_data (slave_rx_data),

        .done    (slave_done)
    );

    // ============================================================
    // Clock Generation
    // 10 ns period
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    // ============================================================
    // Test Procedure
    // ============================================================

    initial begin

        errors = 0;

        // --------------------------------------------------------
        // Initial Values
        // --------------------------------------------------------

        reset = 1'b1;

        start = 1'b0;

        slave_addr = 7'h50;

        rw = 1'b0;

        master_tx_data = 8'h00;

        slave_tx_data = 8'h00;

        $display("");
        $display("================================================");
        $display("             I2C MASTER / SLAVE");
        $display("                 TESTBENCH");
        $display("================================================");
        $display("");

        // ========================================================
        // RESET
        // ========================================================

        #20;

        reset = 1'b0;

        #20;

        // ========================================================
        // TEST 1: MASTER WRITE
        // ========================================================

        $display("-----------------------------------------------");
        $display("TEST 1 : MASTER WRITE");
        $display("-----------------------------------------------");

        slave_addr = 7'h50;

        rw = 1'b0;

        master_tx_data = 8'hA5;

        $display("Slave Address = 0x%02h", slave_addr);
        $display("Master TX Data = 0x%02h", master_tx_data);

        start = 1'b1;

        @(posedge clk);

        start = 1'b0;

        // Wait for transaction
        wait(done == 1'b1);

        #10;

        $display("Slave RX Data = 0x%02h", slave_rx_data);

        if (slave_rx_data == master_tx_data) begin

            $display("MASTER WRITE TEST : PASS");

        end

        else begin

            $display("MASTER WRITE TEST : FAIL");

            errors = errors + 1;

        end

        // ========================================================
        // TEST 2: MASTER READ
        // ========================================================

        #50;

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 2 : MASTER READ");
        $display("-----------------------------------------------");

        slave_addr = 7'h50;

        rw = 1'b1;

        slave_tx_data = 8'h3C;

        $display("Slave Address = 0x%02h", slave_addr);
        $display("Slave TX Data  = 0x%02h", slave_tx_data);

        start = 1'b1;

        @(posedge clk);

        start = 1'b0;

        // Wait for transaction
        wait(done == 1'b1);

        #10;

        $display("Master RX Data = 0x%02h", master_rx_data);

        if (master_rx_data == slave_tx_data) begin

            $display("MASTER READ TEST : PASS");

        end

        else begin

            $display("MASTER READ TEST : FAIL");

            errors = errors + 1;

        end

        // ========================================================
        // TEST 3: DIFFERENT DATA
        // ========================================================

        #50;

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 3 : SECOND WRITE");
        $display("-----------------------------------------------");

        rw = 1'b0;

        master_tx_data = 8'h55;

        $display("Master TX Data = 0x%02h", master_tx_data);

        start = 1'b1;

        @(posedge clk);

        start = 1'b0;

        wait(done == 1'b1);

        #10;

        $display("Slave RX Data = 0x%02h", slave_rx_data);

        if (slave_rx_data == master_tx_data) begin

            $display("SECOND WRITE TEST : PASS");

        end

        else begin

            $display("SECOND WRITE TEST : FAIL");

            errors = errors + 1;

        end

        // ========================================================
        // FINAL RESULT
        // ========================================================

        #50;

        $display("");
        $display("================================================");

        if (errors == 0) begin

            $display("       I2C MASTER / SLAVE TEST : PASS");
            $display("       ALL TESTS PASSED SUCCESSFULLY");

        end

        else begin

            $display("       I2C MASTER / SLAVE TEST : FAIL");
            $display("       TOTAL ERRORS = %0d", errors);

        end

        $display("================================================");
        $display("");

        $finish;

    end

    // ============================================================
    // VCD Waveform Generation
    // ============================================================

    initial begin

        $dumpfile("i2c_waveform.vcd");

        $dumpvars(0, i2c_master_slave_tb);

    end

endmodule
```
