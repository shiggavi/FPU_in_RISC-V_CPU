`timescale 1ns/1ps

module fp_cvt #(
    parameter RISCV = 0
) (
    input [64:0] fp_cvt_f2f_i_data,
    input [1:0] fp_cvt_f2f_i_fmt,
    input [2:0] fp_cvt_f2f_i_rm,
    input [9:0] fp_cvt_f2f_i_classification,
    output reg fp_cvt_f2f_o_fp_rnd_sig,
    output reg [13:0] fp_cvt_f2f_o_fp_rnd_expo,
    output reg [53:0] fp_cvt_f2f_o_fp_rnd_mant,
    output reg [1:0] fp_cvt_f2f_o_fp_rnd_rema,
    output reg [1:0] fp_cvt_f2f_o_fp_rnd_fmt,
    output reg [2:0] fp_cvt_f2f_o_fp_rnd_rm,
    output reg [2:0] fp_cvt_f2f_o_fp_rnd_grs,
    output reg fp_cvt_f2f_o_fp_rnd_snan,
    output reg fp_cvt_f2f_o_fp_rnd_qnan,
    output reg fp_cvt_f2f_o_fp_rnd_dbz,
    output reg fp_cvt_f2f_o_fp_rnd_infs,
    output reg fp_cvt_f2f_o_fp_rnd_zero,
    output reg fp_cvt_f2f_o_fp_rnd_diff,
    input [64:0] fp_cvt_f2i_i_data,
    input fp_cvt_f2i_i_op_fmadd,
    input fp_cvt_f2i_i_op_fmsub,
    input fp_cvt_f2i_i_op_fnmadd,
    input fp_cvt_f2i_i_op_fnmsub,
    input fp_cvt_f2i_i_op_fadd,
    input fp_cvt_f2i_i_op_fsub,
    input fp_cvt_f2i_i_op_fmul,
    input fp_cvt_f2i_i_op_fdiv,
    input fp_cvt_f2i_i_op_fsqrt,
    input fp_cvt_f2i_i_op_fsgnj,
    input fp_cvt_f2i_i_op_fcmp,
    input fp_cvt_f2i_i_op_fmax,
    input fp_cvt_f2i_i_op_fclass,
    input fp_cvt_f2i_i_op_fmv_i2f,
    input fp_cvt_f2i_i_op_fmv_f2i,
    input fp_cvt_f2i_i_op_fcvt_f2f,
    input fp_cvt_f2i_i_op_fcvt_i2f,
    input fp_cvt_f2i_i_op_fcvt_f2i,
    input [1:0] fp_cvt_f2i_i_op_fcvt_op,
    input [2:0] fp_cvt_f2i_i_rm,
    input [9:0] fp_cvt_f2i_i_classification,
    output reg [63:0] fp_cvt_f2i_o_result,
    output reg [4:0] fp_cvt_f2i_o_flags,
    input [63:0] fp_cvt_i2f_i_data,
    input fp_cvt_i2f_i_op_fmadd,
    input fp_cvt_i2f_i_op_fmsub,
    input fp_cvt_i2f_i_op_fnmadd,
    input fp_cvt_i2f_i_op_fnmsub,
    input fp_cvt_i2f_i_op_fadd,
    input fp_cvt_i2f_i_op_fsub,
    input fp_cvt_i2f_i_op_fmul,
    input fp_cvt_i2f_i_op_fdiv,
    input fp_cvt_i2f_i_op_fsqrt,
    input fp_cvt_i2f_i_op_fsgnj,
    input fp_cvt_i2f_i_op_fcmp,
    input fp_cvt_i2f_i_op_fmax,
    input fp_cvt_i2f_i_op_fclass,
    input fp_cvt_i2f_i_op_fmv_i2f,
    input fp_cvt_i2f_i_op_fmv_f2i,
    input fp_cvt_i2f_i_op_fcvt_f2f,
    input fp_cvt_i2f_i_op_fcvt_i2f,
    input fp_cvt_i2f_i_op_fcvt_f2i,
    input [1:0] fp_cvt_i2f_i_op_fcvt_op,
    input [1:0] fp_cvt_i2f_i_fmt,
    input [2:0] fp_cvt_i2f_i_rm,
    output reg fp_cvt_i2f_o_fp_rnd_sig,
    output reg [13:0] fp_cvt_i2f_o_fp_rnd_expo,
    output reg [53:0] fp_cvt_i2f_o_fp_rnd_mant,
    output reg [1:0] fp_cvt_i2f_o_fp_rnd_rema,
    output reg [1:0] fp_cvt_i2f_o_fp_rnd_fmt,
    output reg [2:0] fp_cvt_i2f_o_fp_rnd_rm,
    output reg [2:0] fp_cvt_i2f_o_fp_rnd_grs,
    output reg fp_cvt_i2f_o_fp_rnd_snan,
    output reg fp_cvt_i2f_o_fp_rnd_qnan,
    output reg fp_cvt_i2f_o_fp_rnd_dbz,
    output reg fp_cvt_i2f_o_fp_rnd_infs,
    output reg fp_cvt_i2f_o_fp_rnd_zero,
    output reg fp_cvt_i2f_o_fp_rnd_diff,
    input [5:0] lzc_o_c,
    input lzc_o_v,
    output reg [63:0] lzc_i_a
);
  // Internal registers for fp_cvt_f2f
  reg [64:0] v_f2f_data;
  reg [1:0] v_f2f_fmt;
  reg [2:0] v_f2f_rm;
  reg [9:0] v_f2f_classification;
  reg v_f2f_snan;
  reg v_f2f_qnan;
  reg v_f2f_dbz;
  reg v_f2f_infs;
  reg v_f2f_zero;
  reg [11:0] v_f2f_exponent_cvt;
  reg [79:0] v_f2f_mantissa_cvt;
  reg [10:0] v_f2f_exponent_bias;
  reg v_f2f_sign_rnd;
  reg [13:0] v_f2f_exponent_rnd;
  reg [13:0] v_f2f_counter_cvt;
  reg [53:0] v_f2f_mantissa_rnd;
  reg [2:0] v_f2f_grs;

  // Internal registers for fp_cvt_f2i
  reg [64:0] v_f2i_data;
  reg [1:0] v_f2i_op;
  reg [2:0] v_f2i_rm;
  reg [9:0] v_f2i_classification;
  reg [63:0] v_f2i_result;
  reg [4:0] v_f2i_flags;
  reg v_f2i_snan;
  reg v_f2i_qnan;
  reg v_f2i_infs;
  reg v_f2i_zero;
  reg v_f2i_sign_cvt;
  reg [12:0] v_f2i_exponent_cvt;
  reg [119:0] v_f2i_mantissa_cvt;
  reg [7:0] v_f2i_exponent_bias;
  reg [64:0] v_f2i_mantissa_uint;
  reg [2:0] v_f2i_grs;
  reg v_f2i_odd;
  reg v_f2i_rnded;
  reg v_f2i_oor;
  reg v_f2i_or_1;
  reg v_f2i_or_2;
  reg v_f2i_or_3;
  reg v_f2i_or_4;
  reg v_f2i_or_5;
  reg v_f2i_oor_64u;
  reg v_f2i_oor_64s;
  reg v_f2i_oor_32u;
  reg v_f2i_oor_32s;

  // Internal registers for fp_cvt_i2f
  reg [63:0] v_i2f_data;
  reg [1:0] v_i2f_op;
  reg [1:0] v_i2f_fmt;
  reg [2:0] v_i2f_rm;
  reg v_i2f_snan;
  reg v_i2f_qnan;
  reg v_i2f_dbz;
  reg v_i2f_infs;
  reg v_i2f_zero;
  reg [9:0] v_i2f_exponent_bias;
  reg v_i2f_sign_uint;
  reg [5:0] v_i2f_exponent_uint;
  reg [63:0] v_i2f_mantissa_uint;
  reg [5:0] v_i2f_counter_uint;
  reg v_i2f_sign_rnd;
  reg [13:0] v_i2f_exponent_rnd;
  reg [53:0] v_i2f_mantissa_rnd;
  reg [2:0] v_i2f_grs;

  always @(*) begin
    // Floating-point to Floating-point (f2f) conversion
    v_f2f_data = fp_cvt_f2f_i_data;
    v_f2f_fmt  = fp_cvt_f2f_i_fmt;
    v_f2f_rm   = fp_cvt_f2f_i_rm;
    v_f2f_classification = fp_cvt_f2f_i_classification;

    // Decode classification flags
    v_f2f_snan = v_f2f_classification[8];
    v_f2f_qnan = v_f2f_classification[9];
    v_f2f_dbz  = 1'b0;
    v_f2f_infs = v_f2f_classification[0] | v_f2f_classification[7];
    v_f2f_zero = v_f2f_classification[3] | v_f2f_classification[4];

    // Extract exponent and construct extended mantissa
    v_f2f_exponent_cvt = v_f2f_data[63:52];
    v_f2f_mantissa_cvt = {2'b01, v_f2f_data[51:0], 26'h0};

    // Set exponent bias based on target format (0: single, 1: double)
    v_f2f_exponent_bias = 11'd1920;
    if (v_f2f_fmt == 1) begin
      v_f2f_exponent_bias = 11'd1024;
    end

    // Extract sign and compute initial exponent difference
    v_f2f_sign_rnd = v_f2f_data[64];
    v_f2f_exponent_rnd = {2'b00, v_f2f_exponent_cvt} - {3'b000, v_f2f_exponent_bias};

    // If exponent is non-positive, normalize mantissa by shifting
    v_f2f_counter_cvt = 14'd0;
    if ($signed(v_f2f_exponent_rnd) <= 0) begin
      v_f2f_counter_cvt = 14'd63;
      if ($signed(v_f2f_exponent_rnd) > -14'sd63) begin
        v_f2f_counter_cvt = 14'h1 - v_f2f_exponent_rnd;
      end
      v_f2f_exponent_rnd = 14'd0;
    end
    v_f2f_mantissa_cvt = v_f2f_mantissa_cvt >> v_f2f_counter_cvt[5:0];

    // Round mantissa and gather GRS (Guard, Round, Sticky) bits
    v_f2f_mantissa_rnd = {29'h0, v_f2f_mantissa_cvt[79:55]};
    v_f2f_grs = {v_f2f_mantissa_cvt[54:53], |v_f2f_mantissa_cvt[52:0]};
    if (v_f2f_fmt == 1) begin
      v_f2f_mantissa_rnd = v_f2f_mantissa_cvt[79:26];
      v_f2f_grs = {v_f2f_mantissa_cvt[25:24], |v_f2f_mantissa_cvt[23:0]};
    end

    // Pack the outputs for f2f conversion
    fp_cvt_f2f_o_fp_rnd_sig  = v_f2f_sign_rnd;
    fp_cvt_f2f_o_fp_rnd_expo = v_f2f_exponent_rnd;
    fp_cvt_f2f_o_fp_rnd_mant = v_f2f_mantissa_rnd;
    fp_cvt_f2f_o_fp_rnd_rema = 2'b00;
    fp_cvt_f2f_o_fp_rnd_fmt  = v_f2f_fmt;
    fp_cvt_f2f_o_fp_rnd_rm   = v_f2f_rm;
    fp_cvt_f2f_o_fp_rnd_grs  = v_f2f_grs;
    fp_cvt_f2f_o_fp_rnd_snan = v_f2f_snan;
    fp_cvt_f2f_o_fp_rnd_qnan = v_f2f_qnan;
    fp_cvt_f2f_o_fp_rnd_dbz  = v_f2f_dbz;
    fp_cvt_f2f_o_fp_rnd_infs = v_f2f_infs;
    fp_cvt_f2f_o_fp_rnd_zero = v_f2f_zero;
    fp_cvt_f2f_o_fp_rnd_diff = 1'b0;
  end

  generate
    if (RISCV == 0) begin
      // Floating-point to Integer conversion (RISCV=0 behavior)
      always @(*) begin
        v_f2i_data = fp_cvt_f2i_i_data;
        v_f2i_op   = fp_cvt_f2i_i_op_fcvt_op;
        v_f2i_rm   = fp_cvt_f2i_i_rm;
        v_f2i_classification = fp_cvt_f2i_i_classification;

        // Default outputs and flags
        v_f2i_flags = 5'b00000;
        v_f2i_result = 64'd0;

        // Decode classification flags
        v_f2i_snan = v_f2i_classification[8];
        v_f2i_qnan = v_f2i_classification[9];
        v_f2i_infs = v_f2i_classification[0] | v_f2i_classification[7];
        v_f2i_zero = 1'b0;

        // Set exponent bias based on conversion operation (fcvt_op)
        if (v_f2i_op == 2'b00) begin
          v_f2i_exponent_bias = 8'd34;    // 32-bit signed
        end else if (v_f2i_op == 2'b01) begin
          v_f2i_exponent_bias = 8'd35;    // 32-bit unsigned
        end else if (v_f2i_op == 2'b10) begin
          v_f2i_exponent_bias = 8'd66;    // 64-bit signed
        end else begin
          v_f2i_exponent_bias = 8'd67;    // 64-bit unsigned
        end

        // Extract sign and biased exponent, construct mantissa with implicit 1
        v_f2i_sign_cvt = v_f2i_data[64];
        v_f2i_exponent_cvt = v_f2i_data[63:52] - 13'd2044;
        v_f2i_mantissa_cvt = {68'h1, v_f2i_data[51:0]};

        // If input is zero or subnormal, clear the implicit 1 (mantissa bit 52)
        if ((v_f2i_classification[3] | v_f2i_classification[4]) == 1'b1) begin
          v_f2i_mantissa_cvt[52] = 1'b0;
        end

        // Determine if result is out of range (oor)
        v_f2i_oor = 1'b0;
        if ($signed(v_f2i_exponent_cvt) > $signed({5'b0, v_f2i_exponent_bias})) begin
          v_f2i_oor = 1'b1;
        end else if ($signed(v_f2i_exponent_cvt) > 0) begin
          v_f2i_mantissa_cvt = v_f2i_mantissa_cvt << v_f2i_exponent_cvt;
        end

        // Align mantissa to integer (take top 65 bits after shifting)
        v_f2i_mantissa_uint = v_f2i_mantissa_cvt[119:55];

        // Gather GRS bits for rounding
        v_f2i_grs = {v_f2i_mantissa_cvt[54:53], |v_f2i_mantissa_cvt[52:0]};
        v_f2i_odd = v_f2i_mantissa_uint[0] | (|v_f2i_grs[1:0]);

        // Inexact flag (LSB of flags vector) is set if any GRS bit is 1
        v_f2i_flags[0] = |v_f2i_grs;

        // Determine rounding increment (v_f2i_rnded)
        v_f2i_rnded = 1'b0;
        case (v_f2i_rm)
          3'b000: begin // RNE (Round to Nearest, ties to Even)
            if (v_f2i_grs[2] & v_f2i_odd) v_f2i_rnded = 1'b1;
          end
          3'b010: begin // RDN (Round toward -∞)
            if (v_f2i_sign_cvt & v_f2i_flags[0]) v_f2i_rnded = 1'b1;
          end
          3'b011: begin // RUP (Round toward +∞)
            if (~v_f2i_sign_cvt & v_f2i_flags[0]) v_f2i_rnded = 1'b1;
          end
          3'b100: begin // RMM (Round to Nearest, ties to Max Magnitude)
            if (v_f2i_grs[2] & v_f2i_flags[0]) v_f2i_rnded = 1'b1;
          end
          default: ; // Other rounding modes (if any) not used here
        endcase

        // Add rounding increment to mantissa_uint (65-bit addition)
        v_f2i_mantissa_uint = v_f2i_mantissa_uint + {64'b0, v_f2i_rnded};

        // Check bits of mantissa_uint to determine overflow/out-of-range conditions
        v_f2i_or_1 = v_f2i_mantissa_uint[64];
        v_f2i_or_2 = v_f2i_mantissa_uint[63];
        v_f2i_or_3 = |v_f2i_mantissa_uint[62:32];
        v_f2i_or_4 = v_f2i_mantissa_uint[31];
        v_f2i_or_5 = |v_f2i_mantissa_uint[30:0];

        // Determine if result is zero after rounding (all bits of mantissa_uint)
        v_f2i_zero = v_f2i_or_1 | v_f2i_or_2 | v_f2i_or_3 | v_f2i_or_4 | v_f2i_or_5;

        // Initial out-of-range signals for each target type
        v_f2i_oor_64u = v_f2i_or_1;
        v_f2i_oor_64s = v_f2i_or_1;
        v_f2i_oor_32u = v_f2i_or_1 | v_f2i_or_2 | v_f2i_or_3;
        v_f2i_oor_32s = v_f2i_or_1 | v_f2i_or_2 | v_f2i_or_3;

        // Adjust out-of-range signals based on sign of original value
        if (v_f2i_sign_cvt) begin
          if (v_f2i_op == 2'b00) begin  // 32-bit signed
            v_f2i_oor_32s = v_f2i_oor_32s | (v_f2i_or_4 & v_f2i_or_5);
          end else if (v_f2i_op == 2'b01) begin  // 32-bit unsigned
            v_f2i_oor = v_f2i_oor | v_f2i_zero;
          end else if (v_f2i_op == 2'b10) begin  // 64-bit signed
            v_f2i_oor_64s = v_f2i_oor_64s | (v_f2i_or_2 & (v_f2i_or_3 | v_f2i_or_4 | v_f2i_or_5));
          end else if (v_f2i_op == 2'b11) begin  // 64-bit unsigned
            v_f2i_oor = v_f2i_oor | v_f2i_zero;
          end
        end else begin
          v_f2i_oor_64s = v_f2i_oor_64s | v_f2i_or_2;
          v_f2i_oor_32s = v_f2i_oor_32s | v_f2i_or_4;
        end

        // Final out-of-range conditions combined with special cases (Inf/NaN)
        v_f2i_oor_64u = (v_f2i_op == 2'b11) & (v_f2i_oor_64u | v_f2i_oor | v_f2i_infs | v_f2i_snan | v_f2i_qnan);
        v_f2i_oor_64s = (v_f2i_op == 2'b10) & (v_f2i_oor_64s | v_f2i_oor | v_f2i_infs | v_f2i_snan | v_f2i_qnan);
        v_f2i_oor_32u = (v_f2i_op == 2'b01) & (v_f2i_oor_32u | v_f2i_oor | v_f2i_infs | v_f2i_snan | v_f2i_qnan);
        v_f2i_oor_32s = (v_f2i_op == 2'b00) & (v_f2i_oor_32s | v_f2i_oor | v_f2i_infs | v_f2i_snan | v_f2i_qnan);

        // Apply sign: if original was negative, take two's complement of mantissa_uint
        if (v_f2i_sign_cvt) begin
          v_f2i_mantissa_uint = -v_f2i_mantissa_uint;
        end

        // Construct final result based on conversion type and handle saturation/overflow
        if (v_f2i_op == 2'b00) begin
          // 32-bit signed integer result
          v_f2i_result = {32'h0, v_f2i_mantissa_uint[31:0]};
          if (v_f2i_oor_32s) begin  // overflow or out-of-range for 32-bit signed
            v_f2i_result = 64'h0000000080000000;  // INT32_MIN (0x80000000) in 64 bits
            v_f2i_flags  = 5'b10000;             // set invalid flag
          end
        end else if (v_f2i_op == 2'b01) begin
          // 32-bit unsigned integer result
          v_f2i_result = {32'h0, v_f2i_mantissa_uint[31:0]};
          if (v_f2i_oor_32u) begin  // overflow for 32-bit unsigned
            v_f2i_result = 64'h00000000FFFFFFFF; // UINT32_MAX
            v_f2i_flags  = 5'b10000;
          end
        end else if (v_f2i_op == 2'b10) begin
          // 64-bit signed integer result
          v_f2i_result = v_f2i_mantissa_uint[63:0];
          if (v_f2i_oor_64s) begin  // overflow for 64-bit signed
            v_f2i_result = 64'h8000000000000000; // INT64_MIN
            v_f2i_flags  = 5'b10000;
          end
        end else if (v_f2i_op == 2'b11) begin
          // 64-bit unsigned integer result
          v_f2i_result = v_f2i_mantissa_uint[63:0];
          if (v_f2i_oor_64u) begin  // overflow for 64-bit unsigned
            v_f2i_result = 64'hFFFFFFFFFFFFFFFF; // UINT64_MAX
            v_f2i_flags  = 5'b10000;
          end
        end

        // Drive outputs for f2i conversion
        fp_cvt_f2i_o_result = v_f2i_result;
        fp_cvt_f2i_o_flags  = v_f2i_flags;
      end
    end

    if (RISCV == 1) begin
      // Floating-point to Integer conversion (RISCV=1 behavior)
      always @(*) begin
        v_f2i_data = fp_cvt_f2i_i_data;
        v_f2i_op   = fp_cvt_f2i_i_op_fcvt_op;
        v_f2i_rm   = fp_cvt_f2i_i_rm;
        v_f2i_classification = fp_cvt_f2i_i_classification;

        v_f2i_flags = 5'b00000;
        v_f2i_result = 64'd0;

        v_f2i_snan = v_f2i_classification[8];
        v_f2i_qnan = v_f2i_classification[9];
        v_f2i_infs = v_f2i_classification[0] | v_f2i_classification[7];
        v_f2i_zero = 1'b0;

        if (v_f2i_op == 2'b00) begin
          v_f2i_exponent_bias = 8'd34;
        end else if (v_f2i_op == 2'b01) begin
          v_f2i_exponent_bias = 8'd35;
        end else if (v_f2i_op == 2'b10) begin
          v_f2i_exponent_bias = 8'd66;
        end else begin
          v_f2i_exponent_bias = 8'd67;
        end

        v_f2i_sign_cvt = v_f2i_data[64];
        v_f2i_exponent_cvt = v_f2i_data[63:52] - 13'd2044;
        v_f2i_mantissa_cvt = {68'h1, v_f2i_data[51:0]};

        if ((v_f2i_classification[3] | v_f2i_classification[4]) == 1'b1) begin
          v_f2i_mantissa_cvt[52] = 1'b0;
        end

        v_f2i_oor = 1'b0;
        if ($signed(v_f2i_exponent_cvt) > $signed({5'b0, v_f2i_exponent_bias})) begin
          v_f2i_oor = 1'b1;
        end else if ($signed(v_f2i_exponent_cvt) > 0) begin
          v_f2i_mantissa_cvt = v_f2i_mantissa_cvt << v_f2i_exponent_cvt;
        end

        v_f2i_mantissa_uint = v_f2i_mantissa_cvt[119:55];

        v_f2i_grs = {v_f2i_mantissa_cvt[54:53], |v_f2i_mantissa_cvt[52:0]};
        v_f2i_odd = v_f2i_mantissa_uint[0] | (|v_f2i_grs[1:0]);

        v_f2i_flags[0] = |v_f2i_grs;

        v_f2i_rnded = 1'b0;
        case (v_f2i_rm)
          3'b000: if (v_f2i_grs[2] & v_f2i_odd) v_f2i_rnded = 1'b1;       // RNE
          3'b010: if (v_f2i_sign_cvt & v_f2i_flags[0]) v_f2i_rnded = 1'b1; // RDN
          3'b011: if (~v_f2i_sign_cvt & v_f2i_flags[0]) v_f2i_rnded = 1'b1; // RUP
          3'b100: if (v_f2i_grs[2] & v_f2i_flags[0]) v_f2i_rnded = 1'b1;   // RMM
          default: ;
        endcase

        v_f2i_mantissa_uint = v_f2i_mantissa_uint + {64'b0, v_f2i_rnded};

        v_f2i_or_1 = v_f2i_mantissa_uint[64];
        v_f2i_or_2 = v_f2i_mantissa_uint[63];
        v_f2i_or_3 = |v_f2i_mantissa_uint[62:32];
        v_f2i_or_4 = v_f2i_mantissa_uint[31];
        v_f2i_or_5 = |v_f2i_mantissa_uint[30:0];

        v_f2i_zero = v_f2i_or_1 | v_f2i_or_2 | v_f2i_or_3 | v_f2i_or_4 | v_f2i_or_5;

        v_f2i_oor_64u = v_f2i_or_1;
        v_f2i_oor_64s = v_f2i_or_1;
        v_f2i_oor_32u = v_f2i_or_1 | v_f2i_or_2 | v_f2i_or_3;
        v_f2i_oor_32s = v_f2i_or_1 | v_f2i_or_2 | v_f2i_or_3;

        if (v_f2i_sign_cvt) begin
          if (v_f2i_op == 2'b00) begin
            v_f2i_oor_32s = v_f2i_oor_32s | (v_f2i_or_4 & v_f2i_or_5);
          end else if (v_f2i_op == 2'b01) begin
            v_f2i_oor = v_f2i_oor | v_f2i_zero;
          end else if (v_f2i_op == 2'b10) begin
            v_f2i_oor_64s = v_f2i_oor_64s | (v_f2i_or_2 & (v_f2i_or_3 | v_f2i_or_4 | v_f2i_or_5));
          end else if (v_f2i_op == 2'b11) begin
            v_f2i_oor = v_f2i_oor | v_f2i_zero;
          end
        end else begin
          v_f2i_oor_64s = v_f2i_oor_64s | v_f2i_or_2;
          v_f2i_oor_32s = v_f2i_oor_32s | v_f2i_or_4;
        end

        v_f2i_oor_64u = (v_f2i_op == 2'b11) & (v_f2i_oor_64u | v_f2i_oor | v_f2i_infs | v_f2i_snan | v_f2i_qnan);
        v_f2i_oor_64s = (v_f2i_op == 2'b10) & (v_f2i_oor_64s | v_f2i_oor | v_f2i_infs | v_f2i_snan | v_f2i_qnan);
        v_f2i_oor_32u = (v_f2i_op == 2'b01) & (v_f2i_oor_32u | v_f2i_oor | v_f2i_infs | v_f2i_snan | v_f2i_qnan);
        v_f2i_oor_32s = (v_f2i_op == 2'b00) & (v_f2i_oor_32s | v_f2i_oor | v_f2i_infs | v_f2i_snan | v_f2i_qnan);

        if (v_f2i_sign_cvt) begin
          v_f2i_mantissa_uint = -v_f2i_mantissa_uint;
        end

        if (v_f2i_op == 2'b00) begin
          v_f2i_result = {32'h0, v_f2i_mantissa_uint[31:0]};
          if (v_f2i_oor_32s) begin
            // Overflow for 32-bit signed: saturate to max or min
            v_f2i_result = 64'h000000007FFFFFFF; // INT32_MAX
            v_f2i_flags  = 5'b10000;
            if (v_f2i_sign_cvt && ~(v_f2i_snan | v_f2i_qnan)) begin
              v_f2i_result = 64'h0000000080000000; // INT32_MIN if negative input
            end
          end
        end else if (v_f2i_op == 2'b01) begin
          v_f2i_result = {32'h0, v_f2i_mantissa_uint[31:0]};
          if (v_f2i_oor_32u) begin
            // Overflow for 32-bit unsigned: saturate to max or 0
            v_f2i_result = 64'h00000000FFFFFFFF; // UINT32_MAX
            v_f2i_flags  = 5'b10000;
            if (v_f2i_sign_cvt && ~(v_f2i_snan | v_f2i_qnan)) begin
              v_f2i_result = 64'h0000000000000000; // 0 if negative input (treated as invalid)
            end
          end
        end else if (v_f2i_op == 2'b10) begin
          v_f2i_result = v_f2i_mantissa_uint[63:0];
          if (v_f2i_oor_64s) begin
            // Overflow for 64-bit signed: saturate to max or min
            v_f2i_result = 64'h7FFFFFFFFFFFFFFF; // INT64_MAX
            v_f2i_flags  = 5'b10000;
            if (v_f2i_sign_cvt && ~(v_f2i_snan | v_f2i_qnan)) begin
              v_f2i_result = 64'h8000000000000000; // INT64_MIN if negative input
            end
          end
        end else if (v_f2i_op == 2'b11) begin
          v_f2i_result = v_f2i_mantissa_uint[63:0];
          if (v_f2i_oor_64u) begin
            // Overflow for 64-bit unsigned: saturate to max or 0
            v_f2i_result = 64'hFFFFFFFFFFFFFFFF; // UINT64_MAX
            v_f2i_flags  = 5'b10000;
            if (v_f2i_sign_cvt && ~(v_f2i_snan | v_f2i_qnan)) begin
              v_f2i_result = 64'h0000000000000000; // 0 if negative input (invalid case)
            end
          end
        end

        fp_cvt_f2i_o_result = v_f2i_result;
        fp_cvt_f2i_o_flags  = v_f2i_flags;
      end
    end
  endgenerate

  always @(*) begin
    // Integer to Floating-point (i2f) conversion
    v_i2f_data = fp_cvt_i2f_i_data;
    v_i2f_op   = fp_cvt_i2f_i_op_fcvt_op;
    v_i2f_fmt  = fp_cvt_i2f_i_fmt;
    v_i2f_rm   = fp_cvt_i2f_i_rm;

    // No NaNs or infs can originate directly from integer inputs
    v_i2f_snan = 1'b0;
    v_i2f_qnan = 1'b0;
    v_i2f_dbz  = 1'b0;
    v_i2f_infs = 1'b0;
    v_i2f_zero = 1'b0;

    // Set exponent bias for target format (0: single-> bias 127, 1: double-> bias 1023)
    v_i2f_exponent_bias = 10'd127;
    if (v_i2f_fmt == 1) begin
      v_i2f_exponent_bias = 10'd1023;
    end

    // Determine sign of input integer (for signed conversions)
    v_i2f_sign_uint = 1'b0;
    if (v_i2f_op == 2'b00) begin  // 32-bit signed
      v_i2f_sign_uint = v_i2f_data[31];
    end else if (v_i2f_op == 2'b10) begin  // 64-bit signed
      v_i2f_sign_uint = v_i2f_data[63];
    end

    // If negative, take two's complement to get magnitude
    if (v_i2f_sign_uint) begin
      v_i2f_data = -v_i2f_data;
    end

    // Initialize mantissa_uint and exponent_uint based on op (bit-width of input)
    v_i2f_mantissa_uint = 64'hFFFFFFFFFFFFFFFF;
    v_i2f_exponent_uint = 6'd0;
    if (!v_i2f_op[1]) begin  // If op[1] == 0 (32-bit int)
      v_i2f_mantissa_uint = {v_i2f_data[31:0], 32'h0};
      v_i2f_exponent_uint = 6'd31;
    end else if (v_i2f_op[1]) begin  // If op[1] == 1 (64-bit int)
      v_i2f_mantissa_uint = v_i2f_data[63:0];
      v_i2f_exponent_uint = 6'd63;
    end

    // Detect if input is zero
    v_i2f_zero = ~|v_i2f_mantissa_uint;

    // Connect mantissa to leading-zero-count (LZC) input and get count
    lzc_i_a = v_i2f_mantissa_uint;
    v_i2f_counter_uint = ~lzc_o_c;

    // Normalize mantissa by left-shifting according to leading zeros
    v_i2f_mantissa_uint = v_i2f_mantissa_uint << v_i2f_counter_uint;

    // Compute sign bit and adjusted exponent for the floating-point result
    v_i2f_sign_rnd = v_i2f_sign_uint;
    v_i2f_exponent_rnd = {8'b0, v_i2f_exponent_uint} + {4'b0, v_i2f_exponent_bias} - {8'b0, v_i2f_counter_uint};

    // Extract the top 54 bits of normalized mantissa and set GRS bits
    v_i2f_mantissa_rnd = {30'h0, v_i2f_mantissa_uint[63:40]};
    v_i2f_grs = {v_i2f_mantissa_uint[39:38], |v_i2f_mantissa_uint[37:0]};
    if (v_i2f_fmt == 1) begin
      v_i2f_mantissa_rnd = {1'b0, v_i2f_mantissa_uint[63:11]};
      v_i2f_grs = {v_i2f_mantissa_uint[10:9], |v_i2f_mantissa_uint[8:0]};
    end

    // Pack the outputs for i2f conversion
    fp_cvt_i2f_o_fp_rnd_sig  = v_i2f_sign_rnd;
    fp_cvt_i2f_o_fp_rnd_expo = v_i2f_exponent_rnd;
    fp_cvt_i2f_o_fp_rnd_mant = v_i2f_mantissa_rnd;
    fp_cvt_i2f_o_fp_rnd_rema = 2'b00;
    fp_cvt_i2f_o_fp_rnd_fmt  = v_i2f_fmt;
    fp_cvt_i2f_o_fp_rnd_rm   = v_i2f_rm;
    fp_cvt_i2f_o_fp_rnd_grs  = v_i2f_grs;
    fp_cvt_i2f_o_fp_rnd_snan = v_i2f_snan;
    fp_cvt_i2f_o_fp_rnd_qnan = v_i2f_qnan;
    fp_cvt_i2f_o_fp_rnd_dbz  = v_i2f_dbz;
    fp_cvt_i2f_o_fp_rnd_infs = v_i2f_infs;
    fp_cvt_i2f_o_fp_rnd_zero = v_i2f_zero;
    fp_cvt_i2f_o_fp_rnd_diff = 1'b0;
  end

endmodule
