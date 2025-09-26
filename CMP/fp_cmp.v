`timescale 1ns/1ps

module fp_cmp (
    input  [64:0] data1_in,
    input  [64:0] data2_in,
    input  [2:0]  rm_in,
    input  signed [9:0]  class1_in,
    input  signed [9:0]  class2_in,
    output reg [63:0] result_out,
    output reg [4:0]  flags_out
);

  reg [64:0] data1, data2;
  reg [2:0] rm;
  reg [9:0] class1, class2;
  reg comp_lt, comp_le;
  reg [63:0] result;
  reg [4:0] flags;

  always @(*) begin
    data1 = data1_in;
    data2 = data2_in;
    rm = rm_in;
    class1 = class1_in;
    class2 = class2_in;

    comp_lt = 0;
    comp_le = 0;
    result = 0;
    flags = 0;

    // Precompute magnitude comparisons for same-sign numbers
    if (rm == 3'd0 || rm == 3'd1 || rm == 3'd2) begin
      comp_lt = (data1[63:0] < data2[63:0]) ? 1'b1 : 1'b0;
      comp_le = (data1[63:0] <= data2[63:0]) ? 1'b1 : 1'b0;
    end

    // -------------------------------
    // FEQ.S (rm==2) - quiet comparison
    // -------------------------------
    if (rm == 3'd2) begin
      // Invalid only for signaling NaN (sNaN = class[8])
      if (|{class1[8], class2[8]}) begin
        flags[4] = 1;
        result[0] = 0;
      end
      // ±0 check
      else if ((|{class1[3],class1[4]}) & (|{class2[3],class2[4]})) begin
        result[0] = 1;
      end
      // Normal equality
      else if (data1 == data2) begin
        result[0] = 1;
      end
      else result[0] = 0;
    end

    // -------------------------------
    // FLT.S (rm==1) - signaling comparison
    // -------------------------------
    else if (rm == 3'd1) begin
      // Any NaN triggers invalid
      if (|{class1[8],class1[9],class2[8],class2[9]}) begin
        flags[4] = 1;
        result[0] = 0;
      end
      // ±0: result=0
      else if ((|{class1[3],class1[4]}) & (|{class2[3],class2[4]})) begin
        result[0] = 0;
      end
      // Different signs: negative < positive
      else if ((data1[64] ^ data2[64]) == 1) begin
        result[0] = data1[64];
      end
      // Same sign
      else begin
        if (data1[64] == 1'b1)
          result[0] = ~comp_le;
        else
          result[0] = comp_lt;
      end
    end

    // -------------------------------
    // FLE.S (rm==0) - signaling comparison
    // -------------------------------
    else if (rm == 3'd0) begin
      // Any NaN triggers invalid
      if (|{class1[8],class1[9],class2[8],class2[9]}) begin
        flags[4] = 1;
        result[0] = 0;
      end
      // ±0: result=1
      else if ((|{class1[3],class1[4]}) & (|{class2[3],class2[4]})) begin
        result[0] = 1;
      end
      // Different signs: negative < positive
      else if ((data1[64] ^ data2[64]) == 1) begin
        result[0] = data1[64];
      end
      // Same sign
      else begin
        if (data1[64] == 1'b0)
          result[0] = comp_le;
        else
          result[0] = ~comp_lt;
      end
    end

    result_out = result;
    flags_out = flags;
  end

endmodule
