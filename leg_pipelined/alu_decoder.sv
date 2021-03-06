/*
   LEG Processor for Education
   Copyright (C) 2016  Max Waugaman

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

module alu_decoder(input  logic       ALUOpE,
           input  logic [24:21] ALUControlE,
           input  logic [1:0] PreviousCVFlag,
           input  logic BXInstrE, RegtoCPSR, CoProc_MCR, multNegateRs,
           output   logic [2:0] ALUOperation, CVUpdate,
           output   logic     InvertB, ReverseInputs, ALUCarryIn, DoNotWriteReg);

 /***** Brief Description *******
 * First Created by Ivan Wong 2014-2015
 * CONTROLLER EXECUTE STAGE
 * ALU_Decoder is used to generate all necessary controls for the ALU to operate. 
 * Which flags to update are also handled by ALU_Decoder
 *
 ******************************/
  assign ReverseInputs = ALUOpE & (ALUControlE[24:21] == 4'b0011 | //RSB
                                   ALUControlE[24:21] == 4'b0111 | //RSC
                                   multNegateRs); 
 
  assign InvertB = (ALUOpE & ((ALUControlE[24:22] == 3'b001) |   //SUB, RSB
                   (ALUControlE[24:22] == 3'b011) |   //SBC, RSC
                   (ALUControlE[24:21] == 4'b1010) |  //CMP
                   (ALUControlE[24:21] == 4'b1111) |  //MVN
                   (ALUControlE[24:21] == 4'b1110)));    //BIC
                 
  always_comb
    // SD 10/5/2015: Why not simplify with don't care?
    casex ({ALUOpE, ALUControlE[24:21]}) 
      5'b10010: ALUCarryIn = 1'b1;   // SUB, RSB
      5'b10011: ALUCarryIn = 1'b1;   // SUB, RSB
      5'b10101: ALUCarryIn = PreviousCVFlag[1];   // ADC
      5'b10110: ALUCarryIn = PreviousCVFlag[1];   // SBC
      5'b10111: ALUCarryIn = PreviousCVFlag[1];   // RSC
      5'b11010: ALUCarryIn = 1'b1;   // CMP
      default:  ALUCarryIn = 1'b0;
    endcase
  
  always_comb
    casex ({ALUOpE, ALUControlE[24:21], BXInstrE}) // AND(&) = 3'b000,  XOR(^) = 3'b001, SUM = 3'b010, OR(|) = 3'b011, SINGLEInput = 3'b100
      6'b100000: ALUOperation = 3'b000; // AND
      6'b110000: ALUOperation = 3'b000; // TST
      6'b100010: ALUOperation = 3'b001; // EOR
      6'b110010: ALUOperation = 3'b001; // TEQ
      6'b100100: ALUOperation = 3'b010; // SUB
      6'b100110: ALUOperation = 3'b010; // RSB
      6'b101000: ALUOperation = 3'b010; // ADD
      6'b101010: ALUOperation = 3'b010; // ADC
      6'b101100: ALUOperation = 3'b010; // SBC
      6'b101110: ALUOperation = 3'b010; // RSC
      6'b110100: ALUOperation = 3'b010; // CMP
      6'b110110: ALUOperation = 3'b010; // CMN
      6'b111000: ALUOperation = 3'b011; // ORR
      6'b111010: ALUOperation = 3'b100; // MOV
      6'b001001: ALUOperation = 3'b101; // BX
      6'b111110: ALUOperation = 3'b100; // MVN
      6'b111100: ALUOperation = 3'b000; // BIC
      6'b0xxxx: ALUOperation = 3'b010;  // others
      default: ALUOperation = 3'b010; // Add by default
    endcase

  assign DoNotWriteReg = (ALUOpE & (ALUControlE[24:23] == 2'b10)) | RegtoCPSR | CoProc_MCR; // TST, TEQ, CMP, CMN or RegtoCPSR(MOV instr)

  always_comb
    casex ({ALUOpE, ALUControlE[24:21]}) 
      5'b10000:  CVUpdate = 3'b000; // AND
      5'b11000:  CVUpdate = 3'b000; // TST
      5'b10001:  CVUpdate = 3'b000; // EOR
      5'b11001:  CVUpdate = 3'b000; // TEQ
      5'b10010:  CVUpdate = 3'b101; // SUB
      5'b10011:  CVUpdate = 3'b101; // RSB
      5'b10100:  CVUpdate = 3'b110; // ADD - has KeepV
      5'b10101:  CVUpdate = 3'b100; // ADC
      5'b10110:  CVUpdate = 3'b101; // SBC
      5'b10111:  CVUpdate = 3'b101; // RSC
      5'b11010:  CVUpdate = 3'b101; // CMP
      5'b11011:  CVUpdate = 3'b100; // CMN
      5'b11100:  CVUpdate = 3'b000; // ORR
      5'b11101:  CVUpdate = 3'b000; // MOV
      5'b11111:  CVUpdate = 3'b000; // MVN
      5'b11110:  CVUpdate = 3'b000; // BIC
      //default: Result = 32'bx;
    endcase

endmodule 