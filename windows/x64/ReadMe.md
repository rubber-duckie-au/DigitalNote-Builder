## Compile for Windows (64 bits)

First, you must get MSYS2 installed on your Windows.

	https://www.msys2.org/

Once MSYS2 is installed, it starts the "MSYS2 UCRT64" console. Close this window.
Click the Windows symbol (left bottom), search for "MSYS2 MINGW64" and start the console.

Second, we will patch MSYS2 with the latest updates:

	pacman -Syu

After the upgrade, it asks to restart "MSYS2 MINGW64".

Once MSYS2 is up-to-date, you can download the libraries.

	cd /c/Users/iamlupo/Desktop/DigitalNote-Builder
	./download.sh

When thats executed, you will have a folder called "download" with all the libraries.

Once thats done, we can install the latest MSYS2 packages by executing.

	cd windows/x64
	./update.sh

Now we have all the libraries we need for the Digitalnote project.

	git clone https://github.com/DigitalNoteXDN/DigitalNote-2.git

Now that we have everything, we can compile the libraries.

	./compile_libs.sh

The job count is optional. With no argument `compile_libs.sh` auto-detects
(`nproc` / `sysctl`, fallback 2), matching `compile_daemon.sh` and
`compile_app.sh`. Pass `"-j N"` to override, e.g. `./compile_libs.sh "-j 4"`.

This will take a while to compile; take a coffee while this runs.

Once finished, we can compile the project.

	./compile_daemon.sh
	./compile_app.sh

And thats it! :D

PS: When everything is done, there is a temp folder. This can be removed.