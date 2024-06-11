
module Button(
    input  clk,
    input  in,
    output out
);

    localparam N = 64;

    wire w_debounce_out;
    reg [1:0] dff_reg, dff_next;
    reg [N-1 : 0] Q_reg, Q_next;

    //Debounce Circuit
    always @(*) begin
        //Q_next = {in,Q_reg[N-1:1]}; //Right Shift
        Q_next = {Q_reg[N-2:0],in};   //Left Shift
    end

    always @(posedge clk) begin
        Q_reg <= Q_next;
    end
    
    assign w_debounce_out = &Q_reg;    


    //D F/F Edge Detector
    always @(*) begin
        dff_next[0] = w_debounce_out;
        dff_next[1] = dff_reg[0];
    end

    always @(posedge clk) begin
        dff_reg <= dff_next;
    end

    //output Logic
    assign out = ~dff_reg[0] & dff_reg[1];

endmodule
