// This module converts the logic from the 4 CAM modules destination ports and connects them in such a way that the arbiter can simply understand given the architecture I already made for it

`default_nettype none

module PA(
    // --- Inputs from Ingress (RX Ports 0 to 3) ---
    // 9-bit data from FIFOs (8 bits payload + 1 bit EOF)
    input wire [8:0] rx_data_0, 
    input wire [8:0] rx_data_1,
    input wire [8:0] rx_data_2,
    input wire [8:0] rx_data_3,
    
    // 4-bit one-hot routing requests from CAMs
    input wire [3:0] cam_dest_0, 
    input wire [3:0] cam_dest_1,
    input wire [3:0] cam_dest_2,
    input wire [3:0] cam_dest_3,

    // --- Inputs from Egress (TX Ports A to D) ---
    // 4-bit grant vectors from Arbiters (bit 0 = RX0 granted, bit 1 = RX1 granted, etc.)
    // Note: I will need to add this output to the Arbiter.v module
    input wire [3:0] arbiter_grant_A,
    input wire [3:0] arbiter_grant_B,
    input wire [3:0] arbiter_grant_C,
    input wire [3:0] arbiter_grant_D,

    // --- Outputs to Egress (TX Ports A to D) ---
    // Master 36-bit data bus (4 ports * 9 bits) going to all Arbiters
    output wire [35:0] tx_data_bus,
    
    // 4-bit valid_input arrays telling each Arbiter which RX ports are requesting it
    output wire [3:0] valid_input_A,
    output wire [3:0] valid_input_B,
    output wire [3:0] valid_input_C,
    output wire [3:0] valid_input_D,

    // --- Outputs to Ingress (RX Ports 0 to 3) ---
    // allow_output signals to tell the FIFOs they are cleared to stream data
    output wire allow_output_0,
    output wire allow_output_1,
    output wire allow_output_2,
    output wire allow_output_3
);

    // 1. THE DATA HIGHWAY (Concatenation)
    // Bundle all 9-bit FIFO outputs into one massive 36-bit bus.
    // Every Arbiter gets this exact same bus and will slice the 9 bits it needs based on its state.
    assign tx_data_bus = {rx_data_3, rx_data_2, rx_data_1, rx_data_0};

    // 2. THE FORWARD PATH (Request Demultiplexing)
    // Translate the CAM's one-hot destination into the Arbiter's valid_input format.
    // Arbiter A looks at index 0 of the CAMs.
    assign valid_input_A[0] = cam_dest_0[0]; // RX0 requesting TX Port A
    assign valid_input_A[1] = cam_dest_1[0]; // RX1 requesting TX Port A
    assign valid_input_A[2] = cam_dest_2[0]; // RX2 requesting TX Port A
    assign valid_input_A[3] = cam_dest_3[0]; // RX3 requesting TX Port A

    // Arbiter B looks at index 1 of the CAMs.
    assign valid_input_B[0] = cam_dest_0[1]; // RX0 requesting TX Port B
    assign valid_input_B[1] = cam_dest_1[1]; // RX1 requesting TX Port B
    assign valid_input_B[2] = cam_dest_2[1]; // RX2 requesting TX Port B
    assign valid_input_B[3] = cam_dest_3[1]; // RX3 requesting TX Port B

    // Arbiter C looks at index 2 of the CAMs.
    assign valid_input_C[0] = cam_dest_0[2]; // RX0 requesting TX Port C
    assign valid_input_C[1] = cam_dest_1[2]; // RX1 requesting TX Port C
    assign valid_input_C[2] = cam_dest_2[2]; // RX2 requesting TX Port C
    assign valid_input_C[3] = cam_dest_3[2]; // RX3 requesting TX Port C

    // Arbiter D looks at index 3 of the CAMs.
    assign valid_input_D[0] = cam_dest_0[3]; // RX0 requesting TX Port D
    assign valid_input_D[1] = cam_dest_1[3]; // RX1 requesting TX Port D
    assign valid_input_D[2] = cam_dest_2[3]; // RX2 requesting TX Port D
    assign valid_input_D[3] = cam_dest_3[3]; // RX3 requesting TX Port D

    // 3. THE REVERSE PATH (Grant Multiplexing)
    // A FIFO is only allowed to output data if ANY of the 4 Arbiters have granted it access.
    // We use a bitwise OR to combine the specific RX index from all four Arbiter grant vectors.
    assign allow_output_0 = arbiter_grant_A[0] | arbiter_grant_B[0] | arbiter_grant_C[0] | arbiter_grant_D[0];
    assign allow_output_1 = arbiter_grant_A[1] | arbiter_grant_B[1] | arbiter_grant_C[1] | arbiter_grant_D[1];
    assign allow_output_2 = arbiter_grant_A[2] | arbiter_grant_B[2] | arbiter_grant_C[2] | arbiter_grant_D[2];
    assign allow_output_3 = arbiter_grant_A[3] | arbiter_grant_B[3] | arbiter_grant_C[3] | arbiter_grant_D[3];

endmodule