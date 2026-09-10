module ysyx_25080209_LSU #(ADDR_WID = 32, DATA_WID = 32)(
  input clk, rst,

  // 来自 IDU 的控制信号
  input               IDU_mem_ren,
  input               IDU_mem_wen,
  input [3:0]         IDU_mem_wmask,
  input [2:0]         IDU_mem_rmask,

  // 来自 EXU 的地址和数据
  input [ADDR_WID-1:0] EXU_raddr,
  input [ADDR_WID-1:0] EXU_waddr,
  input [DATA_WID-1:0] EXU_wdata,
  input [ADDR_WID-1:0] EXU_npc,

  // 来自 EXU 的透传控制
  input   EXU_reg_wen,
  input   EXU_csr_wen,
  input   EXU_csr_ren,

  // 握手信号
  input EXU_valid,
  input WBU_ready,

  // 输出
  output reg [ADDR_WID-1:0] LSU_npc,
  output reg [DATA_WID-1:0] LSU_rdata,
  output LSU_reg_wen,
  output LSU_csr_wen,
  output LSU_csr_ren,
  output reg LSU_ready,
  output reg LSU_valid,

  // ========== AXI4 接口（未修改） ==========
  input 		io_master_awready,
  output 		io_master_awvalid,
  output 	[31:0] 	io_master_awaddr,
  output 	[3:0] 	io_master_awid,
  output 	[7:0] 	io_master_awlen,
  output 	[2:0] 	io_master_awsize,
  output 	[1:0] 	io_master_awburst,
  input 		io_master_wready,
  output 		io_master_wvalid,
  output 	[31:0] 	io_master_wdata,
  output 	[3:0] 	io_master_wstrb,
  output 		io_master_wlast,
  output 		io_master_bready,
  input 		io_master_bvalid,
  input 	[1:0] 	io_master_bresp,
  input 	[3:0] 	io_master_bid,
  input 		io_master_arready,
  output 		io_master_arvalid,
  output 	[31:0] 	io_master_araddr,
  output 	[3:0] 	io_master_arid,
  output 	[7:0] 	io_master_arlen,
  output 	[2:0] 	io_master_arsize,
  output 	[1:0] 	io_master_arburst,
  output 		io_master_rready,
  input 		io_master_rvalid,
  input 	[1:0] 	io_master_rresp,
  input 	[31:0] 	io_master_rdata,
  input 		io_master_rlast,
  input 	[3:0] 	io_master_rid
);

  // ========== LSU 状态机 ==========
  // 0 wait EXU valid
  // 1 wait SRAM and ready
  // 2 wait WBU ready
  reg [1:0] LSU_state, nLSU_state;

  // 工作指示
  wire LSU_work;
  assign LSU_work = IDU_mem_ren | IDU_mem_wen;

  always @(posedge clk) begin
    if(rst) LSU_state <= 0;
    else    LSU_state <= nLSU_state;
  end

  always @(*) begin
    case (LSU_state)
      0: if(EXU_valid)
           if(LSU_work == 0) nLSU_state = 2;
           else              nLSU_state = 1;
         else
           nLSU_state = 0;
      1: if(R_fin || W_fin) nLSU_state = 2;
         else               nLSU_state = 1;
      2: if(WBU_ready)      nLSU_state = 0;
         else               nLSU_state = 2;
      default: nLSU_state = 0;
    endcase
  end

  always @(*) begin
    case (LSU_state)
      0: begin
        if(LSU_work == 0) begin
          LSU_valid = EXU_valid;
          LSU_ready = WBU_ready;
        end else begin
          LSU_valid = 0;
          LSU_ready = 0;
        end
      end
      1: begin
        LSU_valid = 0;
        LSU_ready = 0;
      end
      2: begin
        LSU_valid = 1;
        LSU_ready = WBU_ready;
      end
      default: begin
        LSU_valid = 0;
        LSU_ready = 0;
      end
    endcase
  end

  // ========== AXI4 控制信号 ==========
  wire AR_en, AW_en, W_en, R_fin, W_fin, W_res, R_res;
  assign AR_en  = (LSU_state == 0) && IDU_mem_ren && EXU_valid && (AR_wtime == 0);
  assign AW_en = (LSU_state == 0) && IDU_mem_wen && EXU_valid && (AW_wtime == 0);
  assign W_en  = (LSU_state == 0) && IDU_mem_wen && EXU_valid && (W_wtime  == 0);
  assign R_fin = io_master_rvalid && io_master_rready;
  assign W_fin = io_master_bvalid && io_master_bready;
  assign W_res = (B_rtime == 0);
  assign R_res = (R_rtime == 0);

  // ========== 延时计数器（LSFR 测试） ==========
  wire [4:0] AR_wt_init, AW_wt_init, W_wt_init, R_rt_init, B_rt_init;
  assign AR_wt_init = 0;
  assign AW_wt_init = 0;
  assign W_wt_init  = 0;
  assign R_rt_init  = 0;
  assign B_rt_init  = 0;

  reg [4:0] AR_wtime, AW_wtime, W_wtime, R_rtime, B_rtime;
  always @(posedge clk) begin
    if(rst) begin
      AR_wtime <= AR_wt_init;
      AW_wtime <= AW_wt_init;
      W_wtime  <= W_wt_init;
      R_rtime  <= R_rt_init;
      B_rtime  <= B_rt_init;
    end else begin
      AR_wtime <= (AR_wtime != 0) ? AR_wtime - 1 : AR_wt_init;
      AW_wtime <= (AW_wtime != 0) ? AW_wtime - 1 : AW_wt_init;
      W_wtime  <= (W_wtime  != 0) ? W_wtime  - 1 : W_wt_init;
      R_rtime  <= (R_rtime  != 0) ? R_rtime  - 1 : R_rt_init;
      B_rtime  <= (B_rtime  != 0) ? B_rtime  - 1 : B_rt_init;
    end
  end

  // ========== 读数据后处理 ==========
  reg [DATA_WID-1:0] rdata;
  MuxKeyWithDefault #(5, 3, 32) Mux_mem_wreg (LSU_rdata, IDU_mem_rmask, 32'b0, {
      3'b001, {{24{rdata[7]}}, rdata[7:0]},     // lb
      3'b010, {{16{rdata[15]}}, rdata[15:0]},   // lh
      3'b011, rdata,                            // lw
      3'b100, {24'b0, rdata[7:0]},              // lbu
      3'b101, {16'b0, rdata[15:0]}              // lhu
  });

  // ========== AXI4 主状态机（写地址、写数据、读地址） ==========
  reg AW_state, nAW_state;
  reg W_state, nW_state;
  reg AR_state, nAR_state;

  always @(posedge clk) begin
    if(rst) begin
      AW_state <= 1'b0;
      W_state  <= 1'b0;
      AR_state <= 1'b0;
    end else begin
      AW_state <= nAW_state;
      W_state  <= nW_state;
      AR_state <= nAR_state;
    end
  end

  always @(*) begin
    case (AW_state)
      1'b0: nAW_state = AW_en ? 1'b1 : 1'b0;
      1'b1: nAW_state = io_master_awready ? 1'b0 : 1'b1;
    endcase
    case (W_state)
      1'b0: nW_state = W_en ? 1'b1 : 1'b0;
      1'b1: nW_state = io_master_wready ? 1'b0 : 1'b1;
    endcase
    case (AR_state)
      1'b0: nAR_state = AR_en ? 1'b1 : 1'b0;
      1'b1: nAR_state = io_master_arready ? 1'b0 : 1'b1;
    endcase
  end

  // ========== AXI4 输出信号（组合与时序混合） ==========
  reg [DATA_WID-1:0] AXI4_wdata;
  reg [3:0]          AXI4_strb;
  reg [DATA_WID-1:0] AXI4_rdata;
  reg [1:0]          bresp, rresp;

  always @(posedge clk) begin
    if(rst) begin
      io_master_awvalid <= 0;
      io_master_awaddr  <= 0;
      io_master_awsize  <= 0;
      io_master_wvalid  <= 0;
      io_master_wdata   <= 0;
      io_master_wstrb   <= 0;
      io_master_bready  <= 0;
      bresp             <= 0;
      io_master_arvalid <= 0;
      io_master_araddr  <= 0;
      io_master_arsize  <= 0;
      io_master_rready  <= 0;
      AXI4_rdata        <= 0;
      rresp             <= 0;
    end else begin
      // 写地址通道
      case (AW_state)
        1'b0: if(AW_en) begin
                io_master_awvalid <= 1;
                io_master_awaddr  <= EXU_waddr;
                io_master_awsize  <= awsize;
              end
        1'b1: if(io_master_awready) begin
                io_master_awvalid <= 0;
                io_master_awaddr  <= 0;
                io_master_awsize  <= 0;
              end
      endcase

      // 写数据通道
      case (W_state)
        1'b0: if(W_en) begin
                io_master_wvalid <= 1;
                io_master_wdata  <= AXI4_wdata;
                io_master_wstrb  <= AXI4_strb;
              end
        1'b1: if(io_master_wready) begin
                io_master_wvalid <= 0;
                io_master_wdata  <= 0;
                io_master_wstrb  <= 0;
              end
      endcase

      // 写响应
      if(W_res && io_master_bvalid) begin
        io_master_bready <= 1;
        bresp <= io_master_bresp;
      end else begin
        io_master_bready <= 1;
      end

      // 读地址通道
      case (AR_state)
        1'b0: if(AR_en) begin
                io_master_arvalid <= 1;
                io_master_araddr  <= EXU_raddr;
                io_master_arsize  <= arsize;
              end
        1'b1: if(io_master_arready) begin
                io_master_arvalid <= 0;
                io_master_araddr  <= 0;
                io_master_arsize  <= 0;
              end
      endcase

      // 读数据通道
      if(R_res && io_master_rvalid) begin
        io_master_rready <= 1;
        AXI4_rdata       <= io_master_rdata;
        rresp            <= io_master_rresp;
      end else begin
        io_master_rready <= 1;
      end
    end
  end

  // ========== 写数据与掩码生成（组合逻辑） ==========
  always @(*) begin
    AXI4_wdata = 0;
    AXI4_strb  = 0;
    case(IDU_mem_wmask)
      4'b0001: begin
        case(EXU_waddr[1:0])
          2'b00: begin AXI4_wdata = {24'b0, EXU_wdata[7:0]}; AXI4_strb = 4'b0001; end
          2'b01: begin AXI4_wdata = {16'b0, EXU_wdata[7:0], 8'b0}; AXI4_strb = 4'b0010; end
          2'b10: begin AXI4_wdata = {8'b0, EXU_wdata[7:0], 16'b0}; AXI4_strb = 4'b0100; end
          2'b11: begin AXI4_wdata = {EXU_wdata[7:0], 24'b0}; AXI4_strb = 4'b1000; end
        endcase
      end
      4'b0011: begin
        case(EXU_waddr[1:0])
          2'b00: begin AXI4_wdata = {16'b0, EXU_wdata[15:0]}; AXI4_strb = 4'b0011; end
          2'b01: begin AXI4_wdata = {8'b0, EXU_wdata[15:0], 8'b0}; AXI4_strb = 4'b0110; end
          2'b10: begin AXI4_wdata = {EXU_wdata[15:0], 16'b0}; AXI4_strb = 4'b1100; end
          2'b11: begin AXI4_wdata = {EXU_wdata[7:0], 24'b0}; AXI4_strb = 4'b1000; end
        endcase
      end
      4'b1111: begin
        case(EXU_waddr[1:0])
          2'b00: begin AXI4_wdata = EXU_wdata; AXI4_strb = 4'b1111; end
          2'b01: begin AXI4_wdata = {EXU_wdata[23:0], 8'b0}; AXI4_strb = 4'b1110; end
          2'b10: begin AXI4_wdata = {EXU_wdata[15:0], 16'b0}; AXI4_strb = 4'b1100; end
          2'b11: begin AXI4_wdata = {EXU_wdata[7:0], 24'b0}; AXI4_strb = 4'b1000; end
        endcase
      end
      default: AXI4_wdata = 0;
    endcase

    // 读数据对齐
    case(IDU_mem_rmask)
      3'b001: begin
        case(EXU_raddr[1:0])
          2'b00: rdata = {24'b0, AXI4_rdata[7:0]};
          2'b01: rdata = {24'b0, AXI4_rdata[15:8]};
          2'b10: rdata = {24'b0, AXI4_rdata[23:16]};
          2'b11: rdata = {24'b0, AXI4_rdata[31:24]};
        endcase
      end
      3'b010: begin
        case(EXU_raddr[1:0])
          2'b00: rdata = {16'b0, AXI4_rdata[15:0]};
          2'b01: rdata = {16'b0, AXI4_rdata[23:8]};
          2'b10: rdata = {16'b0, AXI4_rdata[31:16]};
          2'b11: rdata = {24'b0, AXI4_rdata[31:24]};
        endcase
      end
      3'b011: begin
        case(EXU_raddr[1:0])
          2'b00: rdata = AXI4_rdata;
          2'b01: rdata = {8'b0, AXI4_rdata[31:8]};
          2'b10: rdata = {16'b0, AXI4_rdata[31:16]};
          2'b11: rdata = {24'b0, AXI4_rdata[31:24]};
        endcase
      end
      3'b100: begin
        case(EXU_raddr[1:0])
          2'b00: rdata = {24'b0, AXI4_rdata[7:0]};
          2'b01: rdata = {24'b0, AXI4_rdata[15:8]};
          2'b10: rdata = {24'b0, AXI4_rdata[23:16]};
          2'b11: rdata = {24'b0, AXI4_rdata[31:24]};
        endcase
      end
      3'b101: begin
        case(EXU_raddr[1:0])
          2'b00: rdata = {16'b0, AXI4_rdata[15:0]};
          2'b01: rdata = {16'b0, AXI4_rdata[23:8]};
          2'b10: rdata = {16'b0, AXI4_rdata[31:16]};
          2'b11: rdata = {24'b0, AXI4_rdata[31:24]};
        endcase
      end
      default: rdata = 0;
    endcase
  end

  // ========== AXI4 大小编码 ==========
  reg [2:0] awsize, arsize;
  always @(*) begin
    awsize = 0;
    arsize = 0;
    case(IDU_mem_wmask)
      4'b0001: awsize = 3'b000;
      4'b0011: awsize = 3'b001;
      4'b1111: awsize = 3'b010;
      default: awsize = 3'b000;
    endcase
    case(IDU_mem_rmask)
      3'b001: arsize = 3'b000;
      3'b010: arsize = 3'b001;
      3'b011: arsize = 3'b010;
      3'b100: arsize = 3'b000;
      3'b101: arsize = 3'b001;
      default: arsize = 3'b000;
    endcase
  end

  // ========== 固定 AXI4 信号 ==========
  always @(posedge clk) begin
    io_master_awburst <= 2'b01;
    io_master_wlast   <= 1'b1;
    io_master_arburst <= 2'b01;
    io_master_awid    <= 0;
    io_master_awlen   <= 0;
    io_master_arid    <= 0;
    io_master_arlen   <= 0;
  end

  // ========== 响应错误处理 ==========
  always @(*) begin
    if((bresp != 0) || (rresp != 0))
      LSU_npc = 0;
    else
      LSU_npc = EXU_npc;
  end

  // ========== 透传控制信号 ==========
  assign LSU_reg_wen = EXU_reg_wen;
  assign LSU_csr_wen = EXU_csr_wen;
  assign LSU_csr_ren = EXU_csr_ren;

`ifndef YOSYS

  // ========== 性能计数器 ==========
  import "DPI-C" function void LSU_wait_EXU();
  import "DPI-C" function void LSU_wait_read();
  import "DPI-C" function void LSU_update_output_r();
  import "DPI-C" function void LSU_wait_write();
  import "DPI-C" function void LSU_update_output_w();
  import "DPI-C" function void LSU_wait_WBU();

  always @(posedge clk) begin
    if(!rst) begin
      if(LSU_state == 0 && (!EXU_valid)) LSU_wait_EXU();
      else if(LSU_state == 0 && EXU_valid && (!LSU_work)) LSU_wait_EXU();
      else if((LSU_state == 0) && EXU_valid && IDU_mem_ren) LSU_wait_read();
      else if((LSU_state == 0) && EXU_valid && IDU_mem_wen) LSU_wait_write();
      else if((LSU_state == 1) && (R_fin == 1)) LSU_update_output_r();
      else if((LSU_state == 1) && (R_fin == 0) && IDU_mem_ren) LSU_wait_read();
      else if((LSU_state == 1) && (W_fin == 1)) LSU_update_output_w();
      else if((LSU_state == 1) && (W_fin == 0) && IDU_mem_wen) LSU_wait_write();
      else if(LSU_state == 2) LSU_wait_WBU();
    end
  end

`endif

endmodule
