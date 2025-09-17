// ============================================================================
// Module: fp_fma  (Fused Multiply-Add)  -- Verilog
// Role  : Part of a RISC-V F/D (single/double precision) FPU pipeline.
// Op    : Computes (A * B) ± C with normalization and rounding-prep (GRS).
// ============================================================================

`timescale 1ns/1ps

module fp_fma (
  // Global
  input        reset,         // active-low reset
  input        clock,

  // Flattened fp_fma_in_type
  input  [64:0] fp_fma_i_data1,     // A  [sign|exp|mant(implicit-one included when normal)]
  input  [64:0] fp_fma_i_data2,     // B
  input  [64:0] fp_fma_i_data3,     // C
  input  [9:0]  fp_fma_i_class1,    // class bits for A
  input  [9:0]  fp_fma_i_class2,    // class bits for B
  input  [9:0]  fp_fma_i_class3,    // class bits for C
  input  [1:0]  fp_fma_i_fmt,       // 0=double, 1=single
  input  [2:0]  fp_fma_i_rm,        // rounding mode (forwarded downstream)

  // Flattened fp_operation_type (only ops used by this unit)
  input  fp_fma_i_op_fmadd,
  input  fp_fma_i_op_fmsub,
  input  fp_fma_i_op_fnmadd,
  input  fp_fma_i_op_fnmsub,
  input  fp_fma_i_op_fadd,
  input  fp_fma_i_op_fsub,
  input  fp_fma_i_op_fmul,

  // Flattened fp_fma_out_type.fp_rnd (pre-round bundle) + ready
  output reg        fp_fma_o_fp_rnd_sig,
  output reg [13:0] fp_fma_o_fp_rnd_expo,  // unbiased exponent after normalization/subnorm handling
  output reg [53:0] fp_fma_o_fp_rnd_mant,  // extracted magnitude (with leading 1 at bit[53])
  output reg [1:0]  fp_fma_o_fp_rnd_rema,  // not used here; zeros
  output reg [1:0]  fp_fma_o_fp_rnd_fmt,
  output reg [2:0]  fp_fma_o_fp_rnd_rm,
  output reg [2:0]  fp_fma_o_fp_rnd_grs,   // {G,R,S}
  output reg        fp_fma_o_fp_rnd_snan,
  output reg        fp_fma_o_fp_rnd_qnan,
  output reg        fp_fma_o_fp_rnd_dbz,
  output reg        fp_fma_o_fp_rnd_infs,
  output reg        fp_fma_o_fp_rnd_zero,
  output reg        fp_fma_o_fp_rnd_diff,
  output reg        fp_fma_o_ready,

  // Flattened lzc_256 interface
  input  [7:0]      lzc_o_c,         // leading-zero count result (external LZC)
  input             lzc_o_v,         // valid (not explicitly consumed here)
  output reg [255:0] lzc_i_a,        // vector to LZC (mantissa magnitude for normalization)

  // Flush-like control
  input             clear
);

  // ===========================================================================
  // Pipeline/state registers (r_1 between stage-1 and stage-2, r_2 output regs)
  // ===========================================================================
  // r_1: latched unpack/alignment parameters
  reg [1:0]   r_1_fmt;
  reg [2:0]   r_1_rm;
  reg         r_1_snan, r_1_qnan, r_1_dbz, r_1_infs, r_1_zero;
  reg         r_1_sign_mul, r_1_sign_add;
  reg [13:0]  r_1_exponent_mul, r_1_exponent_add;
  reg [163:0] r_1_mantissa_mul, r_1_mantissa_add;
  reg         r_1_exponent_neg;
  reg         r_1_ready;

  // r_1 pipelined operation controls (optional/for visibility)
  reg r_1_op_fmadd, r_1_op_fmsub, r_1_op_fnmadd, r_1_op_fnmsub, r_1_op_fadd, r_1_op_fsub, r_1_op_fmul;

  // r_2: post-add/normalize, pre-round/pack
  reg         r_2_sign_rnd;
  reg [13:0]  r_2_exponent_rnd;
  reg [53:0]  r_2_mantissa_rnd;
  reg [1:0]   r_2_fmt;
  reg [2:0]   r_2_rm;
  reg [2:0]   r_2_grs;
  reg         r_2_snan, r_2_qnan, r_2_dbz, r_2_infs, r_2_zero, r_2_diff;
  reg         r_2_ready;

  // next-state for r_1/r_2
  reg [1:0]   rin_1_fmt;
  reg [2:0]   rin_1_rm;
  reg         rin_1_snan, rin_1_qnan, rin_1_dbz, rin_1_infs, rin_1_zero;
  reg         rin_1_sign_mul, rin_1_sign_add;
  reg [13:0]  rin_1_exponent_mul, rin_1_exponent_add;
  reg [163:0] rin_1_mantissa_mul, rin_1_mantissa_add;
  reg         rin_1_exponent_neg;
  reg         rin_1_ready;
  reg         rin_1_op_fmadd, rin_1_op_fmsub, rin_1_op_fnmadd, rin_1_op_fnmsub, rin_1_op_fadd, rin_1_op_fsub, rin_1_op_fmul;

  reg         rin_2_sign_rnd;
  reg [13:0]  rin_2_exponent_rnd;
  reg [53:0]  rin_2_mantissa_rnd;
  reg [1:0]   rin_2_fmt;
  reg [2:0]   rin_2_rm;
  reg [2:0]   rin_2_grs;
  reg         rin_2_snan, rin_2_qnan, rin_2_dbz, rin_2_infs, rin_2_zero, rin_2_diff;
  reg         rin_2_ready;
  reg         rin_2_op_fmadd, rin_2_op_fmsub, rin_2_op_fnmadd, rin_2_op_fnmsub, rin_2_op_fadd, rin_2_op_fsub, rin_2_op_fmul; // (kept for symmetry)

  // ===========================================================================
  // Stage 1: Unpack, Morph to FMA form (if add/sub/mul), Align Magnitudes
  // ===========================================================================
  reg [64:0]  v_1_a, v_1_b, v_1_c;
  reg [9:0]   v_1_class_a, v_1_class_b, v_1_class_c;
  reg [1:0]   v_1_fmt;
  reg [2:0]   v_1_rm;
  reg         v_1_snan, v_1_qnan, v_1_dbz, v_1_infs, v_1_zero;
  reg         v_1_sign_a, v_1_sign_b, v_1_sign_c;
  reg [11:0]  v_1_exponent_a, v_1_exponent_b, v_1_exponent_c;
  reg [52:0]  v_1_mantissa_a, v_1_mantissa_b, v_1_mantissa_c;
  reg         v_1_sign_mul, v_1_sign_add;
  reg [13:0]  v_1_exponent_mul, v_1_exponent_add, v_1_exponent_dif;
  reg [163:0] v_1_mantissa_mul, v_1_mantissa_add, v_1_mantissa_l, v_1_mantissa_r;
  reg [6:0]   v_1_counter_dif;
  reg         v_1_exponent_neg;
  reg         v_1_ready;

  always @* begin
    // Bring inputs
    v_1_a       = fp_fma_i_data1;
    v_1_b       = fp_fma_i_data2;
    v_1_c       = fp_fma_i_data3;
    v_1_class_a = fp_fma_i_class1;
    v_1_class_b = fp_fma_i_class2;
    v_1_class_c = fp_fma_i_class3;
    v_1_fmt     = fp_fma_i_fmt;
    v_1_rm      = fp_fma_i_rm;

    // Ready if any op used by this unit is asserted
    v_1_ready = fp_fma_i_op_fmadd | fp_fma_i_op_fmsub | fp_fma_i_op_fnmsub | fp_fma_i_op_fnmadd
              | fp_fma_i_op_fadd  | fp_fma_i_op_fsub  | fp_fma_i_op_fmul;

    // Morph add/sub as FMA with B=1.0 and C = prior B
    if (fp_fma_i_op_fadd | fp_fma_i_op_fsub) begin
      v_1_c       = v_1_b;
      v_1_class_c = v_1_class_b;
      v_1_b       = 65'h07FF0000000000000;  // canonical +1.0 (implicit-1 encoding for this datapath)
      v_1_class_b = 10'h040;
    end

    // Morph pure multiply as FMA with C=±0 (sign from A^B)
    if (fp_fma_i_op_fmul) begin
      v_1_c       = {v_1_a[64] ^ v_1_b[64], 64'h0000000000000000};
      v_1_class_c = 10'h000;
    end

    // Unpack to explicit mantissas (include hidden-1 when exponent!=0)
    v_1_sign_a     = v_1_a[64];  v_1_exponent_a = v_1_a[63:52];  v_1_mantissa_a = {|v_1_exponent_a, v_1_a[51:0]};
    v_1_sign_b     = v_1_b[64];  v_1_exponent_b = v_1_b[63:52];  v_1_mantissa_b = {|v_1_exponent_b, v_1_b[51:0]};
    v_1_sign_c     = v_1_c[64];  v_1_exponent_c = v_1_c[63:52];  v_1_mantissa_c = {|v_1_exponent_c, v_1_c[51:0]};

    // Determine leg signs using current op inputs
    v_1_sign_add = v_1_sign_c ^ (fp_fma_i_op_fmsub | fp_fma_i_op_fnmadd | fp_fma_i_op_fsub);
    v_1_sign_mul = (v_1_sign_a ^ v_1_sign_b) ^ (fp_fma_i_op_fnmsub | fp_fma_i_op_fnmadd);

    // Special cases (sNaN/qNaN/Inf*0)
    v_1_snan = 1'b0; v_1_qnan = 1'b0; v_1_dbz = 1'b0; v_1_infs = 1'b0; v_1_zero = 1'b0;
    if (v_1_class_a[8] | v_1_class_b[8] | v_1_class_c[8]) begin
      v_1_snan = 1'b1;
    end else if (((v_1_class_a[3] | v_1_class_a[4]) & (v_1_class_b[0] | v_1_class_b[7]))
              |  ((v_1_class_b[3] | v_1_class_b[4]) & (v_1_class_a[0] | v_1_class_a[7]))) begin
      v_1_snan = 1'b1;
    end else if (v_1_class_a[9] | v_1_class_b[9] | v_1_class_c[9]) begin
      v_1_qnan = 1'b1;
    end else if (((v_1_class_a[0] | v_1_class_a[7]) | (v_1_class_b[0] | v_1_class_b[7]))
              &  ((v_1_class_c[0] | v_1_class_c[7]) & (v_1_sign_add != v_1_sign_mul))) begin
      v_1_snan = 1'b1;
    end else if ((v_1_class_a[0] | v_1_class_a[7]) | (v_1_class_b[0] | v_1_class_b[7]) | (v_1_class_c[0] | v_1_class_c[7])) begin
      v_1_infs = 1'b1;
    end

    // Exponent lanes (unbiased)
    v_1_exponent_add = $signed({2'b00, v_1_exponent_c});
    v_1_exponent_mul = $signed({2'b00, v_1_exponent_a}) + $signed({2'b00, v_1_exponent_b}) - 14'd2047;

    if (&v_1_exponent_c)                v_1_exponent_add = 14'h0FFF;
    if (&v_1_exponent_a | &v_1_exponent_b) v_1_exponent_mul = 14'h0FFF;

    // Build wide mantissas for alignment
    v_1_mantissa_add[163:161] = 3'b000;
    v_1_mantissa_add[160:108] = v_1_mantissa_c;
    v_1_mantissa_add[107:0]   = 108'h0;

    v_1_mantissa_mul[163:162] = 2'b00;
    v_1_mantissa_mul[161:56]  = v_1_mantissa_a * v_1_mantissa_b; // 53x53 = 106 bits
    v_1_mantissa_mul[55:0]    = 56'h0;

    // Align smaller exponent leg to the larger
    v_1_exponent_dif = $signed(v_1_exponent_mul) - $signed(v_1_exponent_add);
    v_1_exponent_neg = v_1_exponent_dif[13];

    if (v_1_exponent_neg) begin
      v_1_counter_dif = 7'd56;
      if ($signed(v_1_exponent_dif) > -56) v_1_counter_dif = -v_1_exponent_dif[6:0];
      v_1_mantissa_l  = v_1_mantissa_add;
      v_1_mantissa_r  = v_1_mantissa_mul >> v_1_counter_dif;
      v_1_mantissa_add = v_1_mantissa_l;
      v_1_mantissa_mul = v_1_mantissa_r;
    end else begin
      v_1_counter_dif = 7'd108;
      if ($signed(v_1_exponent_dif) < 108) v_1_counter_dif =  v_1_exponent_dif[6:0];
      v_1_mantissa_l  = v_1_mantissa_mul;
      v_1_mantissa_r  = v_1_mantissa_add >> v_1_counter_dif;
      v_1_mantissa_add = v_1_mantissa_r;
      v_1_mantissa_mul = v_1_mantissa_l;
    end

    // Flush-like control
    if (clear == 1'b1) v_1_ready = 1'b0;

    // Drive next-state for r_1
    rin_1_fmt          = v_1_fmt;
    rin_1_rm           = v_1_rm;
    rin_1_snan         = v_1_snan;
    rin_1_qnan         = v_1_qnan;
    rin_1_dbz          = v_1_dbz;
    rin_1_infs         = v_1_infs;
    rin_1_zero         = v_1_zero;
    rin_1_sign_mul     = v_1_sign_mul;
    rin_1_exponent_mul = v_1_exponent_mul;
    rin_1_mantissa_mul = v_1_mantissa_mul;
    rin_1_sign_add     = v_1_sign_add;
    rin_1_exponent_add = v_1_exponent_add;
    rin_1_mantissa_add = v_1_mantissa_add;
    rin_1_exponent_neg = v_1_exponent_neg;
    rin_1_ready        = v_1_ready;

    // Pipeline op controls
    rin_1_op_fmadd  = fp_fma_i_op_fmadd;
    rin_1_op_fmsub  = fp_fma_i_op_fmsub;
    rin_1_op_fnmadd = fp_fma_i_op_fnmadd;
    rin_1_op_fnmsub = fp_fma_i_op_fnmsub;
    rin_1_op_fadd   = fp_fma_i_op_fadd;
    rin_1_op_fsub   = fp_fma_i_op_fsub;
    rin_1_op_fmul   = fp_fma_i_op_fmul;
  end

  // ===========================================================================
  // Stage 2: Two’s-Complement Add/Sub, Normalize via LZC, Extract + GRS
  // ===========================================================================
  reg [1:0]   v_2_fmt;  reg [2:0] v_2_rm;
  reg         v_2_snan, v_2_qnan, v_2_dbz, v_2_infs, v_2_zero, v_2_diff;
  reg         v_2_sign_mul, v_2_sign_add, v_2_sign_mac, v_2_sign_rnd;
  reg         v_2_exponent_neg;
  reg [13:0]  v_2_exponent_mul, v_2_exponent_add, v_2_exponent_mac, v_2_exponent_rnd, v_2_counter_sub;
  reg [163:0] v_2_mantissa_mul, v_2_mantissa_add, v_2_mantissa_mac;
  reg [7:0]   v_2_counter_mac;
  reg [10:0]  v_2_bias;
  reg [53:0]  v_2_mantissa_rnd;
  reg [2:0]   v_2_grs;
  reg         v_2_ready;

  always @* begin
    // Bring forward stage-1 results
    v_2_fmt          = r_1_fmt;
    v_2_rm           = r_1_rm;
    v_2_snan         = r_1_snan;
    v_2_qnan         = r_1_qnan;
    v_2_dbz          = r_1_dbz;
    v_2_infs         = r_1_infs;
    v_2_zero         = r_1_zero;
    v_2_sign_mul     = r_1_sign_mul;
    v_2_exponent_mul = r_1_exponent_mul;
    v_2_mantissa_mul = r_1_mantissa_mul;
    v_2_sign_add     = r_1_sign_add;
    v_2_exponent_add = r_1_exponent_add;
    v_2_mantissa_add = r_1_mantissa_add;
    v_2_exponent_neg = r_1_exponent_neg;
    v_2_ready        = r_1_ready;

    // For symmetry (optional)
    rin_2_op_fmadd  = r_1_op_fmadd;
    rin_2_op_fmsub  = r_1_op_fmsub;
    rin_2_op_fnmadd = r_1_op_fnmadd;
    rin_2_op_fnmsub = r_1_op_fnmsub;
    rin_2_op_fadd   = r_1_op_fadd;
    rin_2_op_fsub   = r_1_op_fsub;
    rin_2_op_fmul   = r_1_op_fmul;

    // Base exponent from dominant leg
    v_2_exponent_mac = (v_2_exponent_neg) ? v_2_exponent_add : v_2_exponent_mul;

    // Two's-complement add/sub (invert lanes if subtracting)
    if (v_2_sign_add) v_2_mantissa_add = ~v_2_mantissa_add;
    if (v_2_sign_mul) v_2_mantissa_mul = ~v_2_mantissa_mul;

    v_2_mantissa_mac = v_2_mantissa_add + v_2_mantissa_mul
                     + {163'h0, v_2_sign_add} + {163'h0, v_2_sign_mul};

    v_2_sign_mac = v_2_mantissa_mac[163];
    v_2_zero     = ~|v_2_mantissa_mac;

    if (v_2_zero) begin
      v_2_sign_mac     = v_2_sign_add & v_2_sign_mul;  // exact zero sign rule
    end else if (v_2_sign_mac) begin
      v_2_mantissa_mac = -v_2_mantissa_mac;            // make positive for normalization
    end

    v_2_diff = v_2_sign_add ^ v_2_sign_mul;

    // IEEE-754 exponent biases
    v_2_bias = 11'd1023;              // double
    if (v_2_fmt == 2'b01) v_2_bias = 11'd127; // single

    // Normalize left via external LZC
    lzc_i_a          = {v_2_mantissa_mac[162:0], {93{1'b1}}};
    v_2_counter_mac  = ~lzc_o_c;
    v_2_mantissa_mac = v_2_mantissa_mac << v_2_counter_mac;

    // Unbiased exponent after normalization shift and bias removal
    v_2_sign_rnd     = v_2_sign_mac;
    v_2_exponent_rnd = v_2_exponent_mac - {3'b000, v_2_bias} - {6'b000000, v_2_counter_mac};

    // Subnormal handling (right shift mantissa, clamp exponent=0)
    v_2_counter_sub = 14'd0;
    if ($signed(v_2_exponent_rnd) <= 0) begin
      v_2_counter_sub = 14'd63;
      if ($signed(v_2_exponent_rnd) > -63) v_2_counter_sub = 14'h1 - v_2_exponent_rnd;
      v_2_exponent_rnd = 14'd0;
    end
    v_2_mantissa_mac = v_2_mantissa_mac >> v_2_counter_sub[5:0];

    // Extract mantissa and GRS by format
    v_2_mantissa_rnd = {30'h0, v_2_mantissa_mac[162:139]};
    v_2_grs          = {v_2_mantissa_mac[138:137], |v_2_mantissa_mac[136:0]};
    if (v_2_fmt == 2'b01) begin
      v_2_mantissa_rnd = {1'h0, v_2_mantissa_mac[162:110]};
      v_2_grs          = {v_2_mantissa_mac[109:108], |v_2_mantissa_mac[107:0]};
    end

    if (clear == 1'b1) v_2_ready = 1'b0;

    // Drive next-state for r_2
    rin_2_sign_rnd     = v_2_sign_rnd;
    rin_2_exponent_rnd = v_2_exponent_rnd;
    rin_2_mantissa_rnd = v_2_mantissa_rnd;
    rin_2_fmt          = v_2_fmt;
    rin_2_rm           = v_2_rm;
    rin_2_grs          = v_2_grs;
    rin_2_snan         = v_2_snan;
    rin_2_qnan         = v_2_qnan;
    rin_2_dbz          = v_2_dbz;
    rin_2_infs         = v_2_infs;
    rin_2_diff         = v_2_diff;
    rin_2_zero         = v_2_zero;
    rin_2_ready        = v_2_ready;
  end

  // ===========================================================================
  // Output wiring (forward r_2 fields)
  // ===========================================================================
  always @* begin
    fp_fma_o_fp_rnd_sig   = r_2_sign_rnd;
    fp_fma_o_fp_rnd_expo  = r_2_exponent_rnd;
    fp_fma_o_fp_rnd_mant  = r_2_mantissa_rnd;
    fp_fma_o_fp_rnd_rema  = 2'b00;
    fp_fma_o_fp_rnd_fmt   = r_2_fmt;
    fp_fma_o_fp_rnd_rm    = r_2_rm;
    fp_fma_o_fp_rnd_grs   = r_2_grs;
    fp_fma_o_fp_rnd_snan  = r_2_snan;
    fp_fma_o_fp_rnd_qnan  = r_2_qnan;
    fp_fma_o_fp_rnd_dbz   = r_2_dbz;
    fp_fma_o_fp_rnd_infs  = r_2_infs;
    fp_fma_o_fp_rnd_zero  = r_2_zero;
    fp_fma_o_fp_rnd_diff  = r_2_diff;
    fp_fma_o_ready        = r_2_ready;
  end

  // ===========================================================================
  // Sequential (reset/init and pipeline latching)
  // ===========================================================================
  always @(posedge clock) begin
    if (reset == 1'b0) begin
      // r_1 reset
      r_1_fmt <= 2'b00; r_1_rm <= 3'b000;
      r_1_snan <= 1'b0; r_1_qnan <= 1'b0; r_1_dbz <= 1'b0; r_1_infs <= 1'b0; r_1_zero <= 1'b0;
      r_1_sign_mul <= 1'b0; r_1_sign_add <= 1'b0; r_1_exponent_neg <= 1'b0; r_1_ready <= 1'b0;
      r_1_exponent_mul <= 14'd0; r_1_exponent_add <= 14'd0;
      r_1_mantissa_mul <= 164'd0; r_1_mantissa_add <= 164'd0;
      r_1_op_fmadd <= 1'b0; r_1_op_fmsub <= 1'b0; r_1_op_fnmadd <= 1'b0; r_1_op_fnmsub <= 1'b0; r_1_op_fadd <= 1'b0; r_1_op_fsub <= 1'b0; r_1_op_fmul <= 1'b0;

      // r_2 reset
      r_2_sign_rnd <= 1'b0;
      r_2_exponent_rnd <= 14'd0;
      r_2_mantissa_rnd <= 54'd0;
      r_2_fmt <= 2'b00; r_2_rm <= 3'b000; r_2_grs <= 3'b000;
      r_2_snan <= 1'b0; r_2_qnan <= 1'b0; r_2_dbz <= 1'b0; r_2_infs <= 1'b0; r_2_zero <= 1'b0; r_2_diff <= 1'b0; r_2_ready <= 1'b0;

    end else begin
      // r_1 update
      r_1_fmt <= rin_1_fmt;  r_1_rm <= rin_1_rm;
      r_1_snan <= rin_1_snan; r_1_qnan <= rin_1_qnan; r_1_dbz <= rin_1_dbz; r_1_infs <= rin_1_infs; r_1_zero <= rin_1_zero;
      r_1_sign_mul <= rin_1_sign_mul; r_1_sign_add <= rin_1_sign_add; r_1_exponent_neg <= rin_1_exponent_neg; r_1_ready <= rin_1_ready;
      r_1_exponent_mul <= rin_1_exponent_mul; r_1_exponent_add <= rin_1_exponent_add;
      r_1_mantissa_mul <= rin_1_mantissa_mul; r_1_mantissa_add <= rin_1_mantissa_add;
      r_1_op_fmadd <= rin_1_op_fmadd; r_1_op_fmsub <= rin_1_op_fmsub; r_1_op_fnmadd <= rin_1_op_fnmadd; r_1_op_fnmsub <= rin_1_op_fnmsub;
      r_1_op_fadd <= rin_1_op_fadd; r_1_op_fsub <= rin_1_op_fsub; r_1_op_fmul <= rin_1_op_fmul;

      // r_2 update
      r_2_sign_rnd <= rin_2_sign_rnd;
      r_2_exponent_rnd <= rin_2_exponent_rnd;
      r_2_mantissa_rnd <= rin_2_mantissa_rnd;
      r_2_fmt <= rin_2_fmt;  r_2_rm <= rin_2_rm;  r_2_grs <= rin_2_grs;
      r_2_snan <= rin_2_snan; r_2_qnan <= rin_2_qnan; r_2_dbz <= rin_2_dbz; r_2_infs <= rin_2_infs; r_2_zero <= rin_2_zero; r_2_diff <= rin_2_diff; r_2_ready <= rin_2_ready;
    end
  end

endmodule
