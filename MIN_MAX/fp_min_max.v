`timescale 1ns / 1ps

// Floating-Point Min/Max Unit
// This module computes either FMIN or FMAX between two FP operands
// depending on the rounding mode (rm). It handles NaN propagation
// and invalid operation flags per IEEE-754.
module fp_max (

    // Input operands and classification
    input [63:0] fp_max_in_data1,     // Floating-point operand 1
    input [63:0] fp_max_in_data2,     // Floating-point operand 2
    input [64:0] fp_max_in_ext1,      // Extended operand 1 (includes sign + magnitude for comparison)
    input [64:0] fp_max_in_ext2,      // Extended operand 2 (includes sign + magnitude for comparison)
    input [1:0]  fp_max_in_fmt,       // Format: 0 = single precision, else double precision
    input [2:0]  fp_max_in_rm,        // Operation selector: rm==0 → FMIN, rm==1 → FMAX
    input [9:0]  fp_max_in_class1,    // Classification bits for operand 1 (NaN, Inf, Zero, etc.)
    input [9:0]  fp_max_in_class2,    // Classification bits for operand 2

    // Outputs
    output reg [63:0] fp_max_out_result_out, // Result of FMIN/FMAX
    output reg [4:0]  fp_max_out_flags_out   // IEEE flags (only invalid-op is used here: flags[4])
);

  // Internal signals
  reg [63:0] data1, data2;      // Input operands
  reg [64:0] extend1, extend2;  // Extended compare versions
  reg [1:0]  fmt;               // Format
  reg [2:0]  rm;                // Operation selector
  reg [9:0]  class1, class2;    // Classification values

  reg [63:0] nan;               // Quiet NaN value (per format)
  reg comp;                     // Comparison flag: 1 if data1 > data2 (by magnitude)

  reg [63:0] result;            // Final result
  reg [4:0]  flags;             // Exception flags

  // Always-combinational logic block
  always @(*) begin
    // Assign inputs to local signals
    data1   = fp_max_in_data1;
    data2   = fp_max_in_data2;
    extend1 = fp_max_in_ext1;
    extend2 = fp_max_in_ext2;
    fmt     = fp_max_in_fmt;
    rm      = fp_max_in_rm;
    class1  = fp_max_in_class1;
    class2  = fp_max_in_class2;

    // Default values
    nan    = 64'h7ff8000000000000;  // Default quiet NaN (double precision)
    comp   = 0;
    result = 0;
    flags  = 0;

    // Use 32-bit quiet NaN constant if format is single precision
    if (fmt == 0) begin
      nan = 64'h000000007fc00000;
    end

    // Compare magnitudes (ignoring sign bit in [64])
    if (extend1[63:0] > extend2[63:0]) begin
      comp = 1;
    end

    // ------------------------------------------------------------------
    // Main operation logic
    // rm==0 → Perform FMIN
    // rm==1 → Perform FMAX
    // ------------------------------------------------------------------
    if (rm == 0) begin : FMIN_CASE
      // ---- Handle signaling NaN cases ----
      if ((class1[8] & class2[8]) == 1) begin
        result   = nan;     // Both are sNaN → return NaN
        flags[4] = 1;       // Raise invalid flag
      end else if (class1[8] == 1) begin
        result   = data2;   // Operand1 is sNaN → return operand2
        flags[4] = 1;
      end else if (class2[8] == 1) begin
        result   = data1;   // Operand2 is sNaN → return operand1
        flags[4] = 1;

      // ---- Handle quiet NaN cases ----
      end else if ((class1[9] & class2[9]) == 1) begin
        result = nan;       // Both are qNaN → return quiet NaN
      end else if (class1[9] == 1) begin
        result = data2;     // Operand1 is qNaN → return operand2
      end else if (class2[9] == 1) begin
        result = data1;     // Operand2 is qNaN → return operand1

      // ---- Handle normal numbers ----
      end else if ((extend1[64] ^ extend2[64]) == 1) begin
        // Signs differ: pick negative number for FMIN
        if (extend1[64] == 1) result = data1;
        else                  result = data2;
      end else begin
        // Same sign: compare magnitudes
        if (extend1[64] == 1) begin
          // Both negative → pick larger magnitude
          if (comp == 1) result = data1;
          else           result = data2;
        end else begin
          // Both positive → pick smaller magnitude
          if (comp == 0) result = data1;
          else           result = data2;
        end
      end

    end else if (rm == 1) begin : FMAX_CASE
      // ---- Handle signaling NaN cases ----
      if ((class1[8] & class2[8]) == 1) begin
        result   = nan;     // Both sNaN → return NaN
        flags[4] = 1;
      end else if (class1[8] == 1) begin
        result   = data2;   // Operand1 sNaN → return operand2
        flags[4] = 1;
      end else if (class2[8] == 1) begin
        result   = data1;   // Operand2 sNaN → return operand1
        flags[4] = 1;

      // ---- Handle quiet NaN cases ----
      end else if ((class1[9] & class2[9]) == 1) begin
        result = nan;       // Both qNaN → return quiet NaN
      end else if (class1[9] == 1) begin
        result = data2;     // Operand1 qNaN → return operand2
      end else if (class2[9] == 1) begin
        result = data1;     // Operand2 qNaN → return operand1

      // ---- Handle normal numbers ----
      end else if ((extend1[64] ^ extend2[64]) == 1) begin
        // Signs differ: pick positive number for FMAX
        if (extend1[64] == 1) result = data2;
        else                  result = data1;
      end else begin
        // Same sign: compare magnitudes
        if (extend1[64] == 1) begin
          // Both negative → pick smaller magnitude (less negative)
          if (comp == 1) result = data2;
          else           result = data1;
        end else begin
          // Both positive → pick larger magnitude
          if (comp == 0) result = data2;
          else           result = data1;
        end
      end
    end

    // Assign outputs
    fp_max_out_result_out = result;
    fp_max_out_flags_out  = flags;
  end

endmodule
