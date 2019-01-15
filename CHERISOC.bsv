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

module mkCHERISOC (CHERISOC);
  let tagcontroller <- mkTagControllerAXI;
  let berisoc <- mkBERISOC;
  mkConnection(tagcontroller.master, berisoc.slave);
  interface slave = tagcontroller.slave;
  method peekIRQs = berisoc.peekIRQs;
endmodule

endpackage
