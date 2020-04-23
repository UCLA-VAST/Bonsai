// Pre-sorter sort each 512-bit axi transfer data into 16 sorted elements
// before distributing them into FIFOs
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// CAS_PRESORT will ensure out_data_1 >= out_data_0
////////////////////////////////////////////////////////////////////////////////
module CAS_PRESORT #
(
    parameter integer  DATA_WIDTH = 32
)
(
    input   wire                            aclk,  
    input   wire    [DATA_WIDTH-1:0]        in_data_0,
    input   wire    [DATA_WIDTH-1:0]        in_data_1,
    output  wire    [DATA_WIDTH-1:0]        out_data_0,
    output  wire    [DATA_WIDTH-1:0]        out_data_1
);

    reg [DATA_WIDTH-1:0]    out_data_reg_0 = {DATA_WIDTH{1'b0}};
    reg [DATA_WIDTH-1:0]    out_data_reg_1 = {DATA_WIDTH{1'b0}};

    always @(posedge aclk) begin
        if (in_data_0[DATA_WIDTH-1:0] > in_data_1[DATA_WIDTH-1:0]) begin
            /* switch */
            out_data_reg_0 <= in_data_1;
            out_data_reg_1 <= in_data_0;
        end
        else begin
            /* stay */
            out_data_reg_0 <= in_data_0;
            out_data_reg_1 <= in_data_1;
        end
    end

    assign out_data_0 = out_data_reg_0;
    assign out_data_1 = out_data_reg_1;

endmodule


module presorter #(
    parameter integer  DATA_WIDTH = 32
)
(
    input   wire                            aclk,  
    input   wire    [16*DATA_WIDTH-1:0]     in_data,
    output  wire    [16*DATA_WIDTH-1:0]     out_data
);

    wire    [16*DATA_WIDTH-1:0]             inter_data_1;
    wire    [16*DATA_WIDTH-1:0]             inter_data_2;
    wire    [16*DATA_WIDTH-1:0]             inter_data_3;
    wire    [16*DATA_WIDTH-1:0]             inter_data_4;
    wire    [16*DATA_WIDTH-1:0]             inter_data_5;
    wire    [16*DATA_WIDTH-1:0]             inter_data_6;
    wire    [16*DATA_WIDTH-1:0]             inter_data_7;
    wire    [16*DATA_WIDTH-1:0]             inter_data_8;
    wire    [16*DATA_WIDTH-1:0]             inter_data_9;

    genvar i, j;

    /* step 1 */
    generate
        for (i=0; i<16; i=i+4) begin: GEN_CAS_PRESORT_1_0
            CAS_PRESORT #(
                .DATA_WIDTH(DATA_WIDTH)
            )
            CAS_PRESORT_INST(
                .aclk(aclk),  
                .in_data_0(in_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .in_data_1(in_data[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH]),
                .out_data_0(inter_data_1[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .out_data_1(inter_data_1[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH])
            );
        end
    endgenerate

    generate
        for (i=2; i<16; i=i+4) begin: GEN_CAS_PRESORT_1_1
            CAS_PRESORT #(
                .DATA_WIDTH(DATA_WIDTH)
            )
            CAS_PRESORT_INST(
                .aclk(aclk),  
                .in_data_0(in_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .in_data_1(in_data[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH]),
                .out_data_0(inter_data_1[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH]),
                .out_data_1(inter_data_1[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH])
            );
        end
    endgenerate

    /* step 2 */
    generate
        for (i=0; i<16; i=i+8) begin: GEN_CAS_PRESORT_2_0
            for (j=0; j<2; j=j+1) begin
                CAS_PRESORT #(
                    .DATA_WIDTH(DATA_WIDTH)
                )
                CAS_PRESORT_INST(
                    .aclk(aclk),  
                    .in_data_0(inter_data_1[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .in_data_1(inter_data_1[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH]),
                    .out_data_0(inter_data_2[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .out_data_1(inter_data_2[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH])
                );   
            end
        end
    endgenerate

    generate
        for (i=4; i<16; i=i+8) begin: GEN_CAS_PRESORT_2_1
            for (j=0; j<2; j=j+1) begin
                CAS_PRESORT #(
                    .DATA_WIDTH(DATA_WIDTH)
                )
                CAS_PRESORT_INST(
                    .aclk(aclk),  
                    .in_data_0(inter_data_1[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .in_data_1(inter_data_1[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH]),
                    .out_data_0(inter_data_2[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH]),
                    .out_data_1(inter_data_2[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH])
                );  
            end
        end 
    endgenerate

    /* step 3 */
    generate
        for (i=0; i<16; i=i+8) begin: GEN_CAS_PRESORT_3_0
            for (j=0; j<4; j=j+2) begin
                CAS_PRESORT #(
                    .DATA_WIDTH(DATA_WIDTH)
                )
                CAS_PRESORT_INST(
                    .aclk(aclk),  
                    .in_data_0(inter_data_2[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .in_data_1(inter_data_2[(i+j+2)*DATA_WIDTH-1:(i+j+1)*DATA_WIDTH]),
                    .out_data_0(inter_data_3[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .out_data_1(inter_data_3[(i+j+2)*DATA_WIDTH-1:(i+j+1)*DATA_WIDTH])
                );   
            end
        end
    endgenerate

    generate
        for (i=4; i<16; i=i+8) begin: GEN_CAS_PRESORT_3_1
            for (j=0; j<4; j=j+2) begin
                CAS_PRESORT #(
                    .DATA_WIDTH(DATA_WIDTH)
                )
                CAS_PRESORT_INST(
                    .aclk(aclk),  
                    .in_data_0(inter_data_2[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .in_data_1(inter_data_2[(i+j+2)*DATA_WIDTH-1:(i+j+1)*DATA_WIDTH]),
                    .out_data_0(inter_data_3[(i+j+2)*DATA_WIDTH-1:(i+j+1)*DATA_WIDTH]),
                    .out_data_1(inter_data_3[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH])
                );   
            end
        end
    endgenerate

    /* step 4 */
    generate
        for (i=0; i<4; i=i+1) begin: GEN_CAS_PRESORT_4_0
            CAS_PRESORT #(
                .DATA_WIDTH(DATA_WIDTH)
            )
            CAS_PRESORT_INST(
                .aclk(aclk),  
                .in_data_0(inter_data_3[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .in_data_1(inter_data_3[(i+5)*DATA_WIDTH-1:(i+4)*DATA_WIDTH]),
                .out_data_0(inter_data_4[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .out_data_1(inter_data_4[(i+5)*DATA_WIDTH-1:(i+4)*DATA_WIDTH])
            ); 
        end  
    endgenerate

    generate
        for (i=8; i<12; i=i+1) begin: GEN_CAS_PRESORT_4_1
            CAS_PRESORT #(
                .DATA_WIDTH(DATA_WIDTH)
            )
            CAS_PRESORT_INST(
                .aclk(aclk),  
                .in_data_0(inter_data_3[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .in_data_1(inter_data_3[(i+5)*DATA_WIDTH-1:(i+4)*DATA_WIDTH]),
                .out_data_0(inter_data_4[(i+5)*DATA_WIDTH-1:(i+4)*DATA_WIDTH]),
                .out_data_1(inter_data_4[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH])
            ); 
        end  
    endgenerate
    
    /* step 5 */
    generate
        for (i=0; i<8; i=i+4) begin: GEN_CAS_PRESORT_5_0
            for (j=0; j<2; j=j+1) begin
                CAS_PRESORT #(
                    .DATA_WIDTH(DATA_WIDTH)
                )
                CAS_PRESORT_INST(
                    .aclk(aclk),  
                    .in_data_0(inter_data_4[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .in_data_1(inter_data_4[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH]),
                    .out_data_0(inter_data_5[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .out_data_1(inter_data_5[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH])
                );   
            end
        end
    endgenerate    

    generate
        for (i=8; i<16; i=i+4) begin: GEN_CAS_PRESORT_5_1
            for (j=0; j<2; j=j+1) begin
                CAS_PRESORT #(
                    .DATA_WIDTH(DATA_WIDTH)
                )
                CAS_PRESORT_INST(
                    .aclk(aclk),  
                    .in_data_0(inter_data_4[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .in_data_1(inter_data_4[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH]),
                    .out_data_0(inter_data_5[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH]),
                    .out_data_1(inter_data_5[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH])
                );   
            end
        end
    endgenerate  

    /* step 6 */
    generate
        for (i=0; i<8; i=i+2) begin: GEN_CAS_PRESORT_6_0
            CAS_PRESORT #(
                .DATA_WIDTH(DATA_WIDTH)
            )
            CAS_PRESORT_INST(
                .aclk(aclk),  
                .in_data_0(inter_data_5[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .in_data_1(inter_data_5[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH]),
                .out_data_0(inter_data_6[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .out_data_1(inter_data_6[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH])
            );   
        end
    endgenerate     

    generate
        for (i=8; i<16; i=i+2) begin: GEN_CAS_PRESORT_6_1
            CAS_PRESORT #(
                .DATA_WIDTH(DATA_WIDTH)
            )
            CAS_PRESORT_INST(
                .aclk(aclk),  
                .in_data_0(inter_data_5[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .in_data_1(inter_data_5[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH]),
                .out_data_0(inter_data_6[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH]),
                .out_data_1(inter_data_6[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH])
            );   
        end
    endgenerate

    /* step 7 */   
    generate
        for (i=0; i<8; i=i+1) begin: GEN_CAS_PRESORT_7
            CAS_PRESORT #(
                .DATA_WIDTH(DATA_WIDTH)
            )
            CAS_PRESORT_INST(
                .aclk(aclk),  
                .in_data_0(inter_data_6[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .in_data_1(inter_data_6[(i+9)*DATA_WIDTH-1:(i+8)*DATA_WIDTH]),
                .out_data_0(inter_data_7[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .out_data_1(inter_data_7[(i+9)*DATA_WIDTH-1:(i+8)*DATA_WIDTH])
            );   
        end
    endgenerate

    /* step 8 */
    generate
        for (i=0; i<16; i=i+8) begin: GEN_CAS_PRESORT_8
            for (j=0; j<4; j=j+1) begin
                CAS_PRESORT #(
                    .DATA_WIDTH(DATA_WIDTH)
                )
                CAS_PRESORT_INST(
                    .aclk(aclk),  
                    .in_data_0(inter_data_7[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .in_data_1(inter_data_7[(i+j+5)*DATA_WIDTH-1:(i+j+4)*DATA_WIDTH]),
                    .out_data_0(inter_data_8[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .out_data_1(inter_data_8[(i+j+5)*DATA_WIDTH-1:(i+j+4)*DATA_WIDTH])
                );   
            end
        end
    endgenerate 

    /* step 9 */
    generate
        for (i=0; i<16; i=i+4) begin: GEN_CAS_PRESORT_9
            for (j=0; j<2; j=j+1) begin
                CAS_PRESORT #(
                    .DATA_WIDTH(DATA_WIDTH)
                )
                CAS_PRESORT_INST(
                    .aclk(aclk),  
                    .in_data_0(inter_data_8[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .in_data_1(inter_data_8[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH]),
                    .out_data_0(inter_data_9[(i+j+1)*DATA_WIDTH-1:(i+j)*DATA_WIDTH]),
                    .out_data_1(inter_data_9[(i+j+3)*DATA_WIDTH-1:(i+j+2)*DATA_WIDTH])
                );   
            end
        end
    endgenerate 

    /* step 10 */
    generate
        for (i=0; i<16; i=i+2) begin: GEN_CAS_PRESORT_10
            CAS_PRESORT #(
                .DATA_WIDTH(DATA_WIDTH)
            )
            CAS_PRESORT_INST(
                .aclk(aclk),  
                .in_data_0(inter_data_9[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .in_data_1(inter_data_9[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH]),
                .out_data_0(out_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .out_data_1(out_data[(i+2)*DATA_WIDTH-1:(i+1)*DATA_WIDTH])
            );   
        end
    endgenerate 

endmodule