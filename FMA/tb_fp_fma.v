`timescale 1ns/1ps

module tb_fp_fma;

  // Clock / reset / clear
  reg clock = 1'b0;
  reg reset = 1'b0;   // active-low per DUT
  reg clear = 1'b0;

  // DUT operand/control inputs
  reg  [64:0] fp_fma_i_data1;
  reg  [64:0] fp_fma_i_data2;
  reg  [64:0] fp_fma_i_data3;
  reg  [9:0]  fp_fma_i_class1;
  reg  [9:0]  fp_fma_i_class2;
  reg  [9:0]  fp_fma_i_class3;
  reg  [1:0]  fp_fma_i_fmt;      // 0=double, 1=single
  reg  [2:0]  fp_fma_i_rm;       // 0=RNE

  // Operation selects
  reg fp_fma_i_op_fmadd;
  reg fp_fma_i_op_fmsub;
  reg fp_fma_i_op_fnmadd;
  reg fp_fma_i_op_fnmsub;
  reg fp_fma_i_op_fadd;
  reg fp_fma_i_op_fsub;
  reg fp_fma_i_op_fmul;

  // LZC interface
  wire [255:0] lzc_i_a;  // from DUT
  reg  [7:0]   lzc_o_c;  // to DUT
  reg          lzc_o_v;  // to DUT

  // DUT outputs (pre-round bundle)
  wire        fp_fma_o_ready;
  wire        fp_fma_o_fp_rnd_sig;
  wire [13:0] fp_fma_o_fp_rnd_expo;
  wire [53:0] fp_fma_o_fp_rnd_mant;
  wire [1:0]  fp_fma_o_fp_rnd_rema;
  wire [1:0]  fp_fma_o_fp_rnd_fmt;
  wire [2:0]  fp_fma_o_fp_rnd_rm;
  wire [2:0]  fp_fma_o_fp_rnd_grs;
  wire        fp_fma_o_fp_rnd_snan;
  wire        fp_fma_o_fp_rnd_qnan;
  wire        fp_fma_o_fp_rnd_dbz;
  wire        fp_fma_o_fp_rnd_infs;
  wire        fp_fma_o_fp_rnd_zero;
  wire        fp_fma_o_fp_rnd_diff;

  // 10 ns clock
  always #5 clock = ~clock;

  // ------------------ Combinational "LZC responder" (pure Verilog) ------------------
  integer i;
  integer found;
  reg [7:0] lzc_count;

  always @* begin
    lzc_o_v   = 1'b1;
    lzc_count = 8'd255;   // default if vector all zeros
    found     = 0;

    // Count leading zeros from MSB (bit 255) down to 0
    for (i = 255; i >= 0; i = i - 1) begin
      if (!found && lzc_i_a[i]) begin
        lzc_count = 8'd255 - i[7:0];
        found     = 1;
      end
    end

    // DUT uses v_2_counter_mac = ~lzc_o_c;  -> give it one's complement
    lzc_o_c = ~lzc_count;
  end

  // ------------------ DUT ------------------
  fp_fma dut (
    .reset(reset),
    .clock(clock),

    .fp_fma_i_data1(fp_fma_i_data1),
    .fp_fma_i_data2(fp_fma_i_data2),
    .fp_fma_i_data3(fp_fma_i_data3),
    .fp_fma_i_class1(fp_fma_i_class1),
    .fp_fma_i_class2(fp_fma_i_class2),
    .fp_fma_i_class3(fp_fma_i_class3),
    .fp_fma_i_fmt(fp_fma_i_fmt),
    .fp_fma_i_rm(fp_fma_i_rm),

    .fp_fma_i_op_fmadd(fp_fma_i_op_fmadd),
    .fp_fma_i_op_fmsub(fp_fma_i_op_fmsub),
    .fp_fma_i_op_fnmadd(fp_fma_i_op_fnmadd),
    .fp_fma_i_op_fnmsub(fp_fma_i_op_fnmsub),
    .fp_fma_i_op_fadd(fp_fma_i_op_fadd),
    .fp_fma_i_op_fsub(fp_fma_i_op_fsub),
    .fp_fma_i_op_fmul(fp_fma_i_op_fmul),

    .fp_fma_o_ready(fp_fma_o_ready),

    .fp_fma_o_fp_rnd_sig(fp_fma_o_fp_rnd_sig),
    .fp_fma_o_fp_rnd_expo(fp_fma_o_fp_rnd_expo),
    .fp_fma_o_fp_rnd_mant(fp_fma_o_fp_rnd_mant),
    .fp_fma_o_fp_rnd_rema(fp_fma_o_fp_rnd_rema),
    .fp_fma_o_fp_rnd_fmt(fp_fma_o_fp_rnd_fmt),
    .fp_fma_o_fp_rnd_rm(fp_fma_o_fp_rnd_rm),
    .fp_fma_o_fp_rnd_grs(fp_fma_o_fp_rnd_grs),
    .fp_fma_o_fp_rnd_snan(fp_fma_o_fp_rnd_snan),
    .fp_fma_o_fp_rnd_qnan(fp_fma_o_fp_rnd_qnan),
    .fp_fma_o_fp_rnd_dbz(fp_fma_o_fp_rnd_dbz),
    .fp_fma_o_fp_rnd_infs(fp_fma_o_fp_rnd_infs),
    .fp_fma_o_fp_rnd_zero(fp_fma_o_fp_rnd_zero),
    .fp_fma_o_fp_rnd_diff(fp_fma_o_fp_rnd_diff),

    .lzc_o_c(lzc_o_c),
    .lzc_o_v(lzc_o_v),
    .lzc_i_a(lzc_i_a),

    .clear(clear)
  );

  // ------------------ helpers ------------------
  task drive_idle;
    begin
      fp_fma_i_op_fmadd  = 0;
      fp_fma_i_op_fmsub  = 0;
      fp_fma_i_op_fnmadd = 0;
      fp_fma_i_op_fnmsub = 0;
      fp_fma_i_op_fadd   = 0;
      fp_fma_i_op_fsub   = 0;
      fp_fma_i_op_fmul   = 0;
    end
  endtask

  // Hold op 2 cycles so stage-1 surely samples
  task kick_op2;
    input [64:0] a65;
    input [64:0] b65;
    input [64:0] c65;
    input [1:0]  fmt;
    input [2:0]  rm;
    input [6:0]  which; // {fmul,fsub,fadd,fnmsub,fnmadd,fmsub,fmadd}
    begin
      fp_fma_i_data1 = a65;
      fp_fma_i_data2 = b65;
      fp_fma_i_data3 = c65;
      fp_fma_i_fmt   = fmt;
      fp_fma_i_rm    = rm;

      fp_fma_i_op_fmadd  = which[0];
      fp_fma_i_op_fmsub  = which[1];
      fp_fma_i_op_fnmadd = which[2];
      fp_fma_i_op_fnmsub = which[3];
      fp_fma_i_op_fadd   = which[4];
      fp_fma_i_op_fsub   = which[5];
      fp_fma_i_op_fmul   = which[6];

      @(posedge clock);
      @(posedge clock);
      drive_idle();
    end
  endtask

  // Wait for ready (up to max_cyc); return a "got" flag
  task wait_ready;
    input integer max_cyc;
    output reg got;
    integer k;
    begin
      got = 1'b0;
      for (k = 0; k < max_cyc; k = k + 1) begin
        @(posedge clock);
        if (fp_fma_o_ready && !got) begin
          got = 1'b1;
        end
      end
    end
  endtask

  // Self-check for finite tests: sign/zero and no exceptions
  task check_case;
    input [127:0] name;
    input exp_sign;
    input exp_zero;
    input integer max_wait;
    reg got;
    integer pass;
    begin
      wait_ready(max_wait, got);

      pass = 1;

      if (!got) begin
        $display("[%0t] FAIL %-18s : never saw ready within %0d cycles",
                 $time, name, max_wait);
        pass = 0;
      end else begin
        if (fp_fma_o_fp_rnd_snan !== 1'b0) pass = 0;
        if (fp_fma_o_fp_rnd_qnan !== 1'b0) pass = 0;
        if (fp_fma_o_fp_rnd_infs !== 1'b0) pass = 0;
        if (fp_fma_o_fp_rnd_dbz !== 1'b0)  pass = 0;

        if (fp_fma_o_fp_rnd_sig  !== exp_sign) pass = 0;
        if (fp_fma_o_fp_rnd_zero !== exp_zero) pass = 0;

        $display("[%0t] %-18s ready=%0d sig=%0d expo=%0d mant=%h grs=%b  Z=%0d INF=%0d sNaN=%0d qNaN=%0d",
                 $time, name, fp_fma_o_ready, fp_fma_o_fp_rnd_sig, fp_fma_o_fp_rnd_expo,
                 fp_fma_o_fp_rnd_mant, fp_fma_o_fp_rnd_grs,
                 fp_fma_o_fp_rnd_zero, fp_fma_o_fp_rnd_infs,
                 fp_fma_o_fp_rnd_snan, fp_fma_o_fp_rnd_qnan);

        if (pass) $display("PASS: %0s", name);
        else      $display("FAIL: %0s  (expected sign=%0d zero=%0d; no exceptions)", name, exp_sign, exp_zero);
      end
    end
  endtask

  // Self-check for error-flag tests
  task check_flags;
    input [127:0] name;
    input exp_snan;
    input exp_qnan;
    input exp_infs;
    input integer max_wait;
    reg got;
    integer pass;
    begin
      wait_ready(max_wait, got);

      pass = 1;
      if (!got) begin
        $display("[%0t] FAIL %-18s : never saw ready within %0d cycles",
                 $time, name, max_wait);
        pass = 0;
      end else begin
        if (fp_fma_o_fp_rnd_snan !== exp_snan) pass = 0;
        if (fp_fma_o_fp_rnd_qnan !== exp_qnan) pass = 0;
        if (fp_fma_o_fp_rnd_infs !== exp_infs) pass = 0;

        $display("[%0t] %-18s ready=%0d sig=%0d expo=%0d mant=%h grs=%b  flags: Z=%0d INF=%0d sNaN=%0d qNaN=%0d",
                 $time, name, fp_fma_o_ready, fp_fma_o_fp_rnd_sig, fp_fma_o_fp_rnd_expo,
                 fp_fma_o_fp_rnd_mant, fp_fma_o_fp_rnd_grs,
                 fp_fma_o_fp_rnd_zero, fp_fma_o_fp_rnd_infs,
                 fp_fma_o_fp_rnd_snan, fp_fma_o_fp_rnd_qnan);

        if (pass) $display("PASS: %0s", name);
        else      $display("FAIL: %0s  (expected sNaN=%0d qNaN=%0d INF=%0d)", name, exp_snan, exp_qnan, exp_infs);
      end
    end
  endtask

  // ------------------ Stimulus ------------------
  localparam integer MAX_WAIT = 64; // generous in case your pipeline is deeper

  initial begin
    clear = 1'b0;
    drive_idle();
    fp_fma_i_fmt = 2'd0;   // double path
    fp_fma_i_rm  = 3'd0;   // RNE

    // Reset (active-low)
    reset = 1'b0;
    repeat (4) @(posedge clock);
    reset = 1'b1;
    @(posedge clock);

    // Default: classes = finite/normal (no special flags)
    fp_fma_i_class1 = 10'b0;
    fp_fma_i_class2 = 10'b0;
    fp_fma_i_class3 = 10'b0;

    // ---------- Finite Test 1: FMADD: (1.5 * 2.0) + 3.0 = +6.0 ----------
    kick_op2({1'b0, 64'h3FF8000000000000},   // A = +1.5
             {1'b0, 64'h4000000000000000},   // B = +2.0
             {1'b0, 64'h4008000000000000},   // C = +3.0
             2'd0, 3'd0, 7'b0000001);        // fmadd
    check_case("FMADD 1.5*2+3", 1'b0, 1'b0, MAX_WAIT);

    // ---------- Finite Test 2: FADD:  2.5 + 1.5 = +4.0 ----------
    // DUT morphs FADD: sets B=1.0 internally and uses C=former B; classes below remain finite
    kick_op2({1'b0, 64'h4004000000000000},   // A = +2.5
             {1'b0, 64'h0000000000000000},   // ignored for fadd morphing
             {1'b0, 64'h3FF8000000000000},   // C = +1.5
             2'd0, 3'd0, 7'b0010000);        // fadd
    check_case("FADD  2.5+1.5", 1'b0, 1'b0, MAX_WAIT);

    // ---------- Finite Test 3: FMUL:  (-3.0) * (0.5) = -1.5 ----------
    kick_op2({1'b1, 64'h4008000000000000},   // A = -3.0
             {1'b0, 64'h3FE0000000000000},   // B = +0.5
             {1'b0, 64'h0000000000000000},   // ignored for fmul morphing
             2'd0, 3'd0, 7'b1000000);        // fmul
    check_case("FMUL  -3*0.5", 1'b1, 1'b0, MAX_WAIT);

    // ===================== Error-Flag Testcases =====================

    // --- Error 1: sNaN in A (expect sNaN=1) ---
    // Class bit[8] is used by the DUT to signal sNaN presence.
    fp_fma_i_class1 = 10'h100;   // sNaN in A
    fp_fma_i_class2 = 10'h000;   // finite
    fp_fma_i_class3 = 10'h000;   // finite
    kick_op2({1'b0, 64'h7FF0000000000001},   // A payload (sNaN-ish), class drives the flag
             {1'b0, 64'h3FF0000000000000},   // B = +1.0
             {1'b0, 64'h3FF0000000000000},   // C = +1.0
             2'd0, 3'd0, 7'b0000001);        // fmadd
    check_flags("ERR sNaN in A", 1'b1, 1'b0, 1'b0, MAX_WAIT);

    // --- Error 2: qNaN in C (expect qNaN=1) ---
    // Class bit[9] is used by the DUT to signal qNaN presence.
    fp_fma_i_class1 = 10'h000;   // finite
    fp_fma_i_class2 = 10'h000;   // finite
    fp_fma_i_class3 = 10'h200;   // qNaN in C
    kick_op2({1'b0, 64'h3FF8000000000000},   // A = 1.5
             {1'b0, 64'h4000000000000000},   // B = 2.0
             {1'b0, 64'h7FF8000000000000},   // C payload (qNaN-ish)
             2'd0, 3'd0, 7'b0000001);        // fmadd
    check_flags("ERR qNaN in C", 1'b0, 1'b1, 1'b0, MAX_WAIT);

    // --- Error 3: INF * 0 (invalid => DUT sets sNaN=1) ---
    // The design checks (Inf * 0) or (0 * Inf) and raises sNaN (invalid).
    // It uses class bits [0] or [7] for infinities and [3] or [4] for zeros.
    fp_fma_i_class1 = 10'h001;   // treat A as Inf (per design's class decoding)
    fp_fma_i_class2 = 10'h008;   // treat B as Zero
    fp_fma_i_class3 = 10'h000;   // finite
    kick_op2({1'b0, 64'h7FF0000000000000},   // A = +Inf encoding
             {1'b0, 64'h0000000000000000},   // B = +0
             {1'b0, 64'h3FF0000000000000},   // C = +1.0
             2'd0, 3'd0, 7'b0000001);        // fmadd (engages multiply path)
    check_flags("ERR Inf*0 invalid", 1'b1, 1'b0, 1'b0, MAX_WAIT);

    // --- Error 4: INF propagation (expect infs=1, no sNaN/qNaN) ---
    // Any operand marked as Inf (and no invalid condition) sets the 'infs' flag.
    fp_fma_i_class1 = 10'h001;   // Inf in A
    fp_fma_i_class2 = 10'h000;   // finite
    fp_fma_i_class3 = 10'h000;   // finite
    kick_op2({1'b0, 64'h7FF0000000000000},   // A = +Inf
             {1'b0, 64'h3FF0000000000000},   // B = +1.0
             {1'b0, 64'h3FF0000000000000},   // C = +1.0
             2'd0, 3'd0, 7'b0010000);        // fadd (add form)
    check_flags("ERR Inf propagate", 1'b0, 1'b0, 1'b1, MAX_WAIT);

    $display("All tests complete.");
    $finish;
  end

endmodule
