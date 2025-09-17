`timescale 1ns/1ps

module tb_fp_sgnj;

  // DUT inputs
  reg  [63:0] fp_sgnj_i_data1;
  reg  [63:0] fp_sgnj_i_data2;
  reg  [1:0]  fp_sgnj_i_fmt;   // 0: F32, 1: F64, others: expect 0 output
  reg  [2:0]  fp_sgnj_i_rm;    // 0: FSGNJ, 1: FSGNJN, 2: FSGNJX

  // DUT outputs
  wire [63:0] fp_sgnj_o_result;

  // Instantiate DUT
  fp_sgnj DUT (
    .fp_sgnj_i_data1(fp_sgnj_i_data1),
    .fp_sgnj_i_data2(fp_sgnj_i_data2),
    .fp_sgnj_i_fmt  (fp_sgnj_i_fmt),
    .fp_sgnj_i_rm   (fp_sgnj_i_rm),
    .fp_sgnj_o_result(fp_sgnj_o_result)
  );

  // ----------------------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------------------

  integer tests, fails;

  // Compute golden result for F32
  function [63:0] golden_f32;
    input [63:0] a;  // data1
    input [63:0] b;  // data2
    input [2:0]  rm; // op
    reg sign;
    reg [63:0] res;
    begin
      res        = 64'b0;
      res[30:0]  = a[30:0];
      case (rm)
        3'd0: sign = b[31];              // FSGNJ
        3'd1: sign = ~b[31];             // FSGNJN
        3'd2: sign = a[31] ^ b[31];      // FSGNJX
        default: sign = 1'b0;            // DUT leaves default if rm not 0..2
      endcase
      res[31]    = sign;
      golden_f32 = res;
    end
  endfunction

  // Compute golden result for F64
  function [63:0] golden_f64;
    input [63:0] a;  // data1
    input [63:0] b;  // data2
    input [2:0]  rm; // op
    reg sign;
    reg [63:0] res;
    begin
      res        = 64'b0;
      res[62:0]  = a[62:0];
      case (rm)
        3'd0: sign = b[63];              // FSGNJ
        3'd1: sign = ~b[63];             // FSGNJN
        3'd2: sign = a[63] ^ b[63];      // FSGNJX
        default: sign = 1'b0;
      endcase
      res[63]    = sign;
      golden_f64 = res;
    end
  endfunction

  task run_case;
    input [1:0] fmt;
    input [2:0] rm;
    input [63:0] d1;
    input [63:0] d2;
    reg   [63:0] expect;
    begin
      fp_sgnj_i_fmt   = fmt;
      fp_sgnj_i_rm    = rm;
      fp_sgnj_i_data1 = d1;
      fp_sgnj_i_data2 = d2;

      // Compute golden
      if (fmt == 2'd0) expect = golden_f32(d1, d2, rm);
      else if (fmt == 2'd1) expect = golden_f64(d1, d2, rm);
      else expect = 64'b0;

      #1; // allow combinational settle
      tests = tests + 1;

      if (fp_sgnj_o_result !== expect) begin
        fails = fails + 1;
        $display("[FAIL] fmt=%0d rm=%0d d1=0x%016h d2=0x%016h  got=0x%016h  exp=0x%016h",
                 fmt, rm, d1, d2, fp_sgnj_o_result, expect);
      end
    end
  endtask

  // ----------------------------------------------------------------------------
  // Directed edge-case vectors
  // ----------------------------------------------------------------------------

  // F32 constants (packed in low 32 bits; upper bits zero)
  localparam [63:0] F32_PZERO   = 64'h00000000_00000000; // +0
  localparam [63:0] F32_NZERO   = 64'h00000000_80000000; // -0
  localparam [63:0] F32_PONE    = 64'h00000000_3f800000; // +1.0
  localparam [63:0] F32_NONE    = 64'h00000000_bf800000; // -1.0
  localparam [63:0] F32_PINF    = 64'h00000000_7f800000; // +Inf
  localparam [63:0] F32_NINF    = 64'h00000000_ff800000; // -Inf
  localparam [63:0] F32_QNAN    = 64'h00000000_7fc00001; // qNaN
  localparam [63:0] F32_SNAN    = 64'h00000000_7f800001; // sNaN-ish (payload with MSB=0)
  localparam [63:0] F32_SUBP    = 64'h00000000_00000001; // +subnormal tiny
  localparam [63:0] F32_SUBN    = 64'h00000000_80000001; // -subnormal tiny

  // F64 constants
  localparam [63:0] F64_PZERO   = 64'h0000000000000000;  // +0
  localparam [63:0] F64_NZERO   = 64'h8000000000000000;  // -0
  localparam [63:0] F64_PONE    = 64'h3ff0000000000000;  // +1.0
  localparam [63:0] F64_NONE    = 64'hbff0000000000000;  // -1.0
  localparam [63:0] F64_PINF    = 64'h7ff0000000000000;  // +Inf
  localparam [63:0] F64_NINF    = 64'hfff0000000000000;  // -Inf
  localparam [63:0] F64_QNAN    = 64'h7ff8000000000001;  // qNaN
  localparam [63:0] F64_SNAN    = 64'h7ff0000000000001;  // sNaN-ish
  localparam [63:0] F64_SUBP    = 64'h0000000000000001;  // +subnormal tiny
  localparam [63:0] F64_SUBN    = 64'h8000000000000001;  // -subnormal tiny

  // ----------------------------------------------------------------------------
  // Test sequences
  // ----------------------------------------------------------------------------
  integer i, j, k;

  initial begin
    tests = 0;
    fails = 0;

    // -------------------------
    // Directed F32 tests
    // -------------------------
    for (j = 0; j <= 2; j = j + 1) begin : F32_rm_loop
      // (d1 magnitude preserved; sign from d2/rm)
      run_case(2'd0, j[2:0], F32_PZERO, F32_PZERO);
      run_case(2'd0, j[2:0], F32_NZERO, F32_PZERO);
      run_case(2'd0, j[2:0], F32_PONE , F32_PONE );
      run_case(2'd0, j[2:0], F32_NONE , F32_PONE );
      run_case(2'd0, j[2:0], F32_PONE , F32_NONE );
      run_case(2'd0, j[2:0], F32_PINF , F32_NINF );
      run_case(2'd0, j[2:0], F32_NINF , F32_PINF );
      run_case(2'd0, j[2:0], F32_QNAN , F32_SNAN );
      run_case(2'd0, j[2:0], F32_SUBP , F32_SUBN );
      run_case(2'd0, j[2:0], F32_SUBN , F32_SUBP );

      // Check sign-only effect w.r.t. zeros
      run_case(2'd0, j[2:0], 64'h00000000_12345678, F32_PZERO);
      run_case(2'd0, j[2:0], 64'h00000000_12345678, F32_NZERO);
      run_case(2'd0, j[2:0], 64'h00000000_92345678, F32_PONE);
      run_case(2'd0, j[2:0], 64'h00000000_92345678, F32_NONE);
    end

    // -------------------------
    // Directed F64 tests
    // -------------------------
    for (j = 0; j <= 2; j = j + 1) begin : F64_rm_loop
      run_case(2'd1, j[2:0], F64_PZERO, F64_PZERO);
      run_case(2'd1, j[2:0], F64_NZERO, F64_PZERO);
      run_case(2'd1, j[2:0], F64_PONE , F64_PONE );
      run_case(2'd1, j[2:0], F64_NONE , F64_PONE );
      run_case(2'd1, j[2:0], F64_PONE , F64_NONE );
      run_case(2'd1, j[2:0], F64_PINF , F64_NINF );
      run_case(2'd1, j[2:0], F64_NINF , F64_PINF );
      run_case(2'd1, j[2:0], F64_QNAN , F64_SNAN );
      run_case(2'd1, j[2:0], F64_SUBP , F64_SUBN );
      run_case(2'd1, j[2:0], F64_SUBN , F64_SUBP );

      run_case(2'd1, j[2:0], 64'h0123456789abcdef, F64_PZERO);
      run_case(2'd1, j[2:0], 64'h0123456789abcdef, F64_NZERO);
      run_case(2'd1, j[2:0], 64'h8123456789abcdef, F64_PONE);
      run_case(2'd1, j[2:0], 64'h8123456789abcdef, F64_NONE);
    end

    // -------------------------
    // Randomized tests (F32 + F64)
    // -------------------------
    for (i = 0; i < 500; i = i + 1) begin
      // Random F32: only lower 32 bits significant
      run_case(2'd0, {$random} % 3, {32'h0, $random}, {32'h0, $random});

      // Random F64: full 64-bit
      run_case(2'd1, {$random} % 3, {$random, $random}, {$random, $random});
    end

    // -------------------------
    // fmt not 0/1: expect zero result
    // -------------------------
    for (k = 0; k < 10; k = k + 1) begin
      run_case(2'd2, {$random} % 8, {$random, $random}, {$random, $random}); // fmt=2
      run_case(2'd3, {$random} % 8, {$random, $random}, {$random, $random}); // fmt=3
    end

    // Summary
    if (fails == 0) $display("\n[PASS] All %0d tests passed.", tests);
    else            $display("\n[FAIL] %0d / %0d tests failed.", fails, tests);

    $finish;
  end

endmodule
