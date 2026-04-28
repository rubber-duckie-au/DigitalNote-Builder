## Compile for Macos (64 bits)

First, you get the builder's project.

	git clone https://github.com/DigitalNoteXDN/DigitalNote-Builder.git
	cd DigitalNote-Builder

Then download all the library packages.

	bash download.sh

When thats executed, you will have a folder called "download" with all the libraries.

Once thats done, we can install the latest brew packages.

	cd macos/x64
	bash update.sh

Now we have all the packages we need for the Digitalnote project.

	git clone https://github.com/DigitalNoteXDN/DigitalNote-2.git

Now that we have everything, we can compile the libraries.

	bash compile_libs.sh "-j 4"

This will take a while to compile; take a coffee while this runs.

Now we can compile the project.

	bash compile_app.sh "-j 4"
	bash compile_deamon.sh "-j 4"

Once the app is created, we can deploy the DigitalNote-QT version.

	bash deploy.sh

And thats it! :D

PS: When everything is done, there is a temp folder. This can be removed.