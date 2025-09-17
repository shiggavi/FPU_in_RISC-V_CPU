// tb_fp_decode.v
// Simple self-checking testbench for fp_decode (F + D decode).
// It exercises a handful of representative instructions across all FP major groups,
// including OP-FP (F/D), R4 FMAs, loads/stores, moves, and conversions, plus illegal fmt checks.
//

`timescale 1ns/1ps

module tb_fp_decode;

  // DUT inputs
  reg  [31:0] inst;

  // DUT outputs
  wire        is_fp, is_fp_op, is_fp_load, is_fp_store, is_fp_r4;
  wire        uses_frs1, uses_frs2, uses_frs3;
  wire        writes_frd, writes_xrd;
  wire [2:0]  rm;
  wire [1:0]  fmt;
  wire [5:0]  fp_major;
  wire [2:0]  fp_minor;
  wire        illegal_fp_fmt;
  wire        is_f32, is_f64;

  // Instantiate DUT
  fp_decode DUT (
    .inst_i(inst),
    .is_fp(is_fp),
    .is_fp_op(is_fp_op),
    .is_fp_load(is_fp_load),
    .is_fp_store(is_fp_store),
    .is_fp_r4(is_fp_r4),
    .uses_frs1(uses_frs1),
    .uses_frs2(uses_frs2),
    .uses_frs3(uses_frs3),
    .writes_frd(writes_frd),
    .writes_xrd(writes_xrd),
    .rm(rm),
    .fmt(fmt),
    .fp_major(fp_major),
    .fp_minor(fp_minor),
    .illegal_fp_fmt(illegal_fp_fmt),
    .is_f32(is_f32),
    .is_f64(is_f64)
  );

  // ----------------------------------------------------------------------------
  // Encoding helpers
  // ----------------------------------------------------------------------------
  // OP-FP format: funct5[31:27] fmt[26:25] rs2[24:20] rs1[19:15] rm/f3[14:12] rd[11:7] 0x53[6:0]
  function [31:0] enc_opfp;
    input [4:0] funct5;
    input [1:0] fmt2;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] rm3; // or funct3 within the group
    input [4:0] rd;
    begin
      enc_opfp = {funct5, fmt2, rs2, rs1, rm3, rd, 7'h53};
    end
  endfunction

  // R4 (FMADD/FMSUB/FNMADD/FNMSUB): rs3[31:27] fmt[26:25] rs2[24:20] rs1[19:15] rm[14:12] rd[11:7] opcode[6:0]
  function [31:0] enc_r4;
    input [6:0] opc;
    input [1:0] fmt2;
    input [4:0] rs3, rs2, rs1;
    input [2:0] rm3;
    input [4:0] rd;
    begin
      enc_r4 = {rs3, fmt2, rs2, rs1, rm3, rd, opc};
    end
  endfunction

  // FL* (I-type): imm[31:20] rs1[19:15] funct3[14:12] rd[11:7] 0x07[6:0]
  function [31:0] enc_fl;
    input [2:0] f3;
    input [11:0] imm12;
    input [4:0] rs1;
    input [4:0] rd;
    begin
      enc_fl = {imm12, rs1, f3, rd, 7'h07};
    end
  endfunction

  // FS* (S-type): imm[11:5][31:25] rs2[24:20] rs1[19:15] funct3[14:12] imm[4:0][11:7] 0x27[6:0]
  function [31:0] enc_fs;
    input [2:0] f3;
    input [11:0] imm12;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      enc_fs = {imm12[11:5], rs2, rs1, f3, imm12[4:0], 7'h27};
    end
  endfunction

  // Constants
  localparam [1:0] FMT_S = 2'b00;
  localparam [1:0] FMT_D = 2'b01;
  localparam [6:0] FMADD  = 7'h43;
  localparam [6:0] FMSUB  = 7'h47;
  localparam [6:0] FNMADD = 7'h4B;
  localparam [6:0] FNMSUB = 7'h4F;

  integer tests, fails;

  task check_basic;
    input [256*1-1:0] name;
    input expected_is_op, expected_is_load, expected_is_store, expected_is_r4;
    input [1:0] expected_fmt;
    input [5:0] expected_major; // set to 6'h3f to skip check
    input [2:0] expected_minor; // set to 3'h7 to skip check
    input exp_writes_xrd, exp_writes_frd;
    begin
      tests = tests + 1;
      if (expected_is_op !== 1'bx && is_fp_op !== expected_is_op) begin
        $display("[FAIL] %0s : is_fp_op=%0b exp %0b", name, is_fp_op, expected_is_op);
        fails = fails + 1;
      end
      if (expected_is_load !== 1'bx && is_fp_load !== expected_is_load) begin
        $display("[FAIL] %0s : is_fp_load=%0b exp %0b", name, is_fp_load, expected_is_load);
        fails = fails + 1;
      end
      if (expected_is_store !== 1'bx && is_fp_store !== expected_is_store) begin
        $display("[FAIL] %0s : is_fp_store=%0b exp %0b", name, is_fp_store, expected_is_store);
        fails = fails + 1;
      end
      if (expected_is_r4 !== 1'bx && is_fp_r4 !== expected_is_r4) begin
        $display("[FAIL] %0s : is_fp_r4=%0b exp %0b", name, is_fp_r4, expected_is_r4);
        fails = fails + 1;
      end
      if (fmt !== expected_fmt) begin
        $display("[FAIL] %0s : fmt=%02b exp %02b", name, fmt, expected_fmt);
        fails = fails + 1;
      end
      if (expected_major != 6'h3f && fp_major !== expected_major) begin
        $display("[FAIL] %0s : fp_major=%0d exp %0d", name, fp_major, expected_major);
        fails = fails + 1;
      end
      if (expected_minor != 3'h7 && fp_minor !== expected_minor) begin
        $display("[FAIL] %0s : fp_minor=%0d exp %0d", name, fp_minor, expected_minor);
        fails = fails + 1;
      end
      if (writes_xrd !== exp_writes_xrd || writes_frd !== exp_writes_frd) begin
        $display("[FAIL] %0s : writes_xrd=%0b (exp %0b) writes_frd=%0b (exp %0b)",
                 name, writes_xrd, exp_writes_xrd, writes_frd, exp_writes_frd);
        fails = fails + 1;
      end
      if (fails == 0) $display("[PASS] %0s", name);
    end
  endtask

  // Illegal fmt checker (H/Q): expect illegal flag set
  task check_illegal_fmt;
    input [256*1-1:0] name;
    begin
      tests = tests + 1;
      if (illegal_fp_fmt !== 1'b1) begin
        $display("[FAIL] %0s : expected illegal_fp_fmt=1, got %0b", name, illegal_fp_fmt);
        fails = fails + 1;
      end else $display("[PASS] %0s (illegal fmt)", name);
    end
  endtask

  initial begin
    tests = 0; fails = 0;
    $display("=== Running fp_decode smoke tests ===");

    // ---------------- OP-FP arithmetic ----------------
    inst = enc_opfp(5'b00000, FMT_S, 5'd2, 5'd1, 3'b000, 5'd5); #1; // FADD.S
    check_basic("fadd.s", 1, 0, 0, 0, FMT_S, 6'd0, 3'h7, /*xrd*/0, /*frd*/1);

    inst = enc_opfp(5'b00001, FMT_D, 5'd2, 5'd1, 3'b000, 5'd6); #1; // FSUB.D
    check_basic("fsub.d", 1, 0, 0, 0, FMT_D, 6'd1, 3'h7, 0, 1);

    inst = enc_opfp(5'b00010, FMT_S, 5'd2, 5'd1, 3'b000, 5'd7); #1; // FMUL.S
    check_basic("fmul.s", 1, 0, 0, 0, FMT_S, 6'd2, 3'h7, 0, 1);

    inst = enc_opfp(5'b00011, FMT_D, 5'd2, 5'd1, 3'b000, 5'd8); #1; // FDIV.D
    check_basic("fdiv.d", 1, 0, 0, 0, FMT_D, 6'd3, 3'h7, 0, 1);

    // FSQRT.S (rs2=0)
    inst = enc_opfp(5'b01011, FMT_S, 5'd0, 5'd1, 3'b000, 5'd9); #1;
    check_basic("fsqrt.s", 1, 0, 0, 0, FMT_S, 6'd6, 3'h7, 0, 1);

    // ---------------- FSGNJ* and FMIN/FMAX groups ----------------
    inst = enc_opfp(5'b00100, FMT_S, 5'd2, 5'd1, 3'b000, 5'd10); #1; // FSGNJ.S
    check_basic("fsgnj.s", 1, 0, 0, 0, FMT_S, 6'd4, 3'd0, 0, 1);

    inst = enc_opfp(5'b00100, FMT_D, 5'd2, 5'd1, 3'b010, 5'd10); #1; // FSGNJX.D
    check_basic("fsgnjx.d", 1, 0, 0, 0, FMT_D, 6'd4, 3'd2, 0, 1);

    inst = enc_opfp(5'b00101, FMT_S, 5'd2, 5'd1, 3'b000, 5'd11); #1; // FMIN.S
    check_basic("fmin.s", 1, 0, 0, 0, FMT_S, 6'd5, 3'd0, 0, 1);

    inst = enc_opfp(5'b00101, FMT_D, 5'd2, 5'd1, 3'b001, 5'd12); #1; // FMAX.D
    check_basic("fmax.d", 1, 0, 0, 0, FMT_D, 6'd5, 3'd1, 0, 1);

    // ---------------- Compares & classify ----------------
    inst = enc_opfp(5'b10100, FMT_S, 5'd2, 5'd1, 3'b010, 5'd13); #1; // FEQ.S
    check_basic("feq.s", 1, 0, 0, 0, FMT_S, 6'd7, 3'd2, 1, 0);

    inst = enc_opfp(5'b10100, FMT_D, 5'd2, 5'd1, 3'b001, 5'd14); #1; // FLT.D
    check_basic("flt.d", 1, 0, 0, 0, FMT_D, 6'd7, 3'd1, 1, 0);

    inst = enc_opfp(5'b10100, FMT_S, 5'd2, 5'd1, 3'b000, 5'd15); #1; // FLE.S
    check_basic("fle.s", 1, 0, 0, 0, FMT_S, 6'd7, 3'd0, 1, 0);

    // FCLASS.D (funct5=11100, funct3=001)
    inst = enc_opfp(5'b11100, FMT_D, 5'd0, 5'd1, 3'b001, 5'd16); #1;
    check_basic("fclass.d", 1, 0, 0, 0, FMT_D, 6'd12, 3'h7, 1, 0);

    // ---------------- Moves ----------------
    // FMV.X.W
    inst = enc_opfp(5'b11100, FMT_S, 5'd0, 5'd1, 3'b000, 5'd17); #1;
    check_basic("fmv.x.w", 1, 0, 0, 0, FMT_S, 6'd8, 3'd1, 1, 0);

    // FMV.W.X
    inst = enc_opfp(5'b11110, FMT_D, 5'd0, 5'd1, 3'b000, 5'd18); #1;
    check_basic("fmv.w.x(d)", 1, 0, 0, 0, FMT_D, 6'd8, 3'd0, 0, 1);

    // ---------------- Conversions ----------------
    // FCVT.W.S  (fp -> int)
    inst = enc_opfp(5'b11000, FMT_S, 5'd0, 5'd1, 3'b000, 5'd19); #1;
    check_basic("fcvt.w.s", 1, 0, 0, 0, FMT_S, 6'd10, 3'h7, 1, 0);

    // FCVT.WU.D (fp -> int)
    inst = enc_opfp(5'b11000, FMT_D, 5'd1, 5'd1, 3'b000, 5'd20); #1; // rs2=1 for unsigned
    check_basic("fcvt.wu.d", 1, 0, 0, 0, FMT_D, 6'd10, 3'h7, 1, 0);

    // FCVT.S.W  (int -> fp)
    inst = enc_opfp(5'b11010, FMT_S, 5'd0, 5'd1, 3'b000, 5'd21); #1;
    check_basic("fcvt.s.w", 1, 0, 0, 0, FMT_S, 6'd9, 3'h7, 0, 1);

    // FCVT.D.WU (int -> fp)
    inst = enc_opfp(5'b11010, FMT_D, 5'd1, 5'd1, 3'b000, 5'd22); #1;
    check_basic("fcvt.d.wu", 1, 0, 0, 0, FMT_D, 6'd9, 3'h7, 0, 1);

    // FCVT.S.D
    inst = enc_opfp(5'b01000, FMT_S, 5'd1, 5'd1, 3'b000, 5'd23); #1; // rs2=1 means src=D, dest=S
    check_basic("fcvt.s.d", 1, 0, 0, 0, FMT_S, 6'd11, 3'h7, 0, 1);

    // FCVT.D.S
    inst = enc_opfp(5'b01000, FMT_D, 5'd0, 5'd1, 3'b000, 5'd24); #1; // rs2=0 means src=S, dest=D
    check_basic("fcvt.d.s", 1, 0, 0, 0, FMT_D, 6'd11, 3'h7, 0, 1);

    // ---------------- Loads / Stores ----------------
    // FLW / FSW
    inst = enc_fl(3'b010, 12'h004, 5'd1, 5'd2); #1;
    check_basic("flw", 0, 1, 0, 0, FMT_S, 6'h3f, 3'h7, 0, 1);

    inst = enc_fs(3'b010, 12'h008, 5'd1, 5'd3); #1;
    check_basic("fsw", 0, 0, 1, 0, FMT_S, 6'h3f, 3'h7, 0, 0);

    // FLD / FSD
    inst = enc_fl(3'b011, 12'h00C, 5'd1, 5'd4); #1;
    check_basic("fld", 0, 1, 0, 0, FMT_D, 6'h3f, 3'h7, 0, 1);

    inst = enc_fs(3'b011, 12'h010, 5'd1, 5'd5); #1;
    check_basic("fsd", 0, 0, 1, 0, FMT_D, 6'h3f, 3'h7, 0, 0);

    // ---------------- R4 FMA ----------------
    inst = enc_r4(FMADD, FMT_S, 5'd3, 5'd2, 5'd1, 3'b000, 5'd6); #1;
    check_basic("fmadd.s", 0, 0, 0, 1, FMT_S, 6'd13, 3'h7, 0, 1);

    inst = enc_r4(FNMADD, FMT_D, 5'd3, 5'd2, 5'd1, 3'b111, 5'd7); #1;
    check_basic("fnmadd.d", 0, 0, 0, 1, FMT_D, 6'd13, 3'h7, 0, 1);

    // ---------------- Illegal fmt (H/Q) ----------------
    // Encode an OP-FP with fmt=2'b10 (H) to trigger illegal flag
    inst = enc_opfp(5'b00010, 2'b10, 5'd2, 5'd1, 3'b000, 5'd5); #1; // FMUL with fmt=H
    check_illegal_fmt("illegal_fmt_H");

    inst = enc_opfp(5'b00010, 2'b11, 5'd2, 5'd1, 3'b000, 5'd5); #1; // FMUL with fmt=Q
    check_illegal_fmt("illegal_fmt_Q");

    $display("=== DONE: %0d tests, %0d fails ===", tests, fails);
    if (fails == 0) $display("ALL TESTS PASSED");
    else $display("SOME TESTS FAILED");
    $finish;
  end

endmodule
