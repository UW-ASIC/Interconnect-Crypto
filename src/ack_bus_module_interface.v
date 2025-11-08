module ack_bus_module_interface ( 
    input  wire        ACK_READY,
    output wire        ACK_READY_TO_MODULE,
    input  wire        MODULE_SIDE_ACK_VAILD,
    output wire        ACK_VALID,
    input  wire [1:0]  MODULE_SIDE_MODULE_SOURCE_ID,
    output wire [1:0]  MODULE_SOURCE_ID
);

//READY
//MODULE_SIDE_ACK_VALID->ACK_VAILD

  assign ACK_READY=ACK_READY_TO_MODULE;
  assign ACK_VAILD=MODULE_SIDE_ACK_VAILD;
  assign MODULE_SOURCE_ID=MODULE_SIDE_MODULE_SOURCE_ID;

//This is an example of what the interfacing should look like, realistically the central ack_bus module will take care of all the interfacing
//We can refer back to this in the future


endmodule

/*
Acknowledgment Bus Module Interface
This module handles the acknowledgment signals for the interconnect bus.
It provides an interface for the source modules to send acknowledgment
signals and for the destination modules to receive them.

How to use:
ACK Bus:

The Ack bus receive the signals and
*/
