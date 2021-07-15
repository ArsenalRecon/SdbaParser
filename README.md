## Intro ##

Arsenal's Sdba Parser carves and parses (hereafter, parses) Sdba memory pool tags (produced by Windows 7) from any input file. Sdba memory pool tags are related to Windows Application Compatibility Database functionality and seem to be generated each time a new executable (based on analysis of MFT record and sequence numbers) is run. Most importantly for digital forensics practitioners, Sdba memory pool tags contain executable file paths and NTFS last written timestamps (at time of execution). Arsenal has found Sdba memory pool tags from Windows hibernation (from both the active and slack space within hibernation) to be extremely important in our casework - more specifically, they provided insight not available through other artifacts within the same evidence. Sdba memory pool tags may also be found in memory captures, crash dumps, swap files, and (under the right circumstances) unallocated space.

## Requirements: ##

Appropriate PowerShell execution policy (temporarily enabling the "Unrestricted" policy)

## Usage: ##

Sdba Parser can be run with a GUI by simply executing SdbaParser64.exe. Output is in CSV (pipe separated) format.

If you intend to parse Sdba memory pool tags from Windows hibernation, Arsenal recommends using the Hibernation Recon output files "ActiveMemory.bin" and  "AllSlack.bin".

Sdba Parser can also be run from a command prompt:

```
SdbaParser64.exe /Input: /Output: /Arch:
```
   
* Input = Full path to the file to parse
* Output = Optionally set path for the output. Defaults to program directory.
* Arch = The source architecture. Must be 32 or 64.

### Examples: ###

```
SdbaParser64.exe /Input:D:\temp\ActiveMemory.bin /Output:D:\temp /Arch:32
SdbaParser64.exe /Input:D:\temp\pagefile.sys /Arch:64
```

## Contributions: ##

Contributions and improvements to the code are welcomed.

## License: ##

Distributed under the MIT License. See License.md for details.

## More Information: ##

To learn more about Arsenal’s digital forensics software and training, please visit https://ArsenalRecon.com and follow us on Twitter @ArsenalRecon (https://twitter.com/ArsenalRecon).

To learn more about Arsenal’s digital forensics consulting services, please visit https://ArsenalExperts.com and follow us on Twitter @ArsenalArmed (https://twitter.com/ArsenalArmed).