// ucsbece154a_controller.sv
// All Rights Reserved
// Copyright (c) 2025 UCSB ECE
// Distribution Prohibited


module ucsbece154a_controller (
    input logic     [6:0] op_i, 
    input logic     [2:0] funct3_i,
    input logic           funct7b5_i,
    input logic	          Zero_i,
    output logic          RegWrite_o,
    output logic    [2:0] ImmSrc_o,
    output logic          ALUSrc_o,
    output logic    [2:0] ALUControl_o,
    output logic          MemWrite_o,
    output logic    [1:0] ResultSrc_o,
    output logic          PCSrc_o
);


 `include "ucsbece154a_defines.svh"


 logic [11:0] controls;
 logic Branch, Jump;
 logic [1:0] ALUOp;


//  TO DO: Implement main decoder 
//  • Replace all `z` values with the correct values
//  • Extend the code to implement jal and lui 


 assign {RegWrite_o,	
	ImmSrc_o, 
        ALUSrc_o, // 0 is register 1 is immediate
        MemWrite_o, // 0 to not write 1 to write
        ResultSrc_o, 
	Branch, 
	ALUOp,
	Jump} = controls;


 always_comb begin
   case (op_i)
    // implemented main decoder control signals based on the instruction type. Have a default value to prevent latch inferring
	instr_lw_op:        controls = 12'b1_000_1_0_01_0_00_0;       // reg write, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump
	instr_sw_op:        controls = 12'b0_001_1_1_xx_0_00_0;  
	instr_Rtype_op:     controls = 12'b1_xxx_0_0_00_0_10_0;   
	instr_beq_op:       controls = 12'b0_010_0_0_xx_1_01_0;   
	instr_ItypeALU_op:  controls = 12'b1_000_1_0_00_0_10_0;
    instr_jal_op:       controls = 12'b1_011_1_0_10_0_10_1;
    instr_lui_op:       controls = 12'b1_100_1_0_11_0_10_0;
	default:            controls = 12'bx_xxx_x_x_xx_0_xx_x;

     //      `ifdef SIM
     //      $warning("Unsupported op given: %h", op_i);
     //       `else
     //       ;
     //       `endif
   endcase
 end

//  TO DO: Implement ALU decoder by replacing all `z` values with the correct values

logic RtypeSub;

assign RtypeSub = funct7b5_i & op_i[5];

always_comb begin
    case(ALUOp) // implemented alu control signals based on the aluop code and funct3 code. Have a default value to prevent latch inferring
        ALUop_mem:                 ALUControl_o = ALUcontrol_add;
        ALUop_beq:                 ALUControl_o = ALUcontrol_sub;
        ALUop_other: 
            case(funct3_i)
                instr_addsub_funct3: 
                        if(RtypeSub) ALUControl_o = ALUcontrol_sub;
                        else         ALUControl_o = ALUcontrol_add;  
                instr_slt_funct3:  ALUControl_o = ALUcontrol_slt;  
                instr_or_funct3:   ALUControl_o = ALUcontrol_or;  
                instr_and_funct3:  ALUControl_o = ALUcontrol_and;  
                default:           ALUControl_o = 3'bxxx;
                //     `ifdef SIM
                //         $warning("Unsupported funct3 given: %h", funct3_i);
                //     `else
                //         ;
                //     `endif  
            endcase
        default:
        begin   
            ALUControl_o = 3'bxxx;
            `ifdef SIM
                $warning("Unsupported ALUop given: %h", ALUOp);
            `else
                ;
            `endif   
        end
    endcase
end

// TO DO: Generate properly PCSrc by replacing all `z` values with the correct values

assign PCSrc_o = (1'b0 | Jump | (Branch & Zero_i) ); 

endmodule

