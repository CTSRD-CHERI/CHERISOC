/*-
 * Copyright (c) 2018 Alexandre Joannou
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

package CHERISOC;

import      Connectable :: *;
import          BERISOC :: *;
import TagControllerAXI :: *;
import              AXI :: *;

export CHERISOC(..);
export mkCHERISOC;

interface CHERISOC;
  interface AXISlave#(4, 32, 128, 0, 1, 0, 0, 1) slave;
  method Bit#(32) peekIRQs;
endinterface

`define IGNORE_TAGS
`ifndef IGNORE_TAGS
module mkCHERISOC (CHERISOC);
  let tagcontroller <- mkTagControllerAXI;
  let berisoc <- mkBERISOC;
  mkConnection(tagcontroller.master, berisoc.slave);
  interface slave = tagcontroller.slave;
  method peekIRQs = berisoc.peekIRQs;
endmodule
`else
import BlueBasics :: *;
module mkCHERISOC (CHERISOC);
  let berisoc <- mkBERISOC;
  interface slave = interface AXISlave;
    interface aw = interface Sink;
      method canPut = berisoc.slave.aw.canPut;
      method put(x) = berisoc.slave.aw.put(AWFlit{
        awid:     zeroExtend(x.awid),
        awaddr:   x.awaddr,
        awlen:    x.awlen,
        awsize:   x.awsize,
        awburst:  x.awburst,
        awlock:   x.awlock,
        awcache:  x.awcache,
        awprot:   x.awprot,
        awqos:    x.awqos,
        awregion: x.awregion,
        awuser:   x.awuser
      });
    endinterface;
    interface  w = interface Sink;
      method canPut = berisoc.slave.w.canPut;
      method put(x) = berisoc.slave.w.put(WFlit{
        wdata: x.wdata,
        wstrb: x.wstrb,
        wlast: x.wlast,
        wuser: 0
      });
    endinterface;
    interface  b = interface Source;
      method canGet = berisoc.slave.b.canGet;
      method   peek = BFlit{
        bid:   truncate(berisoc.slave.b.peek.bid),
        bresp: berisoc.slave.b.peek.bresp,
        buser: berisoc.slave.b.peek.buser
      };
      method get = actionvalue
        let x <- berisoc.slave.b.get;
        return BFlit{
          bid:   truncate(x.bid),
          bresp: x.bresp,
          buser: x.buser
        };
      endactionvalue;
    endinterface;
    interface ar = interface Sink;
      method canPut = berisoc.slave.ar.canPut;
      method put(x) = berisoc.slave.ar.put(ARFlit{
        arid:     zeroExtend(x.arid),
        araddr:   x.araddr,
        arlen:    x.arlen,
        arsize:   x.arsize,
        arburst:  x.arburst,
        arlock:   x.arlock,
        arcache:  x.arcache,
        arprot:   x.arprot,
        arqos:    x.arqos,
        arregion: x.arregion,
        aruser:   x.aruser
      });
    endinterface;
    interface  r = interface Source;
      method canGet = berisoc.slave.r.canGet;
      method   peek = RFlit{
        rid:   truncate(berisoc.slave.r.peek.rid),
        rdata: berisoc.slave.r.peek.rdata,
        rresp: berisoc.slave.r.peek.rresp,
        rlast: berisoc.slave.r.peek.rlast,
        ruser: 0
      };
      method get = actionvalue
        let x <- berisoc.slave.r.get;
        return RFlit{
        rid:   truncate(x.rid),
        rdata: x.rdata,
        rresp: x.rresp,
        rlast: x.rlast,
        ruser: 0
        };
      endactionvalue;
    endinterface;
  endinterface;
  method peekIRQs = berisoc.peekIRQs;
endmodule
`endif

endpackage
