`timescale 1ns/1ps

module tb_fp_max;

  // ----------------------------------
  // DUT I/O 
  // ----------------------------------
  reg  [63:0] fp_max_in_data1;
  reg  [63:0] fp_max_in_data2;
  reg  [64:0] fp_max_in_ext1;
  reg  [64:0] fp_max_in_ext2;
  reg  [1:0]  fp_max_in_fmt;
  reg  [2:0]  fp_max_in_rm;
  reg  [9:0]  fp_max_in_class1;
  reg  [9:0]  fp_max_in_class2;

  wire [63:0] fp_max_out_result_out;
  wire [4:0]  fp_max_out_flags_out;

  // ----------------------------------
  // Instantiate DUT
  // ----------------------------------
  fp_max dut (
    .fp_max_in_data1       (fp_max_in_data1),
    .fp_max_in_data2       (fp_max_in_data2),
    .fp_max_in_ext1        (fp_max_in_ext1),
    .fp_max_in_ext2        (fp_max_in_ext2),
    .fp_max_in_fmt         (fp_max_in_fmt),
    .fp_max_in_rm          (fp_max_in_rm),
    .fp_max_in_class1      (fp_max_in_class1),
    .fp_max_in_class2      (fp_max_in_class2),
    .fp_max_out_result_out (fp_max_out_result_out),
    .fp_max_out_flags_out  (fp_max_out_flags_out)
  );

  // ----------------------------------
  // Constants / helpers 
  // ----------------------------------
  // class[*] bit positions used by DUT
  parameter SNaN_BIT = 8;
  parameter QNaN_BIT = 9;

  // Canonical quiet NaNs used by DUT
  parameter [63:0] QNAN64       = 64'h7ff8000000000000;
  parameter [63:0] QNAN32_IN64  = 64'h000000007fc00000;

  // Build the class vector with only sNaN/qNaN bits set as needed
  function [9:0] mk_class;
    input is_snan; // 1-bit
    input is_qnan; // 1-bit
    begin
      mk_class           = 10'b0;
      mk_class[SNaN_BIT] = is_snan;
      mk_class[QNaN_BIT] = is_qnan;
    end
  endfunction

  // Build extend field: [64]=sign, [63:0]=magnitude key
  function [64:0] mk_extend;
    input sign;            // 1-bit
    input [63:0] mag_key;  // magnitude key
    begin
      mk_extend = {sign, mag_key};
    end
  endfunction

  integer error_count;

  // Classes used
  reg [9:0] CLASS_NUM;
  reg [9:0] CLASS_QNAN;
  reg [9:0] CLASS_SNAN;

  // Operand payloads 
  reg [63:0] VAL_A, VAL_B, VAL_C, VAL_PZ, VAL_NZ;

  // Magnitude keys 
  reg [63:0] MAG_10, MAG_20, MAG_EQ, MAG_0;

  // Self-checking vector driver (name passed as packed string)
  task check_vec;
    input [8*40-1:0] name; // up to 40 chars
    input [63:0] d1;
    input [63:0] d2;
    input [64:0] e1;
    input [64:0] e2;
    input [1:0]  fmt;
    input [2:0]  rm;
    input [9:0]  c1;
    input [9:0]  c2;
    input [63:0] exp_res;
    input [4:0]  exp_flags;
    begin
      // Drive
      fp_max_in_data1  = d1;
      fp_max_in_data2  = d2;
      fp_max_in_ext1   = e1;
      fp_max_in_ext2   = e2;
      fp_max_in_fmt    = fmt;
      fp_max_in_rm     = rm;
      fp_max_in_class1 = c1;
      fp_max_in_class2 = c2;

      // Let comb settle
      #1;

      // Check
      if (fp_max_out_result_out !== exp_res || fp_max_out_flags_out !== exp_flags) begin
        $display("FAIL %0s | rm=%0d fmt=%0d | got res=%h flg=%b  exp res=%h flg=%b",
                 name, rm, fmt, fp_max_out_result_out, fp_max_out_flags_out, exp_res, exp_flags);
        error_count = error_count + 1;
      end else begin
        $display("PASS %0s | rm=%0d fmt=%0d | res=%h flg=%b",
                 name, rm, fmt, fp_max_out_result_out, fp_max_out_flags_out);
      end
    end
  endtask

  // ----------------------------------
  // Test stimulus
  // ----------------------------------
  initial begin
    $display("=== fp_max direct self-checking testbench (pure Verilog) ===");
    error_count = 0;

    // Initialize classes and constants
    CLASS_NUM  = mk_class(1'b0, 1'b0);
    CLASS_QNAN = mk_class(1'b0, 1'b1);
    CLASS_SNAN = mk_class(1'b1, 1'b0);

    VAL_A = 64'h4000000000000001;
    VAL_B = 64'h4000000000000002;
    VAL_C = 64'h3ff0000000000000;
    VAL_PZ = 64'h0000000000000000; // +0 payload (sign via extend)
    VAL_NZ = 64'h8000000000000000; // -0 payload (sign via extend)

    MAG_10 = 64'd10;
    MAG_20 = 64'd20;
    MAG_EQ = 64'd33; // equal magnitudes to test tie paths
    MAG_0  = 64'd0;

    // 1) Positives, different magnitudes
    check_vec("pos|min small vs big",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd0, CLASS_NUM, CLASS_NUM,
      VAL_A, 5'b00000);

    check_vec("pos|max small vs big",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd1, CLASS_NUM, CLASS_NUM,
      VAL_B, 5'b00000);

    // 2) Negatives, different magnitudes
    check_vec("neg|min |10| vs |20|",
      VAL_A, VAL_B, mk_extend(1'b1,MAG_10), mk_extend(1'b1,MAG_20),
      2'd1, 3'd0, CLASS_NUM, CLASS_NUM,
      VAL_B, 5'b00000);

    check_vec("neg|max |10| vs |20|",
      VAL_A, VAL_B, mk_extend(1'b1,MAG_10), mk_extend(1'b1,MAG_20),
      2'd1, 3'd1, CLASS_NUM, CLASS_NUM,
      VAL_A, 5'b00000);

    // 3) Mixed sign
    check_vec("mixed|min neg vs pos",
      VAL_A, VAL_B, mk_extend(1'b1,MAG_20), mk_extend(1'b0,MAG_10),
      2'd1, 3'd0, CLASS_NUM, CLASS_NUM,
      VAL_A, 5'b00000);

    check_vec("mixed|max neg vs pos",
      VAL_A, VAL_B, mk_extend(1'b1,MAG_20), mk_extend(1'b0,MAG_10),
      2'd1, 3'd1, CLASS_NUM, CLASS_NUM,
      VAL_B, 5'b00000);

    // 4) Ties (same sign, equal magnitude)
    check_vec("tie pos|min",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_EQ), mk_extend(1'b0,MAG_EQ),
      2'd1, 3'd0, CLASS_NUM, CLASS_NUM,
      VAL_A, 5'b00000);

    check_vec("tie pos|max",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_EQ), mk_extend(1'b0,MAG_EQ),
      2'd1, 3'd1, CLASS_NUM, CLASS_NUM,
      VAL_B, 5'b00000);

    check_vec("tie neg|min",
      VAL_A, VAL_B, mk_extend(1'b1,MAG_EQ), mk_extend(1'b1,MAG_EQ),
      2'd1, 3'd0, CLASS_NUM, CLASS_NUM,
      VAL_B, 5'b00000);

    check_vec("tie neg|max",
      VAL_A, VAL_B, mk_extend(1'b1,MAG_EQ), mk_extend(1'b1,MAG_EQ),
      2'd1, 3'd1, CLASS_NUM, CLASS_NUM,
      VAL_A, 5'b00000);

    // 5) Zeros (+0 vs -0)
    check_vec("+0 vs -0 | MIN",
      VAL_PZ, VAL_NZ, mk_extend(1'b0,MAG_0), mk_extend(1'b1,MAG_0),
      2'd1, 3'd0, CLASS_NUM, CLASS_NUM,
      VAL_NZ, 5'b00000);

    check_vec("+0 vs -0 | MAX",
      VAL_PZ, VAL_NZ, mk_extend(1'b0,MAG_0), mk_extend(1'b1,MAG_0),
      2'd1, 3'd1, CLASS_NUM, CLASS_NUM,
      VAL_PZ, 5'b00000);

    // 6) qNaN propagation
    check_vec("qNaN vs qNaN (fmt=64)",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd0, CLASS_QNAN, CLASS_QNAN,
      QNAN64, 5'b00000);

    check_vec("qNaN vs number -> other",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd1, CLASS_QNAN, CLASS_NUM,
      VAL_B, 5'b00000);

    check_vec("number vs qNaN -> other",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd0, CLASS_NUM, CLASS_QNAN,
      VAL_A, 5'b00000);

    // 7) sNaN cases (invalid flag set)
    check_vec("sNaN vs sNaN -> NaN, invalid",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd0, CLASS_SNAN, CLASS_SNAN,
      QNAN64, 5'b10000);

    check_vec("sNaN vs number -> other, invalid",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd1, CLASS_SNAN, CLASS_NUM,
      VAL_B, 5'b10000);

    check_vec("number vs sNaN -> other, invalid",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd0, CLASS_NUM, CLASS_SNAN,
      VAL_A, 5'b10000);

    check_vec("sNaN vs qNaN -> other, invalid",
      64'h0000000000001111, 64'h0000000000002222,
      mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd1, CLASS_SNAN, CLASS_QNAN,
      64'h0000000000002222, 5'b10000);

    check_vec("qNaN vs sNaN -> other, invalid",
      64'h000000000000AAAA, 64'h000000000000BBBB,
      mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd1, 3'd0, CLASS_QNAN, CLASS_SNAN,
      64'h000000000000AAAA, 5'b10000);

    // 8) fmt = single (fmt=0) — NaN constant selection check
    check_vec("fmt=single qNaN vs qNaN",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_10), mk_extend(1'b0,MAG_20),
      2'd0, 3'd0, CLASS_QNAN, CLASS_QNAN,
      QNAN32_IN64, 5'b00000);

    check_vec("fmt=single sNaN vs number -> other, invalid",
      VAL_A, VAL_B, mk_extend(1'b0,MAG_20), mk_extend(1'b0,MAG_10),
      2'd0, 3'd1, CLASS_SNAN, CLASS_NUM,
      VAL_B, 5'b10000);

    // 9) Large magnitude ordering (treated as normals by DUT)
    check_vec("pos|max big vs small",
      64'h7ff0000000000000, 64'h3ff0000000000000,
      mk_extend(1'b0,64'd1000000), mk_extend(1'b0,64'd1),
      2'd1, 3'd1, CLASS_NUM, CLASS_NUM,
      64'h7ff0000000000000, 5'b00000);

    check_vec("neg|min big vs small",
      64'hfff0000000000000, 64'hbff0000000000000,
      mk_extend(1'b1,64'd1000000), mk_extend(1'b1,64'd1),
      2'd1, 3'd0, CLASS_NUM, CLASS_NUM,
      64'hfff0000000000000, 5'b00000);

    // Summary
    if (error_count == 0)
      $display("=== ALL TESTS PASSED ===");
    else
      $display("=== TESTS FAILED: %0d error(s) ===", error_count);

    $finish;
  end

endmodule
