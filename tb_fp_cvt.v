`timescale 1ns/1ps

module tb_fp_cvt;
  // -------------------------------
  // Common stimuli (driven to both DUTs)
  // -------------------------------
  // f2f
  reg  [64:0] fp_cvt_f2f_i_data;
  reg  [1:0]  fp_cvt_f2f_i_fmt;   // 0: single, 1: double (target)
  reg  [2:0]  fp_cvt_f2f_i_rm;    // RNE=000, RTZ=001, RDN=010, RUP=011, RMM=100
  reg  [9:0]  fp_cvt_f2f_i_classification;
  wire        f2f_o_sig_0, f2f_o_sig_1;
  wire [13:0] f2f_o_expo_0, f2f_o_expo_1;
  wire [53:0] f2f_o_mant_0, f2f_o_mant_1;
  wire [1:0]  f2f_o_rema_0, f2f_o_rema_1;
  wire [1:0]  f2f_o_fmt_0,  f2f_o_fmt_1;
  wire [2:0]  f2f_o_rm_0,   f2f_o_rm_1;
  wire [2:0]  f2f_o_grs_0,  f2f_o_grs_1;
  wire        f2f_o_snan_0, f2f_o_snan_1;
  wire        f2f_o_qnan_0, f2f_o_qnan_1;
  wire        f2f_o_dbz_0,  f2f_o_dbz_1;
  wire        f2f_o_infs_0, f2f_o_infs_1;
  wire        f2f_o_zero_0, f2f_o_zero_1;
  wire        f2f_o_diff_0, f2f_o_diff_1;

  // f2i
  reg  [64:0] fp_cvt_f2i_i_data;
  // Unused op flags in DUT; keep low
  reg         fp_cvt_f2i_i_op_fmadd;
  reg         fp_cvt_f2i_i_op_fmsub;
  reg         fp_cvt_f2i_i_op_fnmadd;
  reg         fp_cvt_f2i_i_op_fnmsub;
  reg         fp_cvt_f2i_i_op_fadd;
  reg         fp_cvt_f2i_i_op_fsub;
  reg         fp_cvt_f2i_i_op_fmul;
  reg         fp_cvt_f2i_i_op_fdiv;
  reg         fp_cvt_f2i_i_op_fsqrt;
  reg         fp_cvt_f2i_i_op_fsgnj;
  reg         fp_cvt_f2i_i_op_fcmp;
  reg         fp_cvt_f2i_i_op_fmax;
  reg         fp_cvt_f2i_i_op_fclass;
  reg         fp_cvt_f2i_i_op_fmv_i2f;
  reg         fp_cvt_f2i_i_op_fmv_f2i;
  reg         fp_cvt_f2i_i_op_fcvt_f2f;
  reg         fp_cvt_f2i_i_op_fcvt_i2f;
  reg         fp_cvt_f2i_i_op_fcvt_f2i;
  reg  [1:0]  fp_cvt_f2i_i_op_fcvt_op; // 00:32s, 01:32u, 10:64s, 11:64u
  reg  [2:0]  fp_cvt_f2i_i_rm;
  reg  [9:0]  fp_cvt_f2i_i_classification;
  wire [63:0] f2i_o_res_0, f2i_o_res_1;
  wire [4:0]  f2i_o_flg_0, f2i_o_flg_1;

  // i2f
  reg  [63:0] fp_cvt_i2f_i_data;
  // Unused op flags in DUT; keep low
  reg         fp_cvt_i2f_i_op_fmadd;
  reg         fp_cvt_i2f_i_op_fmsub;
  reg         fp_cvt_i2f_i_op_fnmadd;
  reg         fp_cvt_i2f_i_op_fnmsub;
  reg         fp_cvt_i2f_i_op_fadd;
  reg         fp_cvt_i2f_i_op_fsub;
  reg         fp_cvt_i2f_i_op_fmul;
  reg         fp_cvt_i2f_i_op_fdiv;
  reg         fp_cvt_i2f_i_op_fsqrt;
  reg         fp_cvt_i2f_i_op_fsgnj;
  reg         fp_cvt_i2f_i_op_fcmp;
  reg         fp_cvt_i2f_i_op_fmax;
  reg         fp_cvt_i2f_i_op_fclass;
  reg         fp_cvt_i2f_i_op_fmv_i2f;
  reg         fp_cvt_i2f_i_op_fmv_f2i;
  reg         fp_cvt_i2f_i_op_fcvt_f2f;
  reg         fp_cvt_i2f_i_op_fcvt_i2f;
  reg         fp_cvt_i2f_i_op_fcvt_f2i;
  reg  [1:0]  fp_cvt_i2f_i_op_fcvt_op; // 00:32s, 01:32u, 10:64s, 11:64u
  reg  [1:0]  fp_cvt_i2f_i_fmt;        // 0: single, 1: double (target)
  reg  [2:0]  fp_cvt_i2f_i_rm;
  wire        i2f_o_sig_0, i2f_o_sig_1;
  wire [13:0] i2f_o_expo_0, i2f_o_expo_1;
  wire [53:0] i2f_o_mant_0, i2f_o_mant_1;
  wire [1:0]  i2f_o_rema_0, i2f_o_rema_1;
  wire [1:0]  i2f_o_fmt_0,  i2f_o_fmt_1;
  wire [2:0]  i2f_o_rm_0,   i2f_o_rm_1;
  wire [2:0]  i2f_o_grs_0,  i2f_o_grs_1;
  wire        i2f_o_snan_0, i2f_o_snan_1;
  wire        i2f_o_qnan_0, i2f_o_qnan_1;
  wire        i2f_o_dbz_0,  i2f_o_dbz_1;
  wire        i2f_o_infs_0, i2f_o_infs_1;
  wire        i2f_o_zero_0, i2f_o_zero_1;
  wire        i2f_o_diff_0, i2f_o_diff_1;

  // LZC handshake wires for each instance
  reg  [5:0]  lzc_o_c_0, lzc_o_c_1;
  reg         lzc_o_v_0, lzc_o_v_1;
  wire [63:0] lzc_i_a_0, lzc_i_a_1;

  // ---------------------------------
  // Instantiate DUTs: RISCV=0 and RISCV=1
  // ---------------------------------
  fp_cvt #(.RISCV(0)) dut0 (
    .fp_cvt_f2f_i_data(fp_cvt_f2f_i_data),
    .fp_cvt_f2f_i_fmt(fp_cvt_f2f_i_fmt),
    .fp_cvt_f2f_i_rm(fp_cvt_f2f_i_rm),
    .fp_cvt_f2f_i_classification(fp_cvt_f2f_i_classification),
    .fp_cvt_f2f_o_fp_rnd_sig(f2f_o_sig_0),
    .fp_cvt_f2f_o_fp_rnd_expo(f2f_o_expo_0),
    .fp_cvt_f2f_o_fp_rnd_mant(f2f_o_mant_0),
    .fp_cvt_f2f_o_fp_rnd_rema(f2f_o_rema_0),
    .fp_cvt_f2f_o_fp_rnd_fmt(f2f_o_fmt_0),
    .fp_cvt_f2f_o_fp_rnd_rm(f2f_o_rm_0),
    .fp_cvt_f2f_o_fp_rnd_grs(f2f_o_grs_0),
    .fp_cvt_f2f_o_fp_rnd_snan(f2f_o_snan_0),
    .fp_cvt_f2f_o_fp_rnd_qnan(f2f_o_qnan_0),
    .fp_cvt_f2f_o_fp_rnd_dbz(f2f_o_dbz_0),
    .fp_cvt_f2f_o_fp_rnd_infs(f2f_o_infs_0),
    .fp_cvt_f2f_o_fp_rnd_zero(f2f_o_zero_0),
    .fp_cvt_f2f_o_fp_rnd_diff(f2f_o_diff_0),

    .fp_cvt_f2i_i_data(fp_cvt_f2i_i_data),
    .fp_cvt_f2i_i_op_fmadd(fp_cvt_f2i_i_op_fmadd),
    .fp_cvt_f2i_i_op_fmsub(fp_cvt_f2i_i_op_fmsub),
    .fp_cvt_f2i_i_op_fnmadd(fp_cvt_f2i_i_op_fnmadd),
    .fp_cvt_f2i_i_op_fnmsub(fp_cvt_f2i_i_op_fnmsub),
    .fp_cvt_f2i_i_op_fadd(fp_cvt_f2i_i_op_fadd),
    .fp_cvt_f2i_i_op_fsub(fp_cvt_f2i_i_op_fsub),
    .fp_cvt_f2i_i_op_fmul(fp_cvt_f2i_i_op_fmul),
    .fp_cvt_f2i_i_op_fdiv(fp_cvt_f2i_i_op_fdiv),
    .fp_cvt_f2i_i_op_fsqrt(fp_cvt_f2i_i_op_fsqrt),
    .fp_cvt_f2i_i_op_fsgnj(fp_cvt_f2i_i_op_fsgnj),
    .fp_cvt_f2i_i_op_fcmp(fp_cvt_f2i_i_op_fcmp),
    .fp_cvt_f2i_i_op_fmax(fp_cvt_f2i_i_op_fmax),
    .fp_cvt_f2i_i_op_fclass(fp_cvt_f2i_i_op_fclass),
    .fp_cvt_f2i_i_op_fmv_i2f(fp_cvt_f2i_i_op_fmv_i2f),
    .fp_cvt_f2i_i_op_fmv_f2i(fp_cvt_f2i_i_op_fmv_f2i),
    .fp_cvt_f2i_i_op_fcvt_f2f(fp_cvt_f2i_i_op_fcvt_f2f),
    .fp_cvt_f2i_i_op_fcvt_i2f(fp_cvt_f2i_i_op_fcvt_i2f),
    .fp_cvt_f2i_i_op_fcvt_f2i(fp_cvt_f2i_i_op_fcvt_f2i),
    .fp_cvt_f2i_i_op_fcvt_op(fp_cvt_f2i_i_op_fcvt_op),
    .fp_cvt_f2i_i_rm(fp_cvt_f2i_i_rm),
    .fp_cvt_f2i_i_classification(fp_cvt_f2i_i_classification),
    .fp_cvt_f2i_o_result(f2i_o_res_0),
    .fp_cvt_f2i_o_flags(f2i_o_flg_0),

    .fp_cvt_i2f_i_data(fp_cvt_i2f_i_data),
    .fp_cvt_i2f_i_op_fmadd(fp_cvt_i2f_i_op_fmadd),
    .fp_cvt_i2f_i_op_fmsub(fp_cvt_i2f_i_op_fmsub),
    .fp_cvt_i2f_i_op_fnmadd(fp_cvt_i2f_i_op_fnmadd),
    .fp_cvt_i2f_i_op_fnmsub(fp_cvt_i2f_i_op_fnmsub),
    .fp_cvt_i2f_i_op_fadd(fp_cvt_i2f_i_op_fadd),
    .fp_cvt_i2f_i_op_fsub(fp_cvt_i2f_i_op_fsub),
    .fp_cvt_i2f_i_op_fmul(fp_cvt_i2f_i_op_fmul),
    .fp_cvt_i2f_i_op_fdiv(fp_cvt_i2f_i_op_fdiv),
    .fp_cvt_i2f_i_op_fsqrt(fp_cvt_i2f_i_op_fsqrt),
    .fp_cvt_i2f_i_op_fsgnj(fp_cvt_i2f_i_op_fsgnj),
    .fp_cvt_i2f_i_op_fcmp(fp_cvt_i2f_i_op_fcmp),
    .fp_cvt_i2f_i_op_fmax(fp_cvt_i2f_i_op_fmax),
    .fp_cvt_i2f_i_op_fclass(fp_cvt_i2f_i_op_fclass),
    .fp_cvt_i2f_i_op_fmv_i2f(fp_cvt_i2f_i_op_fmv_i2f),
    .fp_cvt_i2f_i_op_fmv_f2i(fp_cvt_i2f_i_op_fmv_f2i),
    .fp_cvt_i2f_i_op_fcvt_f2f(fp_cvt_i2f_i_op_fcvt_f2f),
    .fp_cvt_i2f_i_op_fcvt_i2f(fp_cvt_i2f_i_op_fcvt_i2f),
    .fp_cvt_i2f_i_op_fcvt_f2i(fp_cvt_i2f_i_op_fcvt_f2i),
    .fp_cvt_i2f_i_op_fcvt_op(fp_cvt_i2f_i_op_fcvt_op),
    .fp_cvt_i2f_i_fmt(fp_cvt_i2f_i_fmt),
    .fp_cvt_i2f_i_rm(fp_cvt_i2f_i_rm),
    .fp_cvt_i2f_o_fp_rnd_sig(i2f_o_sig_0),
    .fp_cvt_i2f_o_fp_rnd_expo(i2f_o_expo_0),
    .fp_cvt_i2f_o_fp_rnd_mant(i2f_o_mant_0),
    .fp_cvt_i2f_o_fp_rnd_rema(i2f_o_rema_0),
    .fp_cvt_i2f_o_fp_rnd_fmt(i2f_o_fmt_0),
    .fp_cvt_i2f_o_fp_rnd_rm(i2f_o_rm_0),
    .fp_cvt_i2f_o_fp_rnd_grs(i2f_o_grs_0),
    .fp_cvt_i2f_o_fp_rnd_snan(i2f_o_snan_0),
    .fp_cvt_i2f_o_fp_rnd_qnan(i2f_o_qnan_0),
    .fp_cvt_i2f_o_fp_rnd_dbz(i2f_o_dbz_0),
    .fp_cvt_i2f_o_fp_rnd_infs(i2f_o_infs_0),
    .fp_cvt_i2f_o_fp_rnd_zero(i2f_o_zero_0),
    .fp_cvt_i2f_o_fp_rnd_diff(i2f_o_diff_0),

    .lzc_o_c(lzc_o_c_0),
    .lzc_o_v(lzc_o_v_0),
    .lzc_i_a(lzc_i_a_0)
  );

  fp_cvt #(.RISCV(1)) dut1 (
    .fp_cvt_f2f_i_data(fp_cvt_f2f_i_data),
    .fp_cvt_f2f_i_fmt(fp_cvt_f2f_i_fmt),
    .fp_cvt_f2f_i_rm(fp_cvt_f2f_i_rm),
    .fp_cvt_f2f_i_classification(fp_cvt_f2f_i_classification),
    .fp_cvt_f2f_o_fp_rnd_sig(f2f_o_sig_1),
    .fp_cvt_f2f_o_fp_rnd_expo(f2f_o_expo_1),
    .fp_cvt_f2f_o_fp_rnd_mant(f2f_o_mant_1),
    .fp_cvt_f2f_o_fp_rnd_rema(f2f_o_rema_1),
    .fp_cvt_f2f_o_fp_rnd_fmt(f2f_o_fmt_1),
    .fp_cvt_f2f_o_fp_rnd_rm(f2f_o_rm_1),
    .fp_cvt_f2f_o_fp_rnd_grs(f2f_o_grs_1),
    .fp_cvt_f2f_o_fp_rnd_snan(f2f_o_snan_1),
    .fp_cvt_f2f_o_fp_rnd_qnan(f2f_o_qnan_1),
    .fp_cvt_f2f_o_fp_rnd_dbz(f2f_o_dbz_1),
    .fp_cvt_f2f_o_fp_rnd_infs(f2f_o_infs_1),
    .fp_cvt_f2f_o_fp_rnd_zero(f2f_o_zero_1),
    .fp_cvt_f2f_o_fp_rnd_diff(f2f_o_diff_1),

    .fp_cvt_f2i_i_data(fp_cvt_f2i_i_data),
    .fp_cvt_f2i_i_op_fmadd(fp_cvt_f2i_i_op_fmadd),
    .fp_cvt_f2i_i_op_fmsub(fp_cvt_f2i_i_op_fmsub),
    .fp_cvt_f2i_i_op_fnmadd(fp_cvt_f2i_i_op_fnmadd),
    .fp_cvt_f2i_i_op_fnmsub(fp_cvt_f2i_i_op_fnmsub),
    .fp_cvt_f2i_i_op_fadd(fp_cvt_f2i_i_op_fadd),
    .fp_cvt_f2i_i_op_fsub(fp_cvt_f2i_i_op_fsub),
    .fp_cvt_f2i_i_op_fmul(fp_cvt_f2i_i_op_fmul),
    .fp_cvt_f2i_i_op_fdiv(fp_cvt_f2i_i_op_fdiv),
    .fp_cvt_f2i_i_op_fsqrt(fp_cvt_f2i_i_op_fsqrt),
    .fp_cvt_f2i_i_op_fsgnj(fp_cvt_f2i_i_op_fsgnj),
    .fp_cvt_f2i_i_op_fcmp(fp_cvt_f2i_i_op_fcmp),
    .fp_cvt_f2i_i_op_fmax(fp_cvt_f2i_i_op_fmax),
    .fp_cvt_f2i_i_op_fclass(fp_cvt_f2i_i_op_fclass),
    .fp_cvt_f2i_i_op_fmv_i2f(fp_cvt_f2i_i_op_fmv_i2f),
    .fp_cvt_f2i_i_op_fmv_f2i(fp_cvt_f2i_i_op_fmv_f2i),
    .fp_cvt_f2i_i_op_fcvt_f2f(fp_cvt_f2i_i_op_fcvt_f2f),
    .fp_cvt_f2i_i_op_fcvt_i2f(fp_cvt_f2i_i_op_fcvt_i2f),
    .fp_cvt_f2i_i_op_fcvt_f2i(fp_cvt_f2i_i_op_fcvt_f2i),
    .fp_cvt_f2i_i_op_fcvt_op(fp_cvt_f2i_i_op_fcvt_op),
    .fp_cvt_f2i_i_rm(fp_cvt_f2i_i_rm),
    .fp_cvt_f2i_i_classification(fp_cvt_f2i_i_classification),
    .fp_cvt_f2i_o_result(f2i_o_res_1),
    .fp_cvt_f2i_o_flags(f2i_o_flg_1),

    .fp_cvt_i2f_i_data(fp_cvt_i2f_i_data),
    .fp_cvt_i2f_i_op_fmadd(fp_cvt_i2f_i_op_fmadd),
    .fp_cvt_i2f_i_op_fmsub(fp_cvt_i2f_i_op_fmsub),
    .fp_cvt_i2f_i_op_fnmadd(fp_cvt_i2f_i_op_fnmadd),
    .fp_cvt_i2f_i_op_fnmsub(fp_cvt_i2f_i_op_fnmsub),
    .fp_cvt_i2f_i_op_fadd(fp_cvt_i2f_i_op_fadd),
    .fp_cvt_i2f_i_op_fsub(fp_cvt_i2f_i_op_fsub),
    .fp_cvt_i2f_i_op_fmul(fp_cvt_i2f_i_op_fmul),
    .fp_cvt_i2f_i_op_fdiv(fp_cvt_i2f_i_op_fdiv),
    .fp_cvt_i2f_i_op_fsqrt(fp_cvt_i2f_i_op_fsqrt),
    .fp_cvt_i2f_i_op_fsgnj(fp_cvt_i2f_i_op_fsgnj),
    .fp_cvt_i2f_i_op_fcmp(fp_cvt_i2f_i_op_fcmp),
    .fp_cvt_i2f_i_op_fmax(fp_cvt_i2f_i_op_fmax),
    .fp_cvt_i2f_i_op_fclass(fp_cvt_i2f_i_op_fclass),
    .fp_cvt_i2f_i_op_fmv_i2f(fp_cvt_i2f_i_op_fmv_i2f),
    .fp_cvt_i2f_i_op_fmv_f2i(fp_cvt_i2f_i_op_fmv_f2i),
    .fp_cvt_i2f_i_op_fcvt_f2f(fp_cvt_i2f_i_op_fcvt_f2f),
    .fp_cvt_i2f_i_op_fcvt_i2f(fp_cvt_i2f_i_op_fcvt_i2f),
    .fp_cvt_i2f_i_op_fcvt_f2i(fp_cvt_i2f_i_op_fcvt_f2i),
    .fp_cvt_i2f_i_op_fcvt_op(fp_cvt_i2f_i_op_fcvt_op),
    .fp_cvt_i2f_i_fmt(fp_cvt_i2f_i_fmt),
    .fp_cvt_i2f_i_rm(fp_cvt_i2f_i_rm),
    .fp_cvt_i2f_o_fp_rnd_sig(i2f_o_sig_1),
    .fp_cvt_i2f_o_fp_rnd_expo(i2f_o_expo_1),
    .fp_cvt_i2f_o_fp_rnd_mant(i2f_o_mant_1),
    .fp_cvt_i2f_o_fp_rnd_rema(i2f_o_rema_1),
    .fp_cvt_i2f_o_fp_rnd_fmt(i2f_o_fmt_1),
    .fp_cvt_i2f_o_fp_rnd_rm(i2f_o_rm_1),
    .fp_cvt_i2f_o_fp_rnd_grs(i2f_o_grs_1),
    .fp_cvt_i2f_o_fp_rnd_snan(i2f_o_snan_1),
    .fp_cvt_i2f_o_fp_rnd_qnan(i2f_o_qnan_1),
    .fp_cvt_i2f_o_fp_rnd_dbz(i2f_o_dbz_1),
    .fp_cvt_i2f_o_fp_rnd_infs(i2f_o_infs_1),
    .fp_cvt_i2f_o_fp_rnd_zero(i2f_o_zero_1),
    .fp_cvt_i2f_o_fp_rnd_diff(i2f_o_diff_1),

    .lzc_o_c(lzc_o_c_1),
    .lzc_o_v(lzc_o_v_1),
    .lzc_i_a(lzc_i_a_1)
  );

  // ---------------------------------
  // Simple combinational LZC models per instance
  // Note: DUT uses v_i2f_counter_uint = ~lzc_o_c, so we drive lzc_o_c as bitwise-not of actual count
  // ---------------------------------
  function [5:0] lzc64(input [63:0] a);
    integer i;
    reg found;
    reg [5:0] cnt;
    begin
      found = 1'b0;
      cnt   = 6'd0;
      for (i = 63; i >= 0; i = i - 1) begin
        if (!found && a[i]) begin
          cnt   = 6'd63 - i[5:0];
          found = 1'b1;
        end
      end
      // If all zeros, define count as 6'd63 (saturate to fit 6 bits)
      if (!found) cnt = 6'd63;
      lzc64 = cnt;
    end
  endfunction

  always @(*) begin
    lzc_o_v_0 = 1'b1;
    lzc_o_c_0 = ~lzc64(lzc_i_a_0);
  end

  always @(*) begin
    lzc_o_v_1 = 1'b1;
    lzc_o_c_1 = ~lzc64(lzc_i_a_1);
  end

  // ---------------------------------
  // Helpers: pack 65-bit FP, classification (RISC-V fclass mapping)
  // ---------------------------------
  function [64:0] pack65_from_raw64(input [63:0] raw);
    begin
      pack65_from_raw64 = {raw[63], raw[62:52], raw[51:0]};
    end
  endfunction

  function [9:0] fclass10(input [64:0] data65);
    reg sign;
    reg [10:0] exp;
    reg [51:0] frac;
    reg isZero, isSub, isInf, isNaN, isQNaN, isSNaN;
    begin
      sign = data65[64];
      exp  = data65[63:52];
      frac = data65[51:0];
      isZero = (exp == 11'd0) && (frac == 52'd0);
      isSub  = (exp == 11'd0) && (frac != 52'd0);
      isInf  = (exp == 11'h7FF) && (frac == 52'd0);
      isNaN  = (exp == 11'h7FF) && (frac != 52'd0);
      isQNaN = isNaN && frac[51];
      isSNaN = isNaN && ~frac[51];
      fclass10 = 10'd0;
      if (isSNaN) fclass10[8] = 1'b1;
      if (isQNaN) fclass10[9] = 1'b1;
      if (isInf &&  sign) fclass10[0] = 1'b1; // -Inf
      if (~isInf && ~isNaN && ~isZero && ~isSub && sign) fclass10[1] = 1'b1; // neg normal
      if (isSub && sign) fclass10[2] = 1'b1; // neg sub
      if (isZero && sign) fclass10[3] = 1'b1; // -0
      if (isZero && ~sign) fclass10[4] = 1'b1; // +0
      if (isSub && ~sign) fclass10[5] = 1'b1; // pos sub
      if (~isInf && ~isNaN && ~isZero && ~isSub && ~sign) fclass10[6] = 1'b1; // pos normal
      if (isInf && ~sign) fclass10[7] = 1'b1; // +Inf
    end
  endfunction

  // ---------------------------------
  // Golden models (replicate DUT math)
  // ---------------------------------
  task golden_i2f(
    input  [63:0] data,
    input  [1:0]  op_fcvt, // 00:32s,01:32u,10:64s,11:64u
    input  [1:0]  fmt,     // 0 single, 1 double
    input  [2:0]  rm,
    output        o_sig,
    output [13:0] o_expo,
    output [53:0] o_mant,
    output [2:0]  o_grs,
    output        o_zero
  );
    reg        sign_uint;
    reg [63:0] mag;
    reg [63:0] mantissa_uint;
    reg [5:0]  exponent_uint;
    reg [9:0]  exponent_bias;
    reg [5:0]  lzc_cnt;
    reg [5:0]  counter_uint;
    reg [63:0] norm_mant;
    reg [13:0] exponent_rnd;
    reg [53:0] mant_rnd;
    reg [2:0]  grs;
    begin
      // sign determination for signed ops
      sign_uint = 1'b0;
      if (op_fcvt == 2'b00) sign_uint = data[31];
      else if (op_fcvt == 2'b10) sign_uint = data[63];

      // magnitude (two's complement for signed negative)
      mag = data;
      if (sign_uint) mag = -mag;

      // input width selection
      mantissa_uint = 64'hFFFFFFFF_FFFFFFFF;
      exponent_uint = 6'd0;
      if (~op_fcvt[1]) begin
        mantissa_uint = {mag[31:0], 32'h0};
        exponent_uint = 6'd31;
      end else begin
        mantissa_uint = mag;
        exponent_uint = 6'd63;
      end

      o_zero = ~|mantissa_uint;

      // exponent bias for target fmt
      exponent_bias = (fmt == 2'd1) ? 10'd1023 : 10'd127;

      // leading zero count and normalization
      lzc_cnt = lzc64(mantissa_uint);
      counter_uint = lzc_cnt;
      norm_mant = mantissa_uint << counter_uint;

      // pack results
      o_sig  = sign_uint;
      exponent_rnd = {8'b0, exponent_uint} + {4'b0, exponent_bias} - {8'b0, counter_uint};
      if (fmt == 2'd0) begin
        mant_rnd = {30'h0, norm_mant[63:40]};
        grs      = {norm_mant[39:38], |norm_mant[37:0]};
      end else begin
        mant_rnd = {1'b0, norm_mant[63:11]};
        grs      = {norm_mant[10:9], |norm_mant[8:0]};
      end
      o_expo = exponent_rnd;
      o_mant = mant_rnd;
      o_grs  = grs;
    end
  endtask

  task golden_f2f(
    input  [64:0] data65,
    input  [1:0]  tgt_fmt, // 0 single, 1 double
    input  [2:0]  rm,
    input  [9:0]  classif,
    output        o_sig,
    output [13:0] o_expo,
    output [53:0] o_mant,
    output [2:0]  o_grs,
    output        o_zero,
    output        o_infs,
    output        o_snan,
    output        o_qnan
  );
    reg [1:0]  v_fmt;
    reg [2:0]  v_rm;
    reg [9:0]  v_class;
    reg        s_snan, s_qnan, s_infs, s_zero;
    reg [10:0] exponent_cvt;
    reg [79:0] mantissa_cvt;
    reg [10:0] exponent_bias;
    reg        sign_rnd;
    reg [13:0] exponent_rnd;
    reg [13:0] counter_cvt;
    reg [53:0] mantissa_rnd;
    reg [2:0]  grs;
    reg signed [13:0] expo_tmp;
    begin
      v_fmt   = tgt_fmt;
      v_rm    = rm;
      v_class = classif;
      s_snan  = v_class[8];
      s_qnan  = v_class[9];
      s_infs  = v_class[0] | v_class[7];
      s_zero  = v_class[3] | v_class[4];

      exponent_cvt = data65[63:52];
      mantissa_cvt = {2'b01, data65[51:0], 26'h0};

      exponent_bias = 11'd1920; // single target
      if (v_fmt == 2'd1) exponent_bias = 11'd1024; // double target

      sign_rnd = data65[64];
      exponent_rnd = {2'b00, exponent_cvt} - {3'b000, exponent_bias};

      counter_cvt = 14'd0;
      expo_tmp = $signed(exponent_rnd);
      if (expo_tmp <= 0) begin
        counter_cvt = 14'd63;
        if (expo_tmp > -14'sd63) counter_cvt = 14'h1 - exponent_rnd;
        exponent_rnd = 14'd0;
      end
      mantissa_cvt = mantissa_cvt >> counter_cvt[5:0];

      mantissa_rnd = {29'h0, mantissa_cvt[79:55]};
      grs = {mantissa_cvt[54:53], |mantissa_cvt[52:0]};
      if (v_fmt == 2'd1) begin
        mantissa_rnd = mantissa_cvt[79:26];
        grs = {mantissa_cvt[25:24], |mantissa_cvt[23:0]};
      end

      o_sig  = sign_rnd;
      o_expo = exponent_rnd;
      o_mant = mantissa_rnd;
      o_grs  = grs;
      o_snan = s_snan;
      o_qnan = s_qnan;
      o_infs = s_infs;
      o_zero = s_zero;
    end
  endtask

  task golden_f2i(
    input  [64:0] data65,
    input  [1:0]  op_fcvt, // 00:32s,01:32u,10:64s,11:64u
    input  [2:0]  rm,
    input  [9:0]  classif,
    input         riscv_one, // 0 to match RISCV=0, 1 for RISCV=1
    output [63:0] o_res,
    output [4:0]  o_flg
  );
    reg [64:0] v_data;
    reg [1:0]  v_op;
    reg [2:0]  v_rm;
    reg [9:0]  v_class;
    reg [63:0] v_result;
    reg [4:0]  v_flags;

    reg v_snan, v_qnan, v_infs, v_zero;
    reg v_sign_cvt;
    reg signed [12:0] v_exponent_cvt;
    reg [119:0] v_mantissa_cvt;
    reg [7:0] v_exponent_bias;
    reg [64:0] v_mantissa_uint;
    reg [2:0] v_grs;
    reg v_odd, v_rnded, v_oor;
    reg v_or_1, v_or_2, v_or_3, v_or_4, v_or_5;
    reg v_oor_64u, v_oor_64s, v_oor_32u, v_oor_32s;

    begin
      v_data  = data65;
      v_op    = op_fcvt;
      v_rm    = rm;
      v_class = classif;

      v_flags  = 5'b00000;
      v_result = 64'd0;

      v_snan = v_class[8];
      v_qnan = v_class[9];
      v_infs = v_class[0] | v_class[7];
      v_zero = 1'b0;

      case (v_op)
        2'b00: v_exponent_bias = 8'd34; // 32s
        2'b01: v_exponent_bias = 8'd35; // 32u
        2'b10: v_exponent_bias = 8'd66; // 64s
        default: v_exponent_bias = 8'd67; // 64u
      endcase

      v_sign_cvt = v_data[64];
      v_exponent_cvt = $signed({2'b00, v_data[63:52]}) - $signed(13'd2044);
      v_mantissa_cvt = {68'h1, v_data[51:0]};
      if ((v_class[3] | v_class[4]) == 1'b1) begin
        v_mantissa_cvt[52] = 1'b0;
      end

      v_oor = 1'b0;
      if ($signed(v_exponent_cvt) > $signed({5'b0, v_exponent_bias})) begin
        v_oor = 1'b1;
      end else if ($signed(v_exponent_cvt) > 0) begin
        v_mantissa_cvt = v_mantissa_cvt << v_exponent_cvt;
      end

      v_mantissa_uint = v_mantissa_cvt[119:55];

      v_grs = {v_mantissa_cvt[54:53], |v_mantissa_cvt[52:0]};
      v_odd = v_mantissa_uint[0] | (|v_grs[1:0]);

      v_flags[0] = |v_grs;

      v_rnded = 1'b0;
      case (v_rm)
        3'b000: if (v_grs[2] & v_odd) v_rnded = 1'b1;        // RNE
        3'b010: if (v_sign_cvt & v_flags[0]) v_rnded = 1'b1; // RDN
        3'b011: if (~v_sign_cvt & v_flags[0]) v_rnded = 1'b1; // RUP
        3'b100: if (v_grs[2] & v_flags[0]) v_rnded = 1'b1;   // RMM
        default: ;
      endcase

      v_mantissa_uint = v_mantissa_uint + {64'b0, v_rnded};

      v_or_1 = v_mantissa_uint[64];
      v_or_2 = v_mantissa_uint[63];
      v_or_3 = |v_mantissa_uint[62:32];
      v_or_4 = v_mantissa_uint[31];
      v_or_5 = |v_mantissa_uint[30:0];

      v_zero = v_or_1 | v_or_2 | v_or_3 | v_or_4 | v_or_5; // per DUT

      v_oor_64u = v_or_1;
      v_oor_64s = v_or_1;
      v_oor_32u = v_or_1 | v_or_2 | v_or_3;
      v_oor_32s = v_or_1 | v_or_2 | v_or_3;

      if (v_sign_cvt) begin
        if (v_op == 2'b00) begin
          v_oor_32s = v_oor_32s | (v_or_4 & v_or_5);
        end else if (v_op == 2'b01) begin
          v_oor = v_oor | v_zero;
        end else if (v_op == 2'b10) begin
          v_oor_64s = v_oor_64s | (v_or_2 & (v_or_3 | v_or_4 | v_or_5));
        end else if (v_op == 2'b11) begin
          v_oor = v_oor | v_zero;
        end
      end else begin
        v_oor_64s = v_oor_64s | v_or_2;
        v_oor_32s = v_oor_32s | v_or_4;
      end

      v_oor_64u = (v_op == 2'b11) & (v_oor_64u | v_oor | v_infs | v_snan | v_qnan);
      v_oor_64s = (v_op == 2'b10) & (v_oor_64s | v_oor | v_infs | v_snan | v_qnan);
      v_oor_32u = (v_op == 2'b01) & (v_oor_32u | v_oor | v_infs | v_snan | v_qnan);
      v_oor_32s = (v_op == 2'b00) & (v_oor_32s | v_oor | v_infs | v_snan | v_qnan);

      if (v_sign_cvt) begin
        v_mantissa_uint = -v_mantissa_uint;
      end

      if (v_op == 2'b00) begin
        v_result = {32'h0, v_mantissa_uint[31:0]};
        if (v_oor_32s) begin
          if (riscv_one && v_sign_cvt && ~(v_snan | v_qnan))
            v_result = 64'h0000000080000000; // INT32_MIN
          else if (riscv_one && ~v_sign_cvt)
            v_result = 64'h000000007FFFFFFF; // INT32_MAX
          else
            v_result = 64'h0000000080000000; // RISCV=0 behavior
          v_flags  = 5'b10000;
        end
      end else if (v_op == 2'b01) begin
        v_result = {32'h0, v_mantissa_uint[31:0]};
        if (v_oor_32u) begin
          if (riscv_one && v_sign_cvt && ~(v_snan | v_qnan))
            v_result = 64'h0000000000000000; // 0 if negative input (invalid)
          else
            v_result = 64'h00000000FFFFFFFF; // UINT32_MAX
          v_flags  = 5'b10000;
        end
      end else if (v_op == 2'b10) begin
        v_result = v_mantissa_uint[63:0];
        if (v_oor_64s) begin
          if (riscv_one && v_sign_cvt && ~(v_snan | v_qnan))
            v_result = 64'h8000000000000000; // INT64_MIN
          else if (riscv_one && ~v_sign_cvt)
            v_result = 64'h7FFFFFFFFFFFFFFF; // INT64_MAX
          else
            v_result = 64'h8000000000000000; // RISCV=0 behavior
          v_flags  = 5'b10000;
        end
      end else begin
        v_result = v_mantissa_uint[63:0];
        if (v_oor_64u) begin
          if (riscv_one && v_sign_cvt && ~(v_snan | v_qnan))
            v_result = 64'h0000000000000000; // 0 if negative input
          else
            v_result = 64'hFFFFFFFFFFFFFFFF; // UINT64_MAX
          v_flags  = 5'b10000;
        end
      end

      o_res = v_result;
      o_flg = v_flags;
    end
  endtask

  // ---------------------------------
  // Scoreboard utilities
  // ---------------------------------
  integer total_checks = 0;
  integer failed_checks = 0;

  task expect_eq_1b(input [255:0] msg, input got, input exp);
    begin
      total_checks = total_checks + 1;
      if (got !== exp) begin
        failed_checks = failed_checks + 1;
        $display("[FAIL] %s: got=%0d exp=%0d", msg, got, exp);
      end
    end
  endtask

  task expect_eq_vec(input [255:0] msg, input [255:0] got, input [255:0] exp);
    begin
      total_checks = total_checks + 1;
      if (got !== exp) begin
        failed_checks = failed_checks + 1;
        $display("[FAIL] %s: got=%h exp=%h", msg, got, exp);
      end
    end
  endtask

  // ---------------------------------
  // Directed tests
  // ---------------------------------
  task test_i2f_case(input [63:0] val, input [1:0] op, input [1:0] fmt, input [2:0] rm);
    reg exp_sig;
    reg [13:0] exp_expo;
    reg [53:0] exp_mant;
    reg [2:0] exp_grs;
    reg exp_zero;
    begin
      // Drive inputs
      fp_cvt_i2f_i_data = val;
      fp_cvt_i2f_i_op_fcvt_op = op;
      fp_cvt_i2f_i_fmt = fmt;
      fp_cvt_i2f_i_rm  = rm;
      // others low
      fp_cvt_i2f_i_op_fmadd=0; fp_cvt_i2f_i_op_fmsub=0; fp_cvt_i2f_i_op_fnmadd=0; fp_cvt_i2f_i_op_fnmsub=0;
      fp_cvt_i2f_i_op_fadd=0;  fp_cvt_i2f_i_op_fsub=0;  fp_cvt_i2f_i_op_fmul=0;   fp_cvt_i2f_i_op_fdiv=0;
      fp_cvt_i2f_i_op_fsqrt=0; fp_cvt_i2f_i_op_fsgnj=0; fp_cvt_i2f_i_op_fcmp=0;   fp_cvt_i2f_i_op_fmax=0;
      fp_cvt_i2f_i_op_fclass=0;fp_cvt_i2f_i_op_fmv_i2f=0;fp_cvt_i2f_i_op_fmv_f2i=0;fp_cvt_i2f_i_op_fcvt_f2f=0;
      fp_cvt_i2f_i_op_fcvt_i2f=0; fp_cvt_i2f_i_op_fcvt_f2i=0;

      // Golden
      golden_i2f(val, op, fmt, rm, exp_sig, exp_expo, exp_mant, exp_grs, exp_zero);

      #1; // allow combinational settle

      expect_eq_1b("i2f.sig", i2f_o_sig_0, exp_sig);
      expect_eq_vec("i2f.expo", {18'd0, i2f_o_expo_0}, {18'd0, exp_expo});
      expect_eq_vec("i2f.mant", i2f_o_mant_0, exp_mant);
      expect_eq_vec("i2f.grs", {5'd0, i2f_o_grs_0}, {5'd0, exp_grs});
      expect_eq_1b("i2f.zero", i2f_o_zero_0, exp_zero);

      // instance 1 must match too (same path)
      expect_eq_1b("i2f.sig.i1", i2f_o_sig_1, exp_sig);
      expect_eq_vec("i2f.expo.i1", {18'd0, i2f_o_expo_1}, {18'd0, exp_expo});
      expect_eq_vec("i2f.mant.i1", i2f_o_mant_1, exp_mant);
      expect_eq_vec("i2f.grs.i1", {5'd0, i2f_o_grs_1}, {5'd0, exp_grs});
      expect_eq_1b("i2f.zero.i1", i2f_o_zero_1, exp_zero);
    end
  endtask

  task test_f2f_case(input [63:0] raw64, input [1:0] tgt_fmt, input [2:0] rm);
    reg [64:0] d65;
    reg exp_sig;
    reg [13:0] exp_expo;
    reg [53:0] exp_mant;
    reg [2:0]  exp_grs;
    reg exp_zero, exp_infs, exp_snan, exp_qnan;
    begin
      d65 = pack65_from_raw64(raw64);
      fp_cvt_f2f_i_data = d65;
      fp_cvt_f2f_i_fmt  = tgt_fmt;
      fp_cvt_f2f_i_rm   = rm;
      fp_cvt_f2f_i_classification = fclass10(d65);

      golden_f2f(d65, tgt_fmt, rm, fp_cvt_f2f_i_classification,
                 exp_sig, exp_expo, exp_mant, exp_grs, exp_zero, exp_infs, exp_snan, exp_qnan);

      #1;

      expect_eq_1b("f2f.sig", f2f_o_sig_0, exp_sig);
      expect_eq_vec("f2f.expo", {18'd0, f2f_o_expo_0}, {18'd0, exp_expo});
      expect_eq_vec("f2f.mant", f2f_o_mant_0, exp_mant);
      expect_eq_vec("f2f.grs", {5'd0, f2f_o_grs_0}, {5'd0, exp_grs});
      expect_eq_1b("f2f.zero", f2f_o_zero_0, exp_zero);
      expect_eq_1b("f2f.infs", f2f_o_infs_0, exp_infs);
      expect_eq_1b("f2f.snan", f2f_o_snan_0, exp_snan);
      expect_eq_1b("f2f.qnan", f2f_o_qnan_0, exp_qnan);

      // instance 1 must match too (same path)
      expect_eq_1b("f2f.sig.i1", f2f_o_sig_1, exp_sig);
      expect_eq_vec("f2f.expo.i1", {18'd0, f2f_o_expo_1}, {18'd0, exp_expo});
      expect_eq_vec("f2f.mant.i1", f2f_o_mant_1, exp_mant);
      expect_eq_vec("f2f.grs.i1", {5'd0, f2f_o_grs_1}, {5'd0, exp_grs});
      expect_eq_1b("f2f.zero.i1", f2f_o_zero_1, exp_zero);
      expect_eq_1b("f2f.infs.i1", f2f_o_infs_1, exp_infs);
      expect_eq_1b("f2f.snan.i1", f2f_o_snan_1, exp_snan);
      expect_eq_1b("f2f.qnan.i1", f2f_o_qnan_1, exp_qnan);
    end
  endtask

  task test_f2i_case(input [63:0] raw64, input [1:0] op, input [2:0] rm);
    reg [64:0] d65;
    reg [63:0] exp_res0, exp_res1;
    reg [4:0]  exp_flg0, exp_flg1;
    begin
      d65 = pack65_from_raw64(raw64);
      fp_cvt_f2i_i_data = d65;
      fp_cvt_f2i_i_op_fcvt_op = op;
      fp_cvt_f2i_i_rm = rm;
      fp_cvt_f2i_i_classification = fclass10(d65);

      // unused ops low
      fp_cvt_f2i_i_op_fmadd=0; fp_cvt_f2i_i_op_fmsub=0; fp_cvt_f2i_i_op_fnmadd=0; fp_cvt_f2i_i_op_fnmsub=0;
      fp_cvt_f2i_i_op_fadd=0;  fp_cvt_f2i_i_op_fsub=0;  fp_cvt_f2i_i_op_fmul=0;   fp_cvt_f2i_i_op_fdiv=0;
      fp_cvt_f2i_i_op_fsqrt=0; fp_cvt_f2i_i_op_fsgnj=0; fp_cvt_f2i_i_op_fcmp=0;   fp_cvt_f2i_i_op_fmax=0;
      fp_cvt_f2i_i_op_fclass=0;fp_cvt_f2i_i_op_fmv_i2f=0;fp_cvt_f2i_i_op_fmv_f2i=0;fp_cvt_f2i_i_op_fcvt_f2f=0;
      fp_cvt_f2i_i_op_fcvt_i2f=0; fp_cvt_f2i_i_op_fcvt_f2i=0;

      golden_f2i(d65, op, rm, fp_cvt_f2i_i_classification, 1'b0, exp_res0, exp_flg0); // RISCV=0
      golden_f2i(d65, op, rm, fp_cvt_f2i_i_classification, 1'b1, exp_res1, exp_flg1); // RISCV=1

      #1;

      expect_eq_vec("f2i.res.riscv0", f2i_o_res_0, exp_res0);
      expect_eq_vec("f2i.flg.riscv0", {59'd0, f2i_o_flg_0}, {59'd0, exp_flg0});

      expect_eq_vec("f2i.res.riscv1", f2i_o_res_1, exp_res1);
      expect_eq_vec("f2i.flg.riscv1", {59'd0, f2i_o_flg_1}, {59'd0, exp_flg1});
    end
  endtask

  // ---------------------------------
  // Random generators
  // ---------------------------------
  function [63:0] rand64;
    reg [31:0] a, b;
    begin
      a = $random;
      b = $random;
      rand64 = {a, b};
    end
  endfunction

  function [63:0] rand_norm_double;
    reg [63:0] r;
    reg [10:0] exp;
    reg [51:0] fra;
    reg [0:0] s;
    begin
      s   = $random;
      fra = rand64()[51:0];
      // Create exponent in [1, 2046] but avoid 2047 (Inf/NaN) and 0 (zero/sub)
      exp = ($random & 11'h7FF);
      if (exp == 11'd0)     exp = 11'd1;
      if (exp == 11'h7FF)   exp = 11'h7FE;
      rand_norm_double = {s[0], exp[10:0], fra[51:0]};
    end
  endfunction

  // ---------------------------------
  // Test sequence
  // ---------------------------------
  initial begin
    integer i;

    // defaults
    fp_cvt_f2f_i_data = 65'd0; fp_cvt_f2f_i_fmt = 0; fp_cvt_f2f_i_rm = 3'b000; fp_cvt_f2f_i_classification = 10'd0;
    fp_cvt_f2i_i_data = 65'd0; fp_cvt_f2i_i_op_fcvt_op = 2'b00; fp_cvt_f2i_i_rm = 3'b000; fp_cvt_f2i_i_classification = 10'd0;
    fp_cvt_i2f_i_data = 64'd0; fp_cvt_i2f_i_op_fcvt_op = 2'b00; fp_cvt_i2f_i_fmt = 2'd0; fp_cvt_i2f_i_rm = 3'b000;

    // ---------------- Directed: i2f ----------------
    test_i2f_case(64'd0,  2'b00, 2'd0, 3'b000); // 32s -> single, 0
    test_i2f_case(64'd1,  2'b00, 2'd0, 3'b000); // 32s -> single, 1
    test_i2f_case(-64'sd1,2'b00, 2'd1, 3'b000); // 32s -> double, -1
    test_i2f_case(64'h7FFFFFFF, 2'b00, 2'd1, 3'b000); // INT32_MAX
    test_i2f_case(64'h80000000, 2'b00, 2'd1, 3'b000); // INT32_MIN magnitude
    test_i2f_case(64'hFFFFFFFF, 2'b01, 2'd0, 3'b000); // 32u max -> single

    test_i2f_case(64'd0,  2'b10, 2'd1, 3'b000); // 64s -> double, 0
    test_i2f_case(64'd1,  2'b10, 2'd1, 3'b000); // 64s -> double, 1
    test_i2f_case(-64'sd1,2'b10, 2'd1, 3'b000); // 64s -> double, -1
    test_i2f_case(64'h7FFF_FFFF_FFFF_FFFF, 2'b10, 2'd1, 3'b000);
    test_i2f_case(64'h8000_0000_0000_0000, 2'b11, 2'd1, 3'b000); // unsigned path

    // ---------------- Directed: f2i ----------------
    // key constants
    test_f2i_case(64'h0000_0000_0000_0000, 2'b00, 3'b000); // +0 -> 32s
    test_f2i_case(64'h8000_0000_0000_0000, 2'b00, 3'b000); // -0 -> 32s
    test_f2i_case(64'h3FF0_0000_0000_0000, 2'b00, 3'b000); // 1.0
    test_f2i_case(64'hBFF0_0000_0000_0000, 2'b00, 3'b000); // -1.0
    test_f2i_case(64'h3FF8_0000_0000_0000, 2'b00, 3'b000); // 1.5 (RNE ties to even)
    test_f2i_case(64'h4004_0000_0000_0000, 2'b00, 3'b000); // 2.5
    test_f2i_case(64'hC004_0000_0000_0000, 2'b00, 3'b000); // -2.5
    test_f2i_case(64'h7FF0_0000_0000_0000, 2'b10, 3'b000); // +Inf -> 64s
    test_f2i_case(64'hFFF0_0000_0000_0000, 2'b10, 3'b000); // -Inf -> 64s
    test_f2i_case(64'h7FF8_0000_0000_0000, 2'b11, 3'b000); // qNaN -> 64u
    test_f2i_case(64'h7FF0_0000_0000_0001, 2'b11, 3'b000); // sNaN -> 64u
    // boundary large (>= 2^63)
    test_f2i_case(64'h43E0_0000_0000_0000, 2'b10, 3'b000); // 2^63 -> overflow signed

    // Rounding mode variations
    test_f2i_case(64'h3FE0_0000_0000_0000, 2'b00, 3'b001); // 0.5 RTZ
    test_f2i_case(64'h3FE0_0000_0000_0000, 2'b00, 3'b010); // 0.5 RDN
    test_f2i_case(64'h3FE0_0000_0000_0000, 2'b00, 3'b011); // 0.5 RUP
    test_f2i_case(64'h3FE8_0000_0000_0000, 2'b00, 3'b100); // 0.75 RMM

    // ---------------- Directed: f2f ----------------
    test_f2f_case(64'h0000_0000_0000_0000, 2'd0, 3'b000); // +0 -> single pack
    test_f2f_case(64'h8000_0000_0000_0000, 2'd0, 3'b000); // -0
    test_f2f_case(64'h3FF0_0000_0000_0000, 2'd0, 3'b000); // 1.0 -> single
    test_f2f_case(64'h4008_0000_0000_0000, 2'd0, 3'b000); // 3.0 -> single
    test_f2f_case(64'h7FF0_0000_0000_0000, 2'd0, 3'b000); // +Inf
    test_f2f_case(64'hFFF0_0000_0000_0000, 2'd0, 3'b000); // -Inf
    test_f2f_case(64'h7FF8_0000_0000_0000, 2'd0, 3'b000); // qNaN
    test_f2f_case(64'h7FF0_0000_0000_0001, 2'd0, 3'b000); // sNaN

    // also identity in double target
    test_f2f_case(64'h3FF0_0000_0000_0000, 2'd1, 3'b000); // 1.0 -> double target

    // ---------------- Random: i2f/f2i/f2f ----------------
    for (i = 0; i < 100; i = i + 1) begin
      test_i2f_case(rand64(), {$random}%4, {$random}%2, {$random}%5);
    end

    for (i = 0; i < 100; i = i + 1) begin
      test_f2i_case(rand_norm_double(), {$random}%4, {$random}%5);
    end

    for (i = 0; i < 100; i = i + 1) begin
      test_f2f_case(rand_norm_double(), {$random}%2, {$random}%5);
    end

    // Summary
    if (failed_checks == 0) begin
      $display("\nAll %0d checks PASSED.", total_checks);
    end else begin
      $display("\n%0d/%0d checks FAILED.", failed_checks, total_checks);
    end
    $finish;
  end

endmodule
