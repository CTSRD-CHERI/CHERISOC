/*-
 * Copyright (c) 2018-2019 Alexandre Joannou
 * Copyright (c) 2019 Peter Rugg
 * All rights reserved.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory (Department of Computer Science and
 * Technology) under DARPA contract HR0011-18-C-0016 ("ECATS"), as part of the
 * DARPA SSITH research programme.
 *
 * @BERI_LICENSE_HEADER_START@
 *
 * Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
 * license agreements.  See the NOTICE file distributed with this work for
 * additional information regarding copyright ownership.  BERI licenses this
 * file to you under the BERI Hardware-Software License, Version 1.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *   http://www.beri-open-systems.org/legal/license-1-0.txt
 *
 * Unless required by applicable law or agreed to in writing, Work distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * @BERI_LICENSE_HEADER_END@
 */

package BERISOC;

import PISM :: *;
import  AXI :: *;  //Bluestuff AXI
import  Axi :: *;  //Bluespec builtin AXI used by PISM

export BERISOC(..);
export mkBERISOC;

interface BERISOC#(numeric type addr_);
  interface AXI4_Slave#(8, addr_, 128, 0, 0, 0, 0, 0) slave;
  method Bit#(32) peekIRQs;
endinterface

module mkBERISOC (BERISOC#(addr_)) provisos (Add#(a__, addr_, 64));
  let pism <- mkAXI_PISM;
  let shim <- mkAXI4Shim;
  connectAXI(shim.master, pism.axiRdSlave, pism.axiWrSlave);
  interface slave = shim.slave;
  method peekIRQs = pism.peekIRQs;
endmodule

module connectAXI#(AXI4_Master#(8, addr_, 128, 0, 0, 0, 0, 0) m,
                  AxiRdSlave#(8, 40, 128, 4, 0) sr,
                  AxiWrSlave#(8, 40, 128, 4, 0) sw
                 ) (Empty) provisos (Add#(a__, addr_, 64));

  let tmp <- toUnguarded_AXI4_Master(m);
  let m_synth = toAXI4_Master_Synth(tmp);
  let m_aw = m_synth.aw;
  let  m_w = m_synth.w;
  let  m_b = m_synth.b;
  let m_ar = m_synth.ar;
  let  m_r = m_synth.r;

  function Action die(Fmt msg) = action
    $display(msg);
    $finish(0);
  endaction;

  rule awChannel;
    let valid = m_aw.awvalid;
    sw.awID(m_aw.awid);
    //XXX horrible hack - from 40 bits restriction
    // support addresses up to 64 bits, only considers bottom 40 bits
    Bit#(64) tmp = zeroExtend(m_aw.awaddr);
    sw.awADDR(truncate(tmp));
    let len = m_aw.awlen;
    sw.awLEN(unpack(len[3:0]));
    if (valid && len[7:4] != 0) die($format("AW: AXI3 only supports 4-bit LEN field (received 0b%0b)", len));
    sw.awSIZE(unpack(pack(m_aw.awsize)));
    sw.awBURST(unpack(pack(m_aw.awburst)));
    sw.awLOCK((m_aw.awlock == NORMAL) ? unpack(2'b00) : unpack(2'b01));
    sw.awCACHE(unpack(m_aw.awcache));
    sw.awPROT(unpack(m_aw.awprot));
    if (valid && m_aw.awqos != 0) die($format("AW: AXI3 does not support QOS (received 0b%0b)", m_aw.awqos));
    if (valid && m_aw.awregion != 0) die($format("AW: AXI3 does not support REGION field (received 0b%0b)", m_aw.awregion));
    if (valid && m_aw.awuser != 0) die($format("AW: AXI3 does not support USER field (received 0b%0b)", m_aw.awuser));
    sw.awVALID(valid);
    m_aw.awready(sw.awREADY);
  endrule

  rule wChannel;
    let valid = m_w.wvalid;
    sw.wID(0);
    sw.wDATA(m_w.wdata);
    sw.wSTRB(m_w.wstrb);
    sw.wLAST(m_w.wlast);
    if (valid && m_w.wuser != 0) die($format("W: AXI3 does not support USER field (received 0b%0b)", m_w.wuser));
    sw.wVALID(valid);
    m_w.wready(sw.wREADY);
  endrule

  rule bChannel(sw.bVALID);
    //XXX could use a don't care ? for user field
    m_b.bflit(sw.bID, unpack(pack(sw.bRESP)), 0);
    sw.bREADY(m_b.bready);
  endrule

  rule arChannel;
    let valid = m_ar.arvalid;
    sr.arID(m_ar.arid);
    //XXX horrible hack - from 40 bits restriction
    // support addresses up to 64 bits, only considers bottom 40 bits
    Bit#(64) tmp = zeroExtend(m_ar.araddr);
    sr.arADDR(truncate(tmp));
    let len = m_ar.arlen;
    sr.arLEN(unpack(len[3:0]));
    if (valid && len[7:4] != 0) die($format("AR: AXI3 only supports 4-bit LEN field (received 0b%0b)", len));
    sr.arSIZE(unpack(pack(m_ar.arsize)));
    sr.arBURST(unpack(pack(m_ar.arburst)));
    sr.arLOCK((m_ar.arlock == NORMAL) ? unpack(2'b00) : unpack(2'b01));
    sr.arCACHE(unpack(m_ar.arcache));
    sr.arPROT(unpack(m_ar.arprot));
    if (valid && m_ar.arqos != 0) die($format("AR: AXI3 does not support QOS (received 0b%0b)", m_ar.arqos));
    if (valid && m_ar.arregion != 0) die($format("AR: AXI3 does not support REGION field (received 0b%0b)", m_ar.arregion));
    if (valid && m_ar.aruser != 0) die($format("AR: AXI3 does not support USER field (received 0b%0b)", m_ar.aruser));
    sr.arVALID(valid);
    m_ar.arready(sr.arREADY);
  endrule

  rule rChannel(sr.rVALID);
    //XXX could use a don't care ? for user field
    m_r.rflit(sr.rID, sr.rDATA, unpack(pack(sr.rRESP)),sr.rLAST, 0);
    sr.rREADY(m_r.rready);
  endrule

endmodule

endpackage
