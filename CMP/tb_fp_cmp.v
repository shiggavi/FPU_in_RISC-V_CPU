
`timescale 1ns/1ps

module tb_fp_cmp;
    // Inputs to the DUT
    reg  [64:0] data1_in;
    reg  [64:0] data2_in;
    reg  [2:0]  rm_in;
    reg  [9:0]  class1_in;
    reg  [9:0]  class2_in;
    // Outputs from the DUT
    wire [63:0] result_out;
    wire [4:0]  flags_out;

    // Instantiate the Device Under Test (DUT)
    fp_cmp dut (
        .data1_in(data1_in),
        .data2_in(data2_in),
        .rm_in(rm_in),
        .class1_in(class1_in),
        .class2_in(class2_in),
        .result_out(result_out),
        .flags_out(flags_out)
    );

    // Registers to hold 64-bit IEEE 754 values for testing
    reg [63:0] val1, val2;

    // Function to compute the 10-bit class mask for a 64-bit double-precision value
    function [9:0] fclass64(input [63:0] val);
        reg sign;
        reg [10:0] exp;
        reg [51:0] frac;
        begin
            sign = val[63];
            exp  = val[62:52];
            frac = val[51:0];
            // Initialize all class bits to 0
            fclass64 = 10'b0;
            if (exp == 11'h7FF) begin  // Exponent all 1's => Inf or NaN
                if (frac == 0) begin
                    // Infinity
                    if (sign) 
                        fclass64[0] = 1'b1;   // -∞ (bit 0)
                    else     
                        fclass64[7] = 1'b1;   // +∞ (bit 7)
                end else begin
                    // NaN (exp all 1's, frac non-zero)
                    if (frac[51] == 1'b0) 
                        fclass64[8] = 1'b1;   // signaling NaN (bit 8)
                    else 
                        fclass64[9] = 1'b1;   // quiet NaN (bit 9)
                end
            end else if (exp == 11'h000) begin  // Exponent all 0's => zero or subnormal
                if (frac == 0) begin
                    // Zero
                    if (sign) 
                        fclass64[3] = 1'b1;   // -0 (bit 3)
                    else     
                        fclass64[4] = 1'b1;   // +0 (bit 4)
                end else begin
                    // Subnormal (denormalized number)
                    if (sign) 
                        fclass64[2] = 1'b1;   // negative subnormal (bit 2)
                    else     
                        fclass64[5] = 1'b1;   // positive subnormal (bit 5)
                end
            end else begin
                // Normalized finite number (exponent neither all 0's nor all 1's)
                if (sign) 
                    fclass64[1] = 1'b1;       // negative normal (bit 1)
                else     
                    fclass64[6] = 1'b1;       // positive normal (bit 6)
            end
        end
    endfunction

    integer total_tests = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    reg exp_result_bit;
    reg exp_invalid_flag;

    initial begin
        // 1. FEQ equal normals (e.g., 2.0 == 2.0)
        total_tests = total_tests + 1;
        val1 = 64'h4000000000000000;  // 2.0 (normal positive)
        val2 = 64'h4000000000000000;  // 2.0 (same value)
        rm_in = 3'd2;  // FEQ operation
        // Prepare inputs: {sign, magnitude} format
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: equal normals -> result = 1, no invalid flag
        exp_result_bit = 1'b1;
        exp_invalid_flag = 1'b0;
        #1;  // wait for combinational logic to settle
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FEQ equal normals         rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FEQ equal normals         rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)", 
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 2. FEQ +0 == -0
        total_tests = total_tests + 1;
        val1 = 64'h0000000000000000;  // +0.0
        val2 = 64'h8000000000000000;  // -0.0
        rm_in = 3'd2;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: +0 and -0 are considered equal -> result = 1, flags = 0
        exp_result_bit = 1'b1;
        exp_invalid_flag = 1'b0;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FEQ +0 == -0              rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FEQ +0 == -0              rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 3. FEQ qNaN vs 1.0
        total_tests = total_tests + 1;
        val1 = 64'h7FF8000000000000;  // quiet NaN
        val2 = 64'h3FF0000000000000;  // 1.0
        rm_in = 3'd2;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: any NaN (quiet) -> FEQ yields false (0) with no invalid flag
        exp_result_bit = 1'b0;
        exp_invalid_flag = 1'b0;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FEQ qNaN vs 1.0           rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FEQ qNaN vs 1.0           rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 4. FEQ sNaN vs qNaN
        total_tests = total_tests + 1;
        val1 = 64'h7FF0000000000001;  // signaling NaN
        val2 = 64'h7FF8000000000000;  // quiet NaN
        rm_in = 3'd2;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: sNaN present -> FEQ yields false (0) and raises invalid flag
        exp_result_bit = 1'b0;
        exp_invalid_flag = 1'b1;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FEQ sNaN vs qNaN          rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FEQ sNaN vs qNaN          rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 5. FEQ subnormal == subnormal
        total_tests = total_tests + 1;
        val1 = 64'h0000000000000001;  // smallest positive subnormal
        val2 = 64'h0000000000000001;  // same subnormal value
        rm_in = 3'd2;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: identical subnormals -> result = 1, flags = 0
        exp_result_bit = 1'b1;
        exp_invalid_flag = 1'b0;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FEQ subnormal             rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FEQ subnormal             rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 6. FLT -1 < 1
        total_tests = total_tests + 1;
        val1 = 64'hBFF0000000000000;  // -1.0
        val2 = 64'h3FF0000000000000;  // +1.0
        rm_in = 3'd1;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: -1.0 < 1.0 -> true (1), no flags
        exp_result_bit = 1'b1;
        exp_invalid_flag = 1'b0;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FLT -1 < 1                rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FLT -1 < 1                rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 7. FLT +0 !< -0  (0 is not less than 0)
        total_tests = total_tests + 1;
        val1 = 64'h0000000000000000;  // +0.0
        val2 = 64'h8000000000000000;  // -0.0
        rm_in = 3'd1;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: +0 !< -0 -> false (0), no flags (treat +0 == -0, so not less)
        exp_result_bit = 1'b0;
        exp_invalid_flag = 1'b0;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FLT +0 !< -0              rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FLT +0 !< -0              rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 8. FLT NaN involved (NaN vs number)
        total_tests = total_tests + 1;
        // Use a quiet NaN and a normal number with opposite sign
        val1 = 64'h7FF8000000000000;  // qNaN
        val2 = 64'hC000000000000000;  // -2.0
        rm_in = 3'd1;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: any NaN in FLT -> result = 0, invalid flag = 1 (invalid operation)
        exp_result_bit = 1'b0;
        exp_invalid_flag = 1'b1;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FLT NaN involved          rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FLT NaN involved          rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 9. FLT -Inf < +Inf
        total_tests = total_tests + 1;
        val1 = 64'hFFF0000000000000;  // -Infinity
        val2 = 64'h7FF0000000000000;  // +Infinity
        rm_in = 3'd1;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: -Inf < +Inf -> true (1), no flags
        exp_result_bit = 1'b1;
        exp_invalid_flag = 1'b0;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FLT -Inf < +Inf           rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FLT -Inf < +Inf           rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 10. FLE +0 <= -0
        total_tests = total_tests + 1;
        val1 = 64'h0000000000000000;  // +0.0
        val2 = 64'h8000000000000000;  // -0.0
        rm_in = 3'd0;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: +0 <= -0 -> true (1), no flags (zeros compare equal for <=)
        exp_result_bit = 1'b1;
        exp_invalid_flag = 1'b0;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FLE +0 <= -0              rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FLE +0 <= -0              rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 11. FLE NaN involved (number vs NaN)
        total_tests = total_tests + 1;
        // Use a negative finite number and a quiet NaN (opposite order from FLT test)
        val1 = 64'hC000000000000000;  // -2.0
        val2 = 64'h7FF8000000000000;  // qNaN
        rm_in = 3'd0;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: any NaN in FLE -> result = 0, invalid flag = 1
        exp_result_bit = 1'b0;
        exp_invalid_flag = 1'b1;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FLE NaN involved          rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FLE NaN involved          rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // 12. FLE +Inf <= +Inf
        total_tests = total_tests + 1;
        val1 = 64'h7FF0000000000000;  // +Infinity
        val2 = 64'h7FF0000000000000;  // +Infinity (same)
        rm_in = 3'd0;
        data1_in = {val1[63], (val1 & 64'h7FFFFFFFFFFFFFFF)};
        data2_in = {val2[63], (val2 & 64'h7FFFFFFFFFFFFFFF)};
        class1_in = fclass64(val1);
        class2_in = fclass64(val2);
        // Expected: +Inf <= +Inf -> true (1), no flags
        exp_result_bit = 1'b1;
        exp_invalid_flag = 1'b0;
        #1;
        if (result_out[0] === exp_result_bit && flags_out[4] === exp_invalid_flag) begin
            pass_count = pass_count + 1;
            $display("# [PASS] FLE +Inf <= +Inf          rm=%0d res=%0d flags=%0d", rm_in, result_out[0], flags_out[4]);
        end else begin
            fail_count = fail_count + 1;
            $display("# [FAIL] FLE +Inf <= +Inf          rm=%0d res=%0d flags=%0d (exp res=%0d flag=%0d)",
                     rm_in, result_out[0], flags_out[4], exp_result_bit, exp_invalid_flag);
        end

        // Summary of results
        $display("# ----------------------------------------------------");
        $display("# Total tests: %0d  Passed: %0d  Failed: %0d", total_tests, pass_count, fail_count);
        $finish;
    end
endmodule
