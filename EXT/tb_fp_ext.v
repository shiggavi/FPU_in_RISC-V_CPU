`timescale 1ns/1ps

module tb_fp_ext;

  // ----------------------------
  // DUT I/O
  // ----------------------------
  reg  [63:0] fp_ext_i_data;
  reg  [1:0]  fp_ext_i_fmt;
  wire [64:0] fp_ext_o_result;
  wire [9:0]  fp_ext_o_classification;
  wire [63:0] lzc_i_a;
  wire [5:0]  lzc_o_c;   // driven by TB LZC logic

  // ---------
  // LZC logic
  // ---------
  function [5:0] lzc64_count;
    input [63:0] a;
    integer i;
    reg found;
  begin
    lzc64_count = 6'd64; // default if all zeros
    found = 1'b0;
    for (i = 63; i >= 0; i = i - 1) begin
      if (!found && a[i]) begin
        lzc64_count = 6'd63 - i;
        found = 1'b1; // emulate break
      end
    end
  end
  endfunction

  // DUT expects: counter = ~lzc_o_c; so feed lzc_o_c = ~count
  assign lzc_o_c = ~lzc64_count(lzc_i_a);

  // ----------------------------
  // DUT Instantiation
  // ----------------------------
  fp_ext dut (
    .fp_ext_i_data(fp_ext_i_data),
    .fp_ext_i_fmt(fp_ext_i_fmt),
    .fp_ext_o_result(fp_ext_o_result),
    .fp_ext_o_classification(fp_ext_o_classification),
    .lzc_o_c(lzc_o_c),
    .lzc_i_a(lzc_i_a)
  );

  // ----------------------------
  // Helpers to build FP bit patterns
  // ----------------------------
  function [31:0] make_f32;
    input s;         // 1 bit
    input [7:0] e;   // 8 bits
    input [22:0] f;  // 23 bits
  begin
    make_f32 = {s, e, f};
  end
  endfunction

  function [63:0] make_f64;
    input s;          // 1 bit
    input [10:0] e;   // 11 bits
    input [51:0] f;   // 52 bits
  begin
    make_f64 = {s, e, f};
  end
  endfunction

  // ----------------------------
  // Reference model (behavioral mirror of DUT)
  // ----------------------------
  task ref_model;
    input  [63:0] data_in;
    input  [1:0]  fmt_in;
    output [64:0] exp_result;
    output [9:0]  exp_class;
    reg [63:0] data;
    reg [1:0]  fmt;
    reg [63:0] mantissa;
    reg [64:0] result;
    reg [9:0]  classification;
    reg [5:0]  counter;
    reg        mantissa_zero, exponent_zero, exponent_ones;
  begin
    data = data_in;
    fmt  = fmt_in;

    mantissa = 64'hFFFF_FFFF_FFFF_FFFF;
    result = 65'd0;
    classification = 10'd0;
    counter = 6'd0;

    mantissa_zero = 1'b0;
    exponent_zero = 1'b0;
    exponent_ones = 1'b0;

    if (fmt == 2'd0) begin
      mantissa = {1'b0, data[22:0], 40'hFF_FFFF_FFFF};
      exponent_zero = ~(|data[30:23]);
      exponent_ones =  (&data[30:23]);
      mantissa_zero = ~(|data[22:0]);
    end else begin
      mantissa = {1'b0, data[51:0], 11'h7FF};
      exponent_zero = ~(|data[62:52]);
      exponent_ones =  (&data[62:52]);
      mantissa_zero = ~(|data[51:0]);
    end

    // emulate same LZC path as DUT: counter = lzc64_count(mantissa)
    counter = lzc64_count(mantissa);

    if (fmt == 2'd0) begin
      result[64] = data[31];
      if (&data[30:23]) begin
        result[63:52] = 12'hFFF;
        result[51:29] = data[22:0];
      end else if (|data[30:23]) begin
        result[63:52] = {4'h0, data[30:23]} + 12'h780;
        result[51:29] = data[22:0];
      end else if (counter < 6'd24) begin
        result[63:52] = 12'h781 - {6'h0, counter};
        result[51:29] = (data[22:0] << counter);
      end
      result[28:0] = 29'd0;
    end else if (fmt == 2'd1) begin
      result[64] = data[63];
      if (&data[62:52]) begin
        result[63:52] = 12'hFFF;
        result[51:0]  = data[51:0];
      end else if (|data[62:52]) begin
        result[63:52] = {1'b0, data[62:52]} + 12'h400;
        result[51:0]  = data[51:0];
      end else if (counter < 6'd53) begin
        result[63:52] = 12'h401 - {6'h0, counter};
        result[51:0]  = (data[51:0] << counter);
      end
    end

    if (result[64]) begin
      if (exponent_ones) begin
        if (mantissa_zero) classification[0] = 1'b1; // -Inf
        else if (result[51] == 1'b0) classification[8] = 1'b1; // sNaN
        else classification[9] = 1'b1; // qNaN
      end else if (exponent_zero) begin
        if (mantissa_zero) classification[3] = 1'b1; // -0
        else classification[2] = 1'b1; // -subnormal
      end else begin
        classification[1] = 1'b1; // -normal
      end
    end else begin
      if (exponent_ones) begin
        if (mantissa_zero) classification[7] = 1'b1; // +Inf
        else if (result[51] == 1'b0) classification[8] = 1'b1; // sNaN
        else classification[9] = 1'b1; // qNaN
      end else if (exponent_zero) begin
        if (mantissa_zero) classification[4] = 1'b1; // +0
        else classification[5] = 1'b1; // +subnormal
      end else begin
        classification[6] = 1'b1; // +normal
      end
    end

    exp_result = result;
    exp_class  = classification;
  end
  endtask

  // ----------------------------
  // Self-check harness
  // ----------------------------
  integer total, fails;

  task run_case;
    input [1:0]   fmt;
    input [63:0]  data64;
    input [1023:0] name;
    reg   [64:0]  exp_res;
    reg   [9:0]   exp_cls;
  begin
    fp_ext_i_fmt  = fmt;
    fp_ext_i_data = data64;
    #1; // settle combinational logic (incl. LZC function)

    ref_model(data64, fmt, exp_res, exp_cls);

    total = total + 1;
    if (fp_ext_o_result !== exp_res || fp_ext_o_classification !== exp_cls) begin
      $display("FAIL: %0s", name);
      $display("  fmt=%0d data=0x%016h", fmt, data64);
      $display("  got  result=0x%016h  class=%b",
               fp_ext_o_result, fp_ext_o_classification);
      $display("  exp  result=0x%016h  class=%b",
               exp_res,         exp_cls);
      fails = fails + 1;
    end else begin
      $display("PASS: %0s", name);
    end
  end
  endtask

  // ----------------------------
  // Stimulus
  // ----------------------------
  initial begin
    $display("tb_fp_ext: starting…");
    total = 0; fails = 0;

    // -------- F32 (fmt=0) --------
    run_case(2'd0, {32'd0, make_f32(1'b0, 8'h00, 23'h000000)}, "F32 +0");
    run_case(2'd0, {32'd0, make_f32(1'b1, 8'h00, 23'h000000)}, "F32 -0");
    run_case(2'd0, {32'd0, make_f32(1'b0, 8'hFF, 23'h000000)}, "F32 +Inf");
    run_case(2'd0, {32'd0, make_f32(1'b1, 8'hFF, 23'h000000)}, "F32 -Inf");
    run_case(2'd0, {32'd0, make_f32(1'b0, 8'hFF, 23'h400000)}, "F32 qNaN");
    run_case(2'd0, {32'd0, make_f32(1'b0, 8'hFF, 23'h000001)}, "F32 sNaN");

    // F32 subnormals
    run_case(2'd0, {32'd0, make_f32(1'b0, 8'h00, 23'h000001)}, "F32 +subnormal min");
    run_case(2'd0, {32'd0, make_f32(1'b1, 8'h00, 23'h004000)}, "F32 -subnormal mid");

    // F32 normals
    run_case(2'd0, {32'd0, make_f32(1'b0, 8'h01, 23'h000000)}, "F32 +smallest normal");
    run_case(2'd0, {32'd0, make_f32(1'b1, 8'h64, 23'h123456)}, "F32 -normal random");
    run_case(2'd0, {32'd0, make_f32(1'b0, 8'hFE, 23'h7FFFFF)}, "F32 +max finite");

    // -------- F64 (fmt=1) --------
    run_case(2'd1, make_f64(1'b0, 11'h000, 52'h0000000000000), "F64 +0");
    run_case(2'd1, make_f64(1'b1, 11'h000, 52'h0000000000000), "F64 -0");
    run_case(2'd1, make_f64(1'b0, 11'h7FF, 52'h0000000000000), "F64 +Inf");
    run_case(2'd1, make_f64(1'b1, 11'h7FF, 52'h0000000000000), "F64 -Inf");
    run_case(2'd1, make_f64(1'b0, 11'h7FF, 52'h8000000000000), "F64 qNaN");
    run_case(2'd1, make_f64(1'b0, 11'h7FF, 52'h0000000000001), "F64 sNaN");

    // F64 subnormals
    run_case(2'd1, make_f64(1'b0, 11'h000, 52'h0000000000001), "F64 +subnormal min");
    run_case(2'd1, make_f64(1'b1, 11'h000, 52'h0008000000000), "F64 -subnormal mid");

    // F64 normals
    run_case(2'd1, make_f64(1'b0, 11'h001, 52'h0000000000000), "F64 +smallest normal");
    run_case(2'd1, make_f64(1'b1, 11'h3FF, 52'h123456789ABCD), "F64 -normal random");
    run_case(2'd1, make_f64(1'b0, 11'h7FE, 52'hFFFFFFFFFFFFF), "F64 +max finite");

    // Summary
    $display("--------------------------------------------------");
    if (fails == 0) $display("ALL TESTS PASSED (%0d cases).", total);
    else            $display("TESTS FAILED: %0d of %0d cases failed.", fails, total);
    $finish;
  end

endmodule