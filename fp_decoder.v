// RISC-V F + D decode
//
// Set of 34 fp instructions:
//1) fmadd  fd,fs1,fs2,fs3 multiply-add fd =   fs1 * fs2 + fs3  
//2) fmsub  fd,fs1,fs2,fs3 multiply-subtract fd =   fs1 * fs2 — fs3 
//3) fnmsub fd,fs1,fs2,fs3 negate multiply-add fd = —(fs1 * fs2 + fs3) 
//4) fnmadd fd,fs1,fs2,fs3 negate multiply-subtract fd = —(fs1 * fs2 – fs3) 
//5) fadd   fd,fs1,fs2 add fd =   fs1 + fs2 
//6) fsub   fd,fs1,fs2 subtract fd =   fs1 — fs2 
//7) fmul   fd,fs1,fs2 multiply fd =   fs1 * fs2 
//8) fdiv   fd,fs1,fs2 divide fd =   fs1 / fs2  
//9) fsqrt  fd,fs1 square root fd = sqrt(fs1) 
//10) fsgnj  fd,fs1,fs2 sign injection fd = fs1, sign =  sign(fs2)  
//11) fsgnjn fd,fs1,fs2 negate sign injection fd = fs1, sign = —sign(fs2) 
//12) fsgnjx fd,fs1,fs2 xor sign injection fd = fs1, sign = sign(fs2) ^ sign(fs1) 
//13) fmin   fd,fs1,fs2 min fd = min(fs1, fs2) 
//14) fmax   fd,fs1,fs2 max fd = max(fs1, fs2) 
//15) feq    rd,fs1,fs2 compare = rd = (fs1 == fs2) 
//16) flt    rd,fs1,fs2 compare < rd = (fs1 < fs2) 
//17) fle    rd,fs1,fs2 compare ≤ rd = (fs1 ≤ fs2) 
//18) fclass rd,fs1 classify rd = classification of fs1 
//19) flw       fd, imm(rs1) load float fd = [Address]31:0  
//20) fsw       fs2,imm(rs1) store float [Address]31:0 = fd 
//21) fcvt.w.s  rd, fs1 convert to integer rd = integer(fs1) 
//22) fcvt.wu.s rd, fs1 convert to unsigned integer rd = unsigned(fs1) 
//23) fcvt.s.w  fd, rs1 convert int to float fd = float(rs1)  
//24) fcvt.s.wu fd, rs1 convert unsigned to float fd = float(rs1) 
//25) fmv.x.w   rd, fs1 move to integer register rd = fs1 
//26) fmv.w.x   fd, rs1 move to f.p. register fd = rs1 
//27) fld       fd, imm(rs1) load double fd = [Address]63:0
//28)fsd       fs2,imm(rs1) store double [Address]63:0 = fd  
//29) fcvt.w.d  rd, fs1 convert to integer rd = integer(fs1) 
//30) fcvt.wu.d rd, fs1 convert to unsigned integer rd = unsigned(fs1)
//31) fcvt.d.w  fd, rs1 convert int to double fd = double(rs1) 
//32) fcvt.d.wu fd, rs1 convert unsigned to double fd = double(rs1)
//33) fcvt.s.d  fd, fs1  convert double to float fd = float(fs1) 
//34) fcvt.d.s  fd, fs1 convert float to double
//

module fp_decode (
  input  wire [31:0] inst_i,

  // Classes
  output wire        is_fp,         // any FP instruction
  output wire        is_fp_op,      // OP-FP (0x53)
  output wire        is_fp_load,    // FLW/FLD
  output wire        is_fp_store,   // FSW/FSD
  output wire        is_fp_r4,      // F{N}MADD/F{N}MSUB (uses rs3)

  // Format & RM (F/D only)
  output wire [1:0]  fmt,           // 00=S, 01=D
  output wire        is_f32,        // fmt==S
  output wire        is_f64,        // fmt==D
  output wire [2:0]  rm,            // rounding mode

  // Operand usage
  output wire        uses_frs1,
  output wire        uses_frs2,
  output wire        uses_frs3,     //only for FMA r4
  output wire        writes_frd,    // writes FP rd
  output wire        writes_xrd,    // writes integer rd

  // Operation select
  output reg  [5:0]  fp_major,      // 0:add 1:sub 2:mul 3:div 4:fsgnj 5:minmax 6:sqrt
                                    // 7:cmp 8:mv 9:cvti2f 10:cvtf2i 11:cvtfmt 12:fclass 13:fma
  output reg  [2:0]  fp_minor,      // sub-op within major (e.g., fsgnj/fsgnjn/fsgnjx; cmp: fle/flt/feq)

  // Illegal inst format
  output wire        illegal_fp_fmt
);

  // ---- fields ----
  wire [6:0] opcode = inst_i[6:0];
  wire [2:0] funct3 = inst_i[14:12];
  wire [4:0] rs2    = inst_i[24:20];
  wire [4:0] funct5 = inst_i[31:27];
  wire [1:0] fmt_opfp = inst_i[26:25]; // OP-FP / R4 fmt field per spec

  // ---- opcodes ----
  localparam [6:0] OP_FP   = 7'b1010011; // 0x53
  localparam [6:0] LOAD_FP = 7'b0000111; // 0x07
  localparam [6:0] STORE_FP= 7'b0100111; // 0x27
  localparam [6:0] FMADD   = 7'b1000011; // 0x43
  localparam [6:0] FMSUB   = 7'b1000111; // 0x47
  localparam [6:0] FNMSUB  = 7'b1001111; // 0x4F
  localparam [6:0] FNMADD  = 7'b1001011; // 0x4B

  assign is_fp_op    = (opcode == OP_FP);
  assign is_fp_load  = (opcode == LOAD_FP);
  assign is_fp_store = (opcode == STORE_FP);
  assign is_fp_r4    = (opcode == FMADD) | (opcode == FMSUB) | (opcode == FNMSUB) | (opcode == FNMADD);
  assign is_fp       = is_fp_op | is_fp_load | is_fp_store | is_fp_r4;

  // ---- rm ----
  assign rm = inst_i[14:12];

  // ---- fmt (F/D only) ----
  // For OP-FP and FMA (R4), the 2-bit fmt field is inst[26:25]: 00=S, 01=D.
  // For FL*/FS*, use funct3 to infer width.
  wire [1:0] fmt_mem = (funct3==3'b010) ? 2'b00 :   // W (single)
                       (funct3==3'b011) ? 2'b01 :   // D (double)
                                          2'b00;    // default (unused for other funct3)
  assign fmt = is_fp_op | is_fp_r4 ? fmt_opfp :
               is_fp_load | is_fp_store ? fmt_mem : 2'b00;

  assign is_f32 = (fmt == 2'b00);
  assign is_f64 = (fmt == 2'b01);
  assign illegal_fp_fmt = is_fp & ~(is_f32 | is_f64); // reject H(10)/Q(11)

  // ---- src/dst usage ----
  assign uses_frs3 = is_fp_r4;
  assign uses_frs1 = is_fp_op | is_fp_r4 | is_fp_store; // store uses FRD/FRS2 as data, rs1 is integer base addr (handled in LSU)
  assign uses_frs2 = is_fp_r4 |
                     (is_fp_op & (
                        (funct5==5'b00000) | // FADD
                        (funct5==5'b00001) | // FSUB
                        (funct5==5'b00010) | // FMUL
                        (funct5==5'b00011) | // FDIV
                        (funct5==5'b00100) | // FSGNJ*
                        (funct5==5'b00101) | // FMIN/FMAX
                        (funct5==5'b10100)   // FEQ/FLT/FLE
                     ));

  // Writes: most OP-FP write FRD; compares, classify, and FMV.X.* write XRD.
  wire is_cmp     = is_fp_op & (funct5==5'b10100); // FEQ/FLT/FLE (rd is integer)
  wire is_class   = is_fp_op & (funct5==5'b11100) & (funct3==3'b001) & (rs2==5'b00000); // FCLASS
  wire is_fmv_x_f = is_fp_op & (funct5==5'b11100) & (funct3==3'b000) & (rs2==5'b00000); // FMV.X.W/D
  wire is_fmv_f_x = is_fp_op & (funct5==5'b11110) & (funct3==3'b000) & (rs2==5'b00000); // FMV.W/D.X

  wire is_cvt_fp_to_int = is_fp_op & (funct5==5'b11000); // FCVT.W[U]/L[U].S/D (fp -> int)

  assign writes_xrd = is_cmp | is_class | is_fmv_x_f | is_cvt_fp_to_int;
  assign writes_frd = is_fp_load | is_fp_r4 |
                      (is_fp_op & ~(is_cmp | is_class | is_fmv_x_f | is_cvt_fp_to_int));

  // ---- major/minor selection ----
  always @* begin
    fp_major = 6'd0; fp_minor = 3'd0;

    if (is_fp_r4) begin
      fp_major = 6'd13; // FMA group
      // 0:FMADD 1:FMSUB 2:FNMSUB 3:FNMADD
      fp_minor = (opcode==FMADD)  ? 3'd0 :
                 (opcode==FMSUB)  ? 3'd1 :
                 (opcode==FNMSUB) ? 3'd2 : 3'd3;

    end else if (is_fp_op) begin
      case (funct5)
        5'b00000: fp_major = 6'd0;                       // FADD.S/D
        5'b00001: fp_major = 6'd1;                       // FSUB.S/D
        5'b00010: fp_major = 6'd2;                       // FMUL.S/D
        5'b00011: fp_major = 6'd3;                       // FDIV.S/D
        5'b01011: begin fp_major = 6'd6; end             // FSQRT.S/D (rs2 must be 0)
        5'b00100: begin fp_major = 6'd4; fp_minor = funct3; end // FSGNJ/FSGNJN/FSGNJX
        5'b00101: begin fp_major = 6'd5; fp_minor = (funct3==3'b000)?3'd0:3'd1; end // FMIN/FMAX
        5'b10100: begin fp_major = 6'd7; fp_minor = funct3; end   // CMP: 000=FLE,001=FLT,010=FEQ
        5'b11100: begin // FMV.X.W/D (funct3=000) or FCLASS (funct3=001)
          if (is_fmv_x_f) begin fp_major = 6'd8; fp_minor = 3'd1; end // move F->X
          else if (is_class) begin fp_major = 6'd12; end             // FCLASS
        end
        5'b11110: begin // FMV.W/D.X (funct3=000)
          if (is_fmv_f_x) begin fp_major = 6'd8; fp_minor = 3'd0; end // move X->F
        end
        5'b11010: begin fp_major = 6'd9;  end // FCVT.S/D.W[U]/L[U]  (int -> fp)
        5'b11000: begin fp_major = 6'd10; end // FCVT.W[U]/L[U].S/D  (fp -> int)
        5'b01000: begin fp_major = 6'd11; end // FCVT.S.D / FCVT.D.S (fp <-> fp), dir via rs2
        default:  begin fp_major = 6'd0; fp_minor = 3'd0; end
      endcase
    end
  end

endmodule
