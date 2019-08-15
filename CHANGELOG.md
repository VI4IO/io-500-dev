# SC-19
  * Moved high default values for all benchmarks to io500_fixed.sh
    * Users should not have to modify them, for testing set the stonewall time to 1
  * IO-500 information fields are now created by a webpage to ensure consistency
  * IOR and MDTest now output the performance when reaching the stonewall
  * MDTest uses -X flag and verifies that data read is matching the expected pattern
  * MDTest now uses the new -P flag to print rate and time to ease debugging
  * MDTest now uses rank shifting supporting block and cyclic layout (auto-detected)
