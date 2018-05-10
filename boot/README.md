## History

The development was begun because of the inspiration from the following
resources:

* Series of bootloader development articles:
    * https://www.codeproject.com/Articles/664165/Writing-a-boot-loader-in-Assembly-and-C-Part
    * https://www.codeproject.com/Articles/668422/Writing-a-boot-loader-in-Assembly-and-C-Part
    * https://www.codeproject.com/Articles/737545/Writing-a-bit-dummy-kernel-in-C-Cplusplus
* OS development series:
    * http://www.brokenthorn.com/Resources/OSDevIndex.html

More importantly there was a meeting with friends one Sunday and one of them
said: "I try to read Linux kernel source but don't understand the entry point
and as a result I've stopped digging into it". It's a key problem for most
people because they don't understand how OS works from the ground up, from the
pushing the power button. This very small hande-made OS will try to fix this
issue.

## Tests

Bochs X86 emulator is used for tests purpose during the development.
For building bochs from scratch use helpers scripts:

   * [OS X](https://github.com/dshil/scripts/blob/master/osx/bochs.sh)
   * [Fedora](https://github.com/dshil/scripts/blob/master/fedora/bochs.sh)

For more information about bochs configurations option
visit: http://bochs.sourceforge.net/doc/docbook/user/compiling.html .

## Debug

There are many possibilities to verify if your executable code that will be
loaded into RAM contains the valid master boot record signature. First you'll
need a some kind of HEX editor. The simplest way I'd recommend is to use vim:

   ```
       r !xxd boot/test_boot.bin
   ```

Look at the last bytes (510 and 511). You should see the following.

   ```
       000001f0: 0000 0000 0000 0000 0000 0000 0000 55aa  ..............U.
   ```

## HAOS

HAOS stands for a hack OS.
