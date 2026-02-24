//============================================================
// design.sv
// Simple AXI4-Lite Slave (Basic-Level Design)
//==================================================


//------------------------------------------------------------
// AXI Interface Definition
// This groups all AXI signals together neatly
//------------------------------------------------------------
interface axi_if;

  logic clk;          // Clock
  logic resetn;       // Active-low reset

  // Write Address Channel
  logic awvalid;      // Master says write address is valid
  logic awready;      // Slave says ready to accept address
  logic [6:0] awaddr; // 7-bit address (0–127)

  // Write Data Channel
  logic wvalid;       // Master says write data is valid
  logic wready;       // Slave ready to accept data
  logic [31:0] wdata; // 32-bit write data

  // Write Response Channel
  logic bvalid;       // Slave says write response is valid
  logic bready;       // Master ready to accept response
  logic [1:0] bresp;  // Write response (00 = OKAY)

  // Read Address Channel
  logic arvalid;      // Master says read address valid
  logic arready;      // Slave ready to accept read address
  logic [6:0] araddr; // 7-bit read address

  // Read Data Channel
  logic rvalid;       // Slave says read data valid
  logic rready;       // Master ready to accept read data
  logic [31:0] rdata; // 32-bit read data
  logic [1:0] rresp;  // Read response (00 = OKAY)

endinterface



//------------------------------------------------------------
// AXI-Lite Slave Design
//------------------------------------------------------------
module axilite_s(

    input  logic         s_axi_aclk,     // Clock
    input  logic         s_axi_aresetn,  // Active-low reset

    // Write Address Channel
    input  logic         s_axi_awvalid,
    output logic         s_axi_awready,
    input  logic [6:0]   s_axi_awaddr,

    // Write Data Channel
    input  logic         s_axi_wvalid,
    output logic         s_axi_wready,
    input  logic [31:0]  s_axi_wdata,

    // Write Response Channel
    output logic         s_axi_bvalid,
    input  logic         s_axi_bready,
    output logic [1:0]   s_axi_bresp,

    // Read Address Channel
    input  logic         s_axi_arvalid,
    output logic         s_axi_arready,
    input  logic [6:0]   s_axi_araddr,

    // Read Data Channel
    output logic         s_axi_rvalid,
    input  logic         s_axi_rready,
    output logic [31:0]  s_axi_rdata,
    output logic [1:0]   s_axi_rresp
);

  //----------------------------------------------------------
  // Internal Memory (128 locations of 32-bit each)
  //----------------------------------------------------------
  logic [31:0] mem [0:127];
  integer i;

  //----------------------------------------------------------
  // Sequential logic (Clocked behavior)
  //----------------------------------------------------------
  always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin

    //--------------------------------------------------------
    // RESET CONDITION
    //--------------------------------------------------------
    if(!s_axi_aresetn) begin

      // Clear handshake outputs
      s_axi_awready <= 0;
      s_axi_wready  <= 0;
      s_axi_bvalid  <= 0;
      s_axi_bresp   <= 0;

      s_axi_arready <= 0;
      s_axi_rvalid  <= 0;
      s_axi_rdata   <= 0;
      s_axi_rresp   <= 0;

      // Clear memory
      for(i=0;i<128;i++)
        mem[i] <= 0;

    end

    //--------------------------------------------------------
    // NORMAL OPERATION
    //--------------------------------------------------------
    else begin

      // This is a simple slave → always ready
      s_axi_awready <= 1;
      s_axi_wready  <= 1;
      s_axi_arready <= 1;

      //---------------- WRITE OPERATION ---------------------

      // If master sends address + data and we are not busy
      if(s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin

        mem[s_axi_awaddr] <= s_axi_wdata;  // Store data
        s_axi_bvalid <= 1;                 // Send response
        s_axi_bresp  <= 2'b00;             // OKAY response
      end

      // When master accepts response
      if(s_axi_bvalid && s_axi_bready)
        s_axi_bvalid <= 0;

      //---------------- READ OPERATION ----------------------

      if(s_axi_arvalid && !s_axi_rvalid) begin

        s_axi_rdata  <= mem[s_axi_araddr]; // Read memory
        s_axi_rvalid <= 1;                 // Send data
        s_axi_rresp  <= 2'b00;             // OKAY
      end

      // When master accepts data
      if(s_axi_rvalid && s_axi_rready)
        s_axi_rvalid <= 0;

    end
  end

endmodule
