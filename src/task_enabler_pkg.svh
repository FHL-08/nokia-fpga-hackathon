package task_enabler_pkg;

typedef struct packed {
  logic task16; logic task15; logic task14; logic task13; logic task12; logic task11; logic task10; logic task9;
  logic task8;  logic task7;  logic task6;  logic task5;  logic task4;  logic task3;  logic task2;  logic task1;
} task_enabler;

localparam task_enabler enable = '{
  task1 :  1'b1,
  task2 :  1'b1,
  task3 :  1'b1,
  task4 :  1'b0, // not used
  task5 :  1'b1,
  task6 :  1'b0, // not used
  task7 :  1'b1,
  task8 :  1'b1,

  task9 :  1'b1,
  task10 : 1'b1,
  task11 : 1'b1,    //finished 22:29. hv not pushed yet
  task12 : 1'b1,
  task13 : 1'b1,
  task14 : 1'b1,
  task15 : 1'b1,
  task16 : 1'b1     //finished 22:49 hv not pushed yet
};

endpackage
