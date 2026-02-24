//============================================================
// testbench.sv
// Layered Verification Environment
//============================================================


//------------------------------------------------------------
// Transaction Class
// Defines one AXI transaction
//------------------------------------------------------------
class transaction;

  rand bit op;               // 1 = write, 0 = read
  rand bit [6:0] addr;       // Address
  rand bit [31:0] wdata;     // Write data

  bit [31:0] rdata;          // Read data (captured later)

  // Address must be within memory range
  constraint addr_c { addr < 128; }

  // Bias towards more writes than reads
  constraint op_dist { op dist {1 := 60, 0 := 40}; }

endclass



//------------------------------------------------------------
// Generator
//------------------------------------------------------------
class generator;

  mailbox #(transaction) gen2drv; // Send to driver
  event next;                     // Sync with scoreboard
  int count;                      // Number of transactions

  function new(mailbox #(transaction) gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task run();
    transaction tr;

    repeat(count) begin

      tr = new();

      // Randomize transaction
      if(!tr.randomize())
        $fatal(1, "Randomization failed");

      $display("[GEN] OP=%0b ADDR=%0d DATA=%0d",
                tr.op, tr.addr, tr.wdata);

      gen2drv.put(tr);  // Send to driver

      @(next);          // Wait until scoreboard completes
    end
  endtask

endclass



//------------------------------------------------------------
// Driver
//------------------------------------------------------------
class driver;

  virtual axi_if vif;                 // Virtual interface
  mailbox #(transaction) gen2drv;     // Input from generator
  mailbox #(transaction) drv2mon;     // Send to monitor

  function new(mailbox #(transaction) gen2drv,
               mailbox #(transaction) drv2mon);
    this.gen2drv = gen2drv;
    this.drv2mon = drv2mon;
  endfunction


  //----------------------------------------------------------
  // RESET
  //----------------------------------------------------------
  task reset();

    vif.resetn <= 0;

    vif.awvalid <= 0;
    vif.wvalid  <= 0;
    vif.arvalid <= 0;
    vif.bready  <= 0;
    vif.rready  <= 0;

    repeat(5) @(posedge vif.clk);

    vif.resetn <= 1;

    $display("[DRV] RESET DONE");
  endtask


  //----------------------------------------------------------
  // WRITE TASK
  //----------------------------------------------------------
  task write(transaction tr);

    @(posedge vif.clk);

    vif.awaddr  <= tr.addr;
    vif.wdata   <= tr.wdata;
    vif.awvalid <= 1;
    vif.wvalid  <= 1;

    @(posedge vif.clk);

    vif.awvalid <= 0;
    vif.wvalid  <= 0;

    wait(vif.bvalid);

    vif.bready <= 1;
    @(posedge vif.clk);
    vif.bready <= 0;

    drv2mon.put(tr);
  endtask


  //----------------------------------------------------------
  // READ TASK
  //----------------------------------------------------------
  task read(transaction tr);

    @(posedge vif.clk);

    vif.araddr  <= tr.addr;
    vif.arvalid <= 1;

    @(posedge vif.clk);
    vif.arvalid <= 0;

    wait(vif.rvalid);

    tr.rdata = vif.rdata;

    vif.rready <= 1;
    @(posedge vif.clk);
    vif.rready <= 0;

    drv2mon.put(tr);
  endtask


  //----------------------------------------------------------
  // Driver main loop
  //----------------------------------------------------------
  task run();
    transaction tr;

    forever begin
      gen2drv.get(tr);

      if(tr.op)
        write(tr);
      else
        read(tr);
    end
  endtask

endclass



//------------------------------------------------------------
// Monitor
//------------------------------------------------------------
class monitor;

  mailbox #(transaction) drv2mon;
  mailbox #(transaction) mon2scb;

  function new(mailbox #(transaction) drv2mon,
               mailbox #(transaction) mon2scb);
    this.drv2mon = drv2mon;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction tr;

    forever begin
      drv2mon.get(tr);
      mon2scb.put(tr);
    end
  endtask

endclass



//------------------------------------------------------------
// Scoreboard
//------------------------------------------------------------
class scoreboard;

  mailbox #(transaction) mon2scb;
  event next;

  bit [31:0] ref_mem [0:127];  // Reference model

  function new(mailbox #(transaction) mon2scb);
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction tr;

    forever begin

      mon2scb.get(tr);

      if(tr.op) begin

        ref_mem[tr.addr] = tr.wdata;

        $display("[SCO] WRITE OK ADDR=%0d DATA=%0d",
                  tr.addr, tr.wdata);
      end
      else begin

        if(tr.rdata == ref_mem[tr.addr])
          $display("[SCO] READ MATCH ADDR=%0d DATA=%0d",
                    tr.addr, tr.rdata);
        else
          $display("[SCO] READ MISMATCH ADDR=%0d EXP=%0d GOT=%0d",
                    tr.addr, ref_mem[tr.addr], tr.rdata);
      end

      $display("----------------------------------");

      ->next;
    end
  endtask

endclass



//------------------------------------------------------------
// Top Testbench Module
//------------------------------------------------------------
module tb;

  axi_if vif();  // Interface instance

  mailbox #(transaction) m1 = new();
  mailbox #(transaction) m2 = new();
  mailbox #(transaction) m3 = new();

  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;

  axilite_s dut (
    vif.clk, vif.resetn,
    vif.awvalid, vif.awready, vif.awaddr,
    vif.wvalid, vif.wready, vif.wdata,
    vif.bvalid, vif.bready, vif.bresp,
    vif.arvalid, vif.arready, vif.araddr,
    vif.rvalid, vif.rready, vif.rdata, vif.rresp
  );

  initial vif.clk = 0;
  always #5 vif.clk = ~vif.clk;


  //----------------------------------------------------------
  // AXI Protocol Assertions
  //----------------------------------------------------------

  property write_resp;
    @(posedge vif.clk)
    (vif.awvalid && vif.wvalid) |=> vif.bvalid;
  endproperty
  assert property(write_resp);

  property read_resp;
    @(posedge vif.clk)
    vif.arvalid |=> vif.rvalid;
  endproperty
  assert property(read_resp);


  //----------------------------------------------------------
  // Start Simulation
  //----------------------------------------------------------
  initial begin

    gen = new(m1);
    drv = new(m1, m2);
    mon = new(m2, m3);
    sco = new(m3);

    drv.vif = vif;

    gen.count = 15;
    gen.next  = sco.next;

    drv.reset();

    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_none

    #2000;
    $finish;
  end

endmodule
