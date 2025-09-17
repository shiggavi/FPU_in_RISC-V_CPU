// ============================================================================
// Module: fp_sgnj  (Sign Inject / Sign Not / Sign XOR for F32/F64)
// ============================================================================

`timescale 1ns/1ps

module fp_sgnj (
    // Flattened fp_sgnj_in_type
    input  [63:0] fp_sgnj_i_data1,  // operand A
    input  [63:0] fp_sgnj_i_data2,  // operand B (provides sign)
    input  [1:0]  fp_sgnj_i_fmt,    // 0 = F32, 1 = F64
    input  [2:0]  fp_sgnj_i_rm,     // 0=FSGNJ, 1=FSGNJN, 2=FSGNJX

    // Flattened fp_sgnj_out_type
    output [63:0] fp_sgnj_o_result
);

  // Internal registers/wires
  reg  [63:0] data1;
  reg  [63:0] data2;
  reg  [1:0]  fmt;
  reg  [2:0]  rm;
  reg  [63:0] result;


  always @* begin
    // Read inputs into locals (purely cosmetic; can use inputs directly)
    data1 = fp_sgnj_i_data1;
    data2 = fp_sgnj_i_data2;
    fmt   = fp_sgnj_i_fmt;
    rm    = fp_sgnj_i_rm;

    result = 64'b0;

    // F32 path
    if (fmt == 2'b00) begin
      result[30:0] = data1[30:0];
      // rm: 0=copy sign, 1=copy inverted sign, 2=sign XOR
      if (rm == 3'd0) begin
        result[31] = data2[31];
      end else if (rm == 3'd1) begin
        result[31] = ~data2[31];
      end else if (rm == 3'd2) begin
        result[31] = data1[31] ^ data2[31];
      end
      // other rm values: leave sign as 0 (result default)

    // F64 path
    end else if (fmt == 2'b01) begin
      result[62:0] = data1[62:0];
      if (rm == 3'd0) begin
        result[63] = data2[63];
      end else if (rm == 3'd1) begin
        result[63] = ~data2[63];
      end else if (rm == 3'd2) begin
        result[63] = data1[63] ^ data2[63];
      end
      // other rm values: leave sign as 0 (result default)

    end
    // For other fmt values, result stays 0
  end

  // Drive outputs
  assign fp_sgnj_o_result = result;

endmodule
