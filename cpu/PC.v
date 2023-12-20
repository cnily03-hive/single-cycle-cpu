module PC (
    input inclk, // Clock
    input rstn,   // Reset Signal

    input      [31:0] PC_next, // Next PC address
    output reg [31:0] PC_out   // Current PC address
);

    always @(posedge inclk, negedge rstn) begin
        if (!rstn) begin
            PC_out <= 32'b0;
        end else begin
            PC_out <= PC_next;
        end
    end

endmodule
