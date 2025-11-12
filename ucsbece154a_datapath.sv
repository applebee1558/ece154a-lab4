// ucsbece154a_datapath.sv
// All Rights Reserved
// Copyright (c) 2025 UCSB ECE
// Distribution Prohibited


module ucsbece154a_datapath (
    input  logic        clk, reset_i,
    input  logic        PCSrc_i,
    output logic [31:0] PC_o,
    input  logic [31:0] Instr_i,
    input  logic        RegWrite_i,
    input  logic  [2:0] ImmSrc_i,
    input  logic        ALUSrc_i,
    input  logic  [2:0] ALUControl_i,
    output logic        Zero_o,
    output logic [31:0] ALUResult_o, WriteData_o,
    input  logic [31:0] ReadData_i,
    input  logic  [1:0] ResultSrc_i
);

logic [31:0] ImmExt;
logic [31:0] ALUSrc_B;
logic [31:0] RD1;
logic [31:0] RD2;
logic [31:0] Register_In;
logic [31:0] PC_next;

`include "ucsbece154a_defines.svh"

/// Your code here

// Use name "rf" for a register file module so testbench file work properly (or modify testbench file) 
ucsbece154a_rf rf(
    .clk        (clk),
    .a1_i       (Instr_i[19:15]),
    .a2_i       (Instr_i[24:20]),
    .a3_i       (Instr_i[11:7]),
    .rd1_o      (RD1),
    .rd2_o      (RD2),
    .wd3_i      (Register_In),
    .we3_i      (RegWrite_i)
);

ucsbece154a_alu alu(
    .a          (RD1),
    .b          (ALUSrc_B),
    .f          (ALUControl_i),
    .result     (ALUResult_o),
    .zero       (Zero_o)
);
/*
module ucsbece154a_alu(
  input  logic [31:0] a,
  input  logic [31:0] b,
  input  logic [2:0]  f,
  output logic [31:0] result,
  output logic        zero,
  output logic        overflow,
  output logic        carry,
  output logic        negative
);
*/

assign WriteData_o = RD2; // write data out is rd2

always_comb begin // extend unit
    case (ImmSrc_i) 
        imm_Itype: ImmExt = {{20{Instr_i[31]}}, Instr_i[31:20]};
        imm_Stype: ImmExt = {{20{Instr_i[31]}}, Instr_i[31:25], Instr_i[11:7]};
        imm_Btype: ImmExt = {{19{Instr_i[31]}}, Instr_i[31], Instr_i[7], Instr_i[30:25], Instr_i[11:8], 1'b0};
        imm_Jtype: ImmExt = {{12{Instr_i[31]}}, Instr_i[19:12], Instr_i[20], Instr_i[30:21], 1'b0};
        imm_Utype: ImmExt = {Instr_i[31:12], {12{1'b0}}}; // not sure if right
    endcase
end

always_comb begin // alu src mux
    case (ALUSrc_i)
        ALUSrc_reg: ALUSrc_B = RD2;
        ALUSrc_imm: ALUSrc_B = ImmExt;
    endcase
end


always_comb begin // result src mux
    case (ResultSrc_i)
        ResultSrc_lui: Register_In = ImmExt;
        ResultSrc_ALU: Register_In = ALUResult_o;
        ResultSrc_jal: Register_In = PC_o + 4;
        ResultSrc_load: Register_In = ReadData_i;
    endcase
end

always_comb begin // pcnext mux
    case (PCSrc_i)
        1'b0: PC_next = PC_o + 4;
        1'b1: begin
            PC_next = PC_o + ImmExt;
        end
    endcase
end

always_ff @(negedge clk) begin
    PC_o <= PC_next;
end

always_ff @(negedge reset_i) begin
    if(!reset_i) begin
        PC_o <= 32'b0;
    end
end
endmodule
