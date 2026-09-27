# Software directory for TASK 8

## Build description
Build is conducted in two steps.
1. `vitis -s bootstrap.py` This step needs to be called once to properly initialize platform and vitis environment.
2. `vitis -s build.py` This is step that actually builds platform and application. It can be used locally for testing next iteration of software. Changes to the application can be made in workspace. Each change in `app.elf` is detected by vivado.

Please note that on CI the same flow is maintained. Therefore it's crucial to modify `sw/workspace/app/src/main.c` in your commit.
